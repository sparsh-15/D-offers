const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { requireSuperAdmin } = require('../middleware/roleAuth');
const superAdminController = require('../controllers/superAdminController');

// All routes require authentication and super admin role
router.use(authMiddleware);
router.use(requireSuperAdmin);

// Dashboard analytics
router.get('/analytics', superAdminController.getDashboardAnalytics);

// User management
router.get('/users', superAdminController.getAllUsers);
router.get('/users/:userId', superAdminController.getUserDetails);
router.patch('/users/:userId/status', superAdminController.toggleUserStatus);
router.patch('/users/:userId/approval', superAdminController.updateApprovalStatus);

// Shop management
router.get('/shops', superAdminController.getAllShops);

// Audit logs
router.get('/audit-logs', superAdminController.getAuditLogs);

module.exports = router;
