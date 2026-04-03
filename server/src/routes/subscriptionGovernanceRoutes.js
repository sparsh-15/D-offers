const express = require('express');
const multer = require('multer');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { requireSuperAdmin } = require('../middleware/roleAuth');
const subscriptionPlanController = require('../controllers/subscriptionPlanController');
const subscriptionGovernanceController = require('../controllers/subscriptionGovernanceController');
const aiCreditPackController = require('../controllers/aiCreditPackController');

const planBulkUpload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    const originalName = String(file.originalname || '').toLowerCase();
    const isCsv = originalName.endsWith('.csv');
    const isXlsx = originalName.endsWith('.xlsx');
    if (isCsv || isXlsx) return cb(null, true);
    return cb(new Error('Only .csv or .xlsx files are allowed'));
  },
});

// ============ Test APIs (public for quick testing) ============
router.post('/test-data/users/bulk', subscriptionGovernanceController.bulkCreateUsers);
router.post('/test-data/subscriptions/bulk', subscriptionGovernanceController.bulkSubscribeUsersToPlans);
router.post('/test-data/offers/bulk', subscriptionGovernanceController.bulkCreateOffers);
router.post('/test-data/ai-packs/bulk', subscriptionGovernanceController.bulkCreateAiPacks);

// All routes require authentication and super admin role
router.use(authMiddleware);
router.use(requireSuperAdmin);

// ============ Business Categories ============

// Get all business categories
router.get('/categories', subscriptionPlanController.getCategories);

// ============ Subscription Plan Management ============

// Create new plan
router.post('/plans', subscriptionPlanController.createPlan);

// Download new-plan template
router.get('/plans/template', subscriptionPlanController.downloadPlanTemplate);

// Export plans
router.get('/plans/export', subscriptionPlanController.exportPlans);

// Bulk import plans
router.post(
  '/plans/import',
  planBulkUpload.single('file'),
  subscriptionPlanController.importPlans
);

// Get recommended plans for category
router.get('/plans/recommend/category', subscriptionPlanController.getRecommendedPlans);

// Get all plans
router.get('/plans', subscriptionPlanController.getAllPlans);

// Get plan by ID
router.get('/plans/:planId', subscriptionPlanController.getPlanById);

// Update plan
router.patch('/plans/:planId', subscriptionPlanController.updatePlan);

// Delete (deactivate) plan
router.delete('/plans/:planId', subscriptionPlanController.deletePlan);

// ============ AI Credit Packs (Admin) ============

router.get('/ai-credit-packs/template', aiCreditPackController.downloadAiPackTemplate);
router.get('/ai-credit-packs/export', aiCreditPackController.exportAiPacks);
router.post(
  '/ai-credit-packs/import',
  planBulkUpload.single('file'),
  aiCreditPackController.importAiPacks
);
router.get('/ai-credit-packs', aiCreditPackController.getAllPacks);
router.get('/ai-credit-packs/:packId', aiCreditPackController.getPackById);
router.post('/ai-credit-packs', aiCreditPackController.createPack);
router.patch('/ai-credit-packs/:packId', aiCreditPackController.updatePack);
router.delete('/ai-credit-packs/:packId', aiCreditPackController.deletePack);

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

// Get subscription metrics (by tier, with filters)
router.get(
  '/analytics/subscription-metrics',
  subscriptionGovernanceController.getSubscriptionMetrics
);

// Get revenue intelligence
router.get('/intelligence/revenue', subscriptionGovernanceController.getRevenueIntelligence);

// Run expiry check (for cron jobs)
router.post('/maintenance/expire-check', subscriptionGovernanceController.runExpiryCheck);

module.exports = router;
