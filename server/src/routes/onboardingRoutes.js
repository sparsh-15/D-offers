const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const onboardingController = require('../controllers/onboardingController');

const router = express.Router();

// All onboarding routes require authentication and shopkeeper role
router.use(authMiddleware);
router.use(requireRole('shopkeeper'));

router.get('/status', onboardingController.getOnboardingStatus);
router.post('/accept-terms', onboardingController.acceptTerms);
router.post('/complete-profile', onboardingController.completeBusinessProfile);
router.post('/complete', onboardingController.completeOnboarding);

module.exports = router;
