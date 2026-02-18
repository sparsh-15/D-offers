const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const {
  requireActiveSubscription,
  checkSubscriptionStatus,
  checkOfferLimit,
} = require('../middleware/subscriptionCheck');
const shopkeeperProfileController = require('../controllers/shopkeeperProfileController');
const offerController = require('../controllers/offerController');
const subscriptionPlanController = require('../controllers/subscriptionPlanController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole('shopkeeper', 'super_admin', 'subadmin'));

// Profile routes - accessible without subscription (needed for onboarding)
router.get('/profile', shopkeeperProfileController.getProfile);
router.put('/profile', shopkeeperProfileController.upsertProfile);

// Subscription plan viewing (for shopkeepers to see available plans)
router.get('/plans', subscriptionPlanController.getAllPlans);
router.get('/plans/recommend', subscriptionPlanController.getRecommendedPlans);

// Dashboard - check subscription status but don't block
router.get('/dashboard', checkSubscriptionStatus, shopkeeperProfileController.getDashboard);

// Offer routes - require active subscription
router.post(
  '/offers',
  requireActiveSubscription,
  checkOfferLimit,
  offerController.create
);
router.get('/offers', requireActiveSubscription, offerController.list);
router.get('/offers/:id', requireActiveSubscription, offerController.getOne);
router.put('/offers/:id', requireActiveSubscription, offerController.update);
router.delete('/offers/:id', requireActiveSubscription, offerController.remove);

module.exports = router;
