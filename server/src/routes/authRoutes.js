const express = require('express');
const rateLimit = require('express-rate-limit');
const config = require('../config');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { success: false, message: 'Too many attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

router.post('/send-otp', authLimiter, authController.sendOtp);
router.post('/verify-otp', authLimiter, authController.verifyOtp);
router.get('/me', authMiddleware, authController.me);
router.put('/me', authMiddleware, authController.updateMe);
router.post('/signup', authLimiter, authController.signup);

if (config.isDev) {
  router.get('/dev/last-otp', authController.getLastOtpDev);
}

module.exports = router;
