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

// Company Sales Agent management
router.get('/company-sales-agents', agentGovernanceController.getCompanySalesAgentList);

// Coupon tracking
router.get('/coupons/activations', agentGovernanceController.getCouponActivations);

module.exports = router;
