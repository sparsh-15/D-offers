const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const {
  requireActiveSubscription,
  checkSubscriptionStatus,
  checkOfferLimit,
  checkAiCreditLimit,
  checkCampaignFeatureAccess,
  checkCampaignMessageQuota,
} = require('../middleware/subscriptionCheck');
const shopkeeperProfileController = require('../controllers/shopkeeperProfileController');
const offerController = require('../controllers/offerController');
const subscriptionPlanController = require('../controllers/subscriptionPlanController');
const shopkeeperAiController = require('../controllers/shopkeeperAiController');
const campaignController = require('../controllers/campaignController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole('shopkeeper', 'super_admin', 'subadmin'));

// Profile routes - accessible without subscription (needed for onboarding)
router.get('/profile', shopkeeperProfileController.getProfile);
router.put('/profile', shopkeeperProfileController.upsertProfile);
router.patch('/profile/images', shopkeeperProfileController.updateShopImages);
router.patch('/profile/logo', shopkeeperProfileController.updateLogoUrl);

// Subscription plan viewing (for shopkeepers to see available plans)
router.get('/plans', subscriptionPlanController.getAllPlans);
router.get('/plans/recommend', subscriptionPlanController.getRecommendedPlans);

// AI wallet and credit packs (require active subscription for purchase/use)
router.get('/ai-wallet', shopkeeperAiController.getAiWallet);
router.get('/ai-credits/packs', shopkeeperAiController.getAiCreditPacks);
router.post('/ai-credits/purchase', requireActiveSubscription, shopkeeperAiController.purchaseAiCreditPack);
router.post('/ai-banners/use', requireActiveSubscription, checkAiCreditLimit, shopkeeperAiController.useAiBanner);
router.post(
  '/ai/banner',
  requireActiveSubscription,
  checkAiCreditLimit,
  shopkeeperAiController.generateBanner,
);

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

// Campaign routes - require active subscription
router.post(
  '/campaigns/estimate-audience',
  requireActiveSubscription,
  checkCampaignFeatureAccess,
  campaignController.estimateAudienceHandler,
);
router.post(
  '/campaigns',
  requireActiveSubscription,
  checkCampaignFeatureAccess,
  checkCampaignMessageQuota,
  campaignController.createCampaign,
);
router.get('/campaigns', requireActiveSubscription, campaignController.listCampaigns);
router.get('/campaigns/templates', requireActiveSubscription, campaignController.getCampaignTemplates);
router.get('/campaigns/:id', requireActiveSubscription, campaignController.getCampaign);
router.put(
  '/campaigns/:id',
  requireActiveSubscription,
  checkCampaignFeatureAccess,
  checkCampaignMessageQuota,
  campaignController.updateCampaign,
);
router.post('/campaigns/:id/pay', requireActiveSubscription, checkCampaignMessageQuota, campaignController.payCampaign);
router.post('/campaigns/:id/cancel', requireActiveSubscription, campaignController.cancelCampaign);
router.delete('/campaigns/:id', requireActiveSubscription, campaignController.deleteCampaign);

module.exports = router;
