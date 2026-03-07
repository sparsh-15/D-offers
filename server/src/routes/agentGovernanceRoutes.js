const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { requireSuperAdmin } = require('../middleware/roleAuth');
const agentGovernanceController = require('../controllers/agentGovernanceController');

// All routes require authentication and super admin role
router.use(authMiddleware);
router.use(requireSuperAdmin);

// Dashboard overview
router.get('/dashboard', agentGovernanceController.getAgentGovernanceDashboard);

// SSA management
router.get('/ssa', agentGovernanceController.getSSAList);
router.post('/ssa', agentGovernanceController.createSSA);

// Company Sales Agent management
router.get('/company-sales-agents', agentGovernanceController.getCompanySalesAgentList);
router.post('/company-sales-agents', agentGovernanceController.createCompanySalesAgent);

// Coupon management
router.get('/coupons', agentGovernanceController.getCouponList);
router.get('/coupons/activations', agentGovernanceController.getCouponActivations);
router.post('/coupons', agentGovernanceController.createCoupon);

// Global coupon cap (all agents)
router.get('/settings/coupon-cap', agentGovernanceController.getCouponCap);
router.patch('/settings/coupon-cap', agentGovernanceController.updateCouponCap);

module.exports = router;
