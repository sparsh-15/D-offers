const jwt = require('jsonwebtoken');
const config = require('../config');
const otpService = require('../services/otpService');
const User = require('../models/User');

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
    if (!phone || !role) {
      return res.status(400).json({ success: false, message: 'Phone and role are required' });
    }
    await otpService.sendOtp(phone.trim(), role, { name, pincode, address });
    res.status(200).json({ success: true, message: 'OTP sent' });
  } catch (err) {
    next(err);
  }
}

async function verifyOtp(req, res, next) {
  try {
    const { phone, otp, role } = req.body;
    if (!phone || otp === undefined || otp === null || !role) {
      return res.status(400).json({ success: false, message: 'Phone, otp and role are required' });
    }
    const { user } = await otpService.verifyOtp(phone.trim(), String(otp), role);
    const token = issueToken(user);
    res.status(200).json({
      success: true,
      token,
      user: { id: user.id, phone: user.phone, role: user.role },
    });
  } catch (err) {
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
  getLastOtpDev,
};
