const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const { requireActiveSubscription, requireOnboardingComplete } = require('../middleware/subscriptionCheck');
const shopkeeperProfileController = require('../controllers/shopkeeperProfileController');
const offerController = require('../controllers/offerController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole(['shopkeeper', 'super_admin', 'subadmin']));

// Profile routes - accessible without subscription (needed for onboarding)
router.get('/profile', shopkeeperProfileController.getProfile);
router.put('/profile', shopkeeperProfileController.upsertProfile);

// Offer routes - require onboarding complete and active subscription
router.post('/offers', requireOnboardingComplete, requireActiveSubscription, offerController.create);
router.get('/offers', requireOnboardingComplete, requireActiveSubscription, offerController.list);
router.get('/offers/:id', requireOnboardingComplete, requireActiveSubscription, offerController.getOne);
router.put('/offers/:id', requireOnboardingComplete, requireActiveSubscription, offerController.update);
router.delete('/offers/:id', requireOnboardingComplete, requireActiveSubscription, offerController.remove);

module.exports = router;
