const crypto = require('crypto');
const config = require('../config');
const otpRepository = require('../repositories/otpRepository');
const userRepository = require('../repositories/userRepository');
const { prisma } = require('../db/prisma');
const { resolveCityStateFromPincode } = require('./pincodeService');

const PHONE_REGEX = /^\+?[1-9]\d{1,14}$|^\d{10}$/;

function generateOtp(length = 6) {
  const digits = '0123456789';
  let otp = '';
  const bytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    otp += digits[bytes[i] % 10];
  }
  return otp;
}

function validatePhone(phone) {
  if (!phone || typeof phone !== 'string') return false;
  const normalized = phone.replace(/\s/g, '');
  return PHONE_REGEX.test(normalized);
}

function constantTimeCompare(a, b) {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

async function sendSmsIfEnabled(phone, otp) {
  if (!config.otp.sendViaSms) return;
  if (config.sms.provider === 'twilio' && config.sms.twilio.accountSid && config.sms.twilio.authToken) {
    try {
      const twilio = require('twilio');
      const client = twilio(config.sms.twilio.accountSid, config.sms.twilio.authToken);
      await client.messages.create({
        body: `Your verification code is: ${otp}. Valid for ${config.otp.expiryMinutes} minutes.`,
        from: config.sms.twilio.phoneNumber,
        to: phone,
      });
    } catch (err) {
      console.error('SMS send error:', err.message);
      throw new Error('Failed to send OTP via SMS');
    }
  }
}

async function sendOtp(phone, role, signupData = {}) {
  if (!validatePhone(phone)) {
    const err = new Error('Invalid phone number');
    err.statusCode = 400;
    throw err;
  }

  const existingUser = await userRepository.findByPhone(phone);

  // Check if this is a signup (has name/pincode) or login (no signup data)
  const isSignup = Boolean(signupData.name || signupData.pincode);

  if (!isSignup) {
    // This is a LOGIN attempt - user must exist
    if (!existingUser) {
      const err = new Error('Account not found. Please signup first.');
      err.statusCode = 404;
      throw err;
    }

    // Optional role check for backward compatibility with older clients.
    if (role) {
      if (!config.ROLES.includes(role)) {
        const err = new Error('Invalid role');
        err.statusCode = 400;
        throw err;
      }

      const adminRoles = ['super_admin', 'subadmin', 'company_sales_agent', 'ssa'];
      const isAdminRequest = adminRoles.includes(role);
      const isAdminUser = adminRoles.includes(existingUser.role);

      if (!(isAdminRequest && isAdminUser) && existingUser.role !== role) {
        const err = new Error(`This phone is registered as ${existingUser.role}`);
        err.statusCode = 400;
        throw err;
      }
    }

    // Generate and send OTP for existing user
    const otp = generateOtp(6);
    const expiresAt = new Date(Date.now() + config.otp.expiryMinutes * 60 * 1000);

    await otpRepository.deleteByPhone(phone);
    await otpRepository.create({ phone, otp, expiresAt });

    await sendSmsIfEnabled(phone, otp);

    return { success: true };
  }

  // This is a SIGNUP attempt
  if (!role || !config.ROLES.includes(role)) {
    const err = new Error('Invalid role');
    err.statusCode = 400;
    throw err;
  }

  const signupRoles = ['customer', 'shopkeeper', 'company_sales_agent'];
  if (!signupRoles.includes(role)) {
    const err = new Error('Cannot signup with this role. Contact administrator.');
    err.statusCode = 403;
    throw err;
  }

  if (existingUser) {
    const err = new Error(`This phone is already registered as ${existingUser.role}`);
    err.statusCode = 400;
    throw err;
  }

  // On first signup, store name/pincode + auto city/state + optional coupon (shopkeeper)
  const name = signupData.name != null ? String(signupData.name).trim() : '';
  const pincode = signupData.pincode != null ? String(signupData.pincode).trim() : '';
  const address = signupData.address != null ? String(signupData.address).trim() : '';
  const cityFromFrontend = signupData.city != null ? String(signupData.city).trim() : '';
  const rawCoupon = signupData.couponCode != null ? String(signupData.couponCode).trim() : '';
  const signupCouponCode = rawCoupon ? rawCoupon.toUpperCase() : null;
  const signupCouponCapturedAt = signupCouponCode && role === 'shopkeeper' ? new Date() : null;
  const acceptedTerms =
    Boolean(signupData.acceptedTerms) || Boolean(signupData.termsAccepted);

  if (!name || !pincode) {
    const err = new Error('Name and pincode are required for signup');
    err.statusCode = 400;
    throw err;
  }

  const resolved = await resolveCityStateFromPincode(pincode);

  const otp = generateOtp(6);
  const expiresAt = new Date(Date.now() + config.otp.expiryMinutes * 60 * 1000);

  await otpRepository.deleteByPhone(phone);
  await otpRepository.create({ phone, otp, expiresAt });

  await sendSmsIfEnabled(phone, otp);

  // Use city from frontend if provided, otherwise use first area or district
  let city = cityFromFrontend;
  if (!city) {
    city = resolved.areas && resolved.areas.length > 0
      ? resolved.areas[0].name
      : resolved.district;
  }

  const update = {
    phone,
    role,
    name,
    address,
    pincode: resolved.pincode,
    city: city || '',
    state: resolved.state,
  };

  // All users are approved by default on signup.
  // Manual moderation can still change approvalStatus later (e.g. to 'rejected').
  if (role === 'customer' || role === 'shopkeeper') {
    update.approvalStatus = 'approved';
  }

  if (signupCouponCode && role === 'shopkeeper') {
    update.signupCouponCode = signupCouponCode;
    update.signupCouponCapturedAt = signupCouponCapturedAt;
  }

  const user = await userRepository.create(update);

  if (role === 'shopkeeper' && acceptedTerms && user && user.id) {
    const existing = await prisma.onboardingStatus.findUnique({
      where: { userId: user.id },
    });
    if (existing) {
      await prisma.onboardingStatus.update({
        where: { userId: user.id },
        data: {
          termsAccepted: true,
          termsAcceptedAt: new Date(),
          currentStep: Math.max(existing.currentStep, 3),
        },
      });
    } else {
      await prisma.onboardingStatus.create({
        data: {
          userId: user.id,
          termsAccepted: true,
          termsAcceptedAt: new Date(),
          currentStep: 3,
        },
      });
    }
  }

  return { success: true };
}

async function markLeadClaimedIfNeeded(user) {
  if (!user || user.role !== 'shopkeeper' || !user.onboardedByLeadId) return;
  await prisma.shopLead.updateMany({
    where: {
      id: user.onboardedByLeadId,
      claimedAt: null,
    },
    data: {
      claimedAt: new Date(),
      status: 'claimed',
    },
  });
}

async function verifyOtp(phone, otp, role) {
  if (!validatePhone(phone)) {
    const err = new Error('Invalid phone number');
    err.statusCode = 400;
    throw err;
  }

  const user = await userRepository.findByPhone(phone);
  if (!user) {
    const err = new Error('Account not found. Please signup first.');
    err.statusCode = 404;
    throw err;
  }
  
  // Optional role check for backward compatibility with older clients.
  if (role) {
    if (!config.ROLES.includes(role)) {
      const err = new Error('Invalid role');
      err.statusCode = 400;
      throw err;
    }

    const adminRoles = ['super_admin', 'subadmin', 'company_sales_agent', 'ssa'];
    const isAdminRequest = adminRoles.includes(role);
    const isAdminUser = adminRoles.includes(user.role);

    if (!(isAdminRequest && isAdminUser) && user.role !== role) {
      const err = new Error(`This phone is registered as ${user.role}`);
      err.statusCode = 400;
      throw err;
    }
  }
  // Note: We allow shopkeepers to login even if pending/rejected
  // The frontend will show appropriate message based on approvalStatus

  if (constantTimeCompare(String(otp), String(config.otp.masterOtp))) {
    await markLeadClaimedIfNeeded(user);
    return { user: { id: user._id, phone: user.phone, role: user.role } };
  }

  const record = await otpRepository.findLatestByPhone(phone);
  if (!record) {
    const err = new Error('Invalid or expired OTP');
    err.statusCode = 401;
    throw err;
  }
  if (new Date() > record.expiresAt) {
    await otpRepository.deleteByPhone(phone);
    const err = new Error('Invalid or expired OTP');
    err.statusCode = 401;
    throw err;
  }
  if (!constantTimeCompare(String(otp), record.otp)) {
    const err = new Error('Invalid or expired OTP');
    err.statusCode = 401;
    throw err;
  }

  await otpRepository.deleteByPhone(phone);
  await markLeadClaimedIfNeeded(user);

  return { user: { id: user._id, phone: user.phone, role: user.role } };
}

async function getLastOtpForDev(phone) {
  const record = await otpRepository.findLatestByPhone(phone);
  if (!record) return null;
  return { otp: record.otp, expiresAt: record.expiresAt };
}

module.exports = {
  sendOtp,
  verifyOtp,
  getLastOtpForDev,
  validatePhone,
  ROLES: config.ROLES,
};
