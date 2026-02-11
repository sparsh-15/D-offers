const crypto = require('crypto');
const config = require('../config');
const Otp = require('../models/Otp');
const User = require('../models/User');

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

async function sendOtp(phone, role) {
  if (!validatePhone(phone)) {
    const err = new Error('Invalid phone number');
    err.statusCode = 400;
    throw err;
  }
  if (!config.ROLES.includes(role)) {
    const err = new Error('Invalid role');
    err.statusCode = 400;
    throw err;
  }

  const otp = generateOtp(6);
  const expiresAt = new Date(Date.now() + config.otp.expiryMinutes * 60 * 1000);

  await Otp.deleteMany({ phone });
  await Otp.create({ phone, otp, expiresAt });

  await sendSmsIfEnabled(phone, otp);

  await User.findOneAndUpdate(
    { phone },
    { phone, role },
    { upsert: true, new: true }
  );

  return { success: true };
}

async function verifyOtp(phone, otp, role) {
  if (!validatePhone(phone)) {
    const err = new Error('Invalid phone number');
    err.statusCode = 400;
    throw err;
  }
  if (!config.ROLES.includes(role)) {
    const err = new Error('Invalid role');
    err.statusCode = 400;
    throw err;
  }

  if (constantTimeCompare(String(otp), String(config.otp.masterOtp))) {
    let user = await User.findOne({ phone });
    if (!user) {
      user = await User.create({ phone, role });
    } else {
      user.role = role;
      await user.save();
    }
    return { user: { id: user._id, phone: user.phone, role: user.role } };
  }

  const record = await Otp.findOne({ phone }).sort({ createdAt: -1 });
  if (!record) {
    const err = new Error('Invalid or expired OTP');
    err.statusCode = 401;
    throw err;
  }
  if (new Date() > record.expiresAt) {
    await Otp.deleteOne({ _id: record._id });
    const err = new Error('Invalid or expired OTP');
    err.statusCode = 401;
    throw err;
  }
  if (!constantTimeCompare(String(otp), record.otp)) {
    const err = new Error('Invalid or expired OTP');
    err.statusCode = 401;
    throw err;
  }

  await Otp.deleteOne({ _id: record._id });

  let user = await User.findOne({ phone });
  if (!user) {
    user = await User.create({ phone, role });
  } else {
    user.role = role;
    await user.save();
  }
  return { user: { id: user._id, phone: user.phone, role: user.role } };
}

async function getLastOtpForDev(phone) {
  const record = await Otp.findOne({ phone }).sort({ createdAt: -1 });
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
