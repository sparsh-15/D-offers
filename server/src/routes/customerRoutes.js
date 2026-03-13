const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const customerController = require('../controllers/customerController');
const shopkeeperProfileController = require('../controllers/shopkeeperProfileController');
const loanController = require('../controllers/loanController');
const campaignController = require('../controllers/campaignController');

const router = express.Router();

router.use(authMiddleware);
router.use(
  requireRole([
    'customer',
    'super_admin',
    'subadmin',
    'ssa',
    'shopkeeper',
    'company_sales_agent',
  ]),
);

router.get('/offers', customerController.listOffers);
router.post('/offers/:id/like', customerController.toggleLike);
router.get('/offers/liked', customerController.getLikedOffers);
router.get('/offers/:id', customerController.getOfferById);
router.post('/callbacks', customerController.requestCallback);
router.post('/become-ssa', customerController.becomeSSA);
router.get('/inbox', campaignController.listInbox);
router.get('/inbox/unread-count', campaignController.getUnreadInboxCount);
router.patch('/inbox/:id/read', campaignController.markInboxMessageRead);

// Loan application routes
router.post('/loans/apply', loanController.submitLoanApplication);
router.get('/loans', loanController.getLoanApplications);
router.get('/loans/:id', loanController.getLoanApplicationById);

// Public shop profile for offer details
router.get('/shops/:shopkeeperId/profile', shopkeeperProfileController.getPublicProfile);

module.exports = router;
