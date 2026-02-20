const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { requireSuperAdmin } = require('../middleware/roleAuth');
const subscriptionPlanController = require('../controllers/subscriptionPlanController');
const subscriptionGovernanceController = require('../controllers/subscriptionGovernanceController');

// All routes require authentication and super admin role
router.use(authMiddleware);
router.use(requireSuperAdmin);

// ============ Business Categories ============

// Get all business categories
router.get('/categories', subscriptionPlanController.getCategories);

// ============ Subscription Plan Management ============

// Create new plan
router.post('/plans', subscriptionPlanController.createPlan);

// Get all plans
router.get('/plans', subscriptionPlanController.getAllPlans);

// Get plan by ID
router.get('/plans/:planId', subscriptionPlanController.getPlanById);

// Update plan
router.patch('/plans/:planId', subscriptionPlanController.updatePlan);

// Delete (deactivate) plan
router.delete('/plans/:planId', subscriptionPlanController.deletePlan);

// Get recommended plans for category
router.get('/plans/recommend/category', subscriptionPlanController.getRecommendedPlans);

// ============ Subscription Management ============

// Create subscription
router.post('/subscriptions', subscriptionGovernanceController.createSubscription);

// Get all subscriptions
router.get('/subscriptions', subscriptionGovernanceController.getAllSubscriptions);

// Update subscription
router.patch(
  '/subscriptions/:subscriptionId',
  subscriptionGovernanceController.updateSubscription
);

// Cancel subscription
router.post(
  '/subscriptions/:subscriptionId/cancel',
  subscriptionGovernanceController.cancelSubscription
);

// Renew subscription
router.post(
  '/subscriptions/:subscriptionId/renew',
  subscriptionGovernanceController.renewSubscription
);

// ============ Monitoring & Intelligence ============

// Get monitoring dashboard
router.get('/monitoring/dashboard', subscriptionGovernanceController.getMonitoringDashboard);

// Get revenue intelligence
router.get('/intelligence/revenue', subscriptionGovernanceController.getRevenueIntelligence);

// Run expiry check (for cron jobs)
router.post('/maintenance/expire-check', subscriptionGovernanceController.runExpiryCheck);

module.exports = router;
