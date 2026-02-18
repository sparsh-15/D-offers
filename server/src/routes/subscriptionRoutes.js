const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const subscriptionController = require('../controllers/subscriptionController');

const router = express.Router();

// All subscription routes require authentication and shopkeeper role
router.use(authMiddleware);
router.use(requireRole('shopkeeper'));

router.get('/', subscriptionController.getSubscription);
router.get('/plans', subscriptionController.getPlans);
router.post('/trial', subscriptionController.activateTrial);
router.post('/activate', subscriptionController.createSubscription);
router.post('/cancel', subscriptionController.cancelSubscription);

module.exports = router;
