const express = require('express');
const rateLimit = require('express-rate-limit');
const config = require('../config');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Rate limiter for regular users (customers and shopkeepers)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  message: { success: false, message: 'Too many attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    console.warn(`[RATE_LIMIT] Regular user rate limit exceeded - IP: ${req.ip}, Path: ${req.path}`);
    res.status(429).json({ 
      success: false, 
      message: 'Too many attempts, please try again later' 
    });
  },
});

// Rate limiter for admin users (more lenient)
const adminAuthLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Higher limit for admin
  message: { success: false, message: 'Too many attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    console.warn(`[RATE_LIMIT] Admin rate limit exceeded - IP: ${req.ip}, Path: ${req.path}`);
    res.status(429).json({ 
      success: false, 
      message: 'Too many attempts, please try again later' 
    });
  },
});

// Middleware to select rate limiter based on role
const selectRateLimiter = (req, res, next) => {
  const role = req.body?.role;
  if (role === 'admin') {
    return adminAuthLimiter(req, res, next);
  }
  return authLimiter(req, res, next);
};

router.post('/send-otp', selectRateLimiter, authController.sendOtp);
router.post('/verify-otp', selectRateLimiter, authController.verifyOtp);
router.get('/me', authMiddleware, authController.me);
router.put('/me', authMiddleware, authController.updateMe);
router.post('/signup', authLimiter, authController.signup);

if (config.isDev) {
  router.get('/dev/last-otp', authController.getLastOtpDev);
}

module.exports = router;
