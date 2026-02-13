const jwt = require('jsonwebtoken');
const config = require('../config');
const otpService = require('../services/otpService');
const User = require('../models/User');
const { resolveCityStateFromPincode } = require('../services/pincodeService');

function issueToken(user) {
  return jwt.sign(
    { userId: user.id, phone: user.phone, role: user.role },
    config.jwt.secret,
    { expiresIn: config.jwt.expiry }
  );
}

async function signup(req, res, next) {
  try {
    const { phone, role, name, pincode, address } = req.body;
    if (!phone || !role || !name || !pincode) {
      return res.status(400).json({
        success: false,
        message: 'Phone, role, name and pincode are required',
      });
    }
    await otpService.sendOtp(phone.trim(), role, { name, pincode, address });
    res.status(200).json({ success: true, message: 'Signup OTP sent' });
  } catch (err) {
    next(err);
  }
}

async function sendOtp(req, res, next) {
  try {
    const { phone, role, name, pincode, address } = req.body;
    const clientIp = req.ip || req.connection.remoteAddress;
    
    console.log(`[AUTH] sendOtp request - Role: ${role}, Phone: ${phone?.substring(0, 3)}***, IP: ${clientIp}`);
    
    if (!phone || !role) {
      console.warn(`[AUTH] sendOtp validation failed - Missing phone or role`);
      return res.status(400).json({ success: false, message: 'Phone and role are required' });
    }
    
    await otpService.sendOtp(phone.trim(), role, { name, pincode, address });
    console.log(`[AUTH] sendOtp success - Role: ${role}, Phone: ${phone?.substring(0, 3)}***`);
    res.status(200).json({ success: true, message: 'OTP sent' });
  } catch (err) {
    console.error(`[AUTH] sendOtp error - Role: ${req.body?.role}, Phone: ${req.body?.phone?.substring(0, 3)}***, Error: ${err.message}`);
    next(err);
  }
}

async function verifyOtp(req, res, next) {
  try {
    const { phone, otp, role } = req.body;
    const clientIp = req.ip || req.connection.remoteAddress;
    
    console.log(`[AUTH] verifyOtp request - Role: ${role}, Phone: ${phone?.substring(0, 3)}***, IP: ${clientIp}`);
    
    if (!phone || otp === undefined || otp === null || !role) {
      console.warn(`[AUTH] verifyOtp validation failed - Missing required fields`);
      return res.status(400).json({ success: false, message: 'Phone, otp and role are required' });
    }
    
    const { user } = await otpService.verifyOtp(phone.trim(), String(otp), role);
    const token = issueToken(user);
    console.log(`[AUTH] verifyOtp success - Role: ${role}, Phone: ${phone?.substring(0, 3)}***, UserId: ${user.id}`);
    res.status(200).json({
      success: true,
      token,
      user: { id: user.id, phone: user.phone, role: user.role },
    });
  } catch (err) {
    console.error(`[AUTH] verifyOtp error - Role: ${req.body?.role}, Phone: ${req.body?.phone?.substring(0, 3)}***, Error: ${err.message}, StatusCode: ${err.statusCode || 500}`);
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = await User.findById(req.user.userId)
      .select('name phone role pincode city state address approvalStatus createdAt')
      .lean();
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        pincode: user.pincode,
        city: user.city,
        state: user.state,
        address: user.address,
        approvalStatus: user.approvalStatus,
        createdAt: user.createdAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function updateMe(req, res, next) {
  try {
    const { name, address, pincode } = req.body;
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (name !== undefined) {
      user.name = String(name).trim();
    }
    if (address !== undefined) {
      user.address = String(address).trim();
    }
    if (pincode !== undefined && String(pincode).trim()) {
      const resolved = await resolveCityStateFromPincode(pincode);
      user.pincode = resolved.pincode;
      user.city =
        (resolved.areas && resolved.areas[0] && resolved.areas[0].name) ||
        user.city;
      user.state = resolved.state || user.state;
    }

    await user.save();

    return res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        pincode: user.pincode,
        city: user.city,
        state: user.state,
        address: user.address,
        approvalStatus: user.approvalStatus,
        createdAt: user.createdAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getLastOtpDev(req, res, next) {
  try {
    const { phone } = req.query;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'phone query is required' });
    }
    const result = await otpService.getLastOtpForDev(phone.trim());
    if (!result) {
      return res.status(404).json({ success: false, message: 'No OTP found for this phone' });
    }
    res.status(200).json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  signup,
  sendOtp,
  verifyOtp,
  me,
  updateMe,
  getLastOtpDev,
};
