const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const companySalesController = require('../controllers/companySalesController');

const router = express.Router();

// Company Sales Agent routes
router.use(authMiddleware);
router.use(requireRole('company_sales_agent'));

// Company Sales Dashboard stats
router.get('/stats', companySalesController.getStats);

// Shops onboarded by CSA with subscription status
router.get('/shops', companySalesController.getShops);

// Performance reports
router.get('/reports', companySalesController.getReports);

// Coupons (auto-created by discount combinations up to agent cap)
router.get('/coupons', companySalesController.getCoupons);

module.exports = router;
