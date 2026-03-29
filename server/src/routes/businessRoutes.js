const express = require('express');
const rateLimit = require('express-rate-limit');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const redemptionController = require('../controllers/redemptionController');

const router = express.Router();

const redemptionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 60,
  message: { success: false, message: 'Too many redemption attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

router.use(authMiddleware);
router.use(requireRole(['shopkeeper', 'ssa', 'company_sales_agent', 'subadmin', 'super_admin']));

router.post('/redemptions/verify', redemptionLimiter, redemptionController.verify);
router.post('/redemptions/manual-verify', redemptionLimiter, redemptionController.manualVerify);
router.post('/redemptions/redeem', redemptionLimiter, redemptionController.redeem);
router.get('/redemptions/history', redemptionController.history);

module.exports = router;
