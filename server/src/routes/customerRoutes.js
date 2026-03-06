const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const customerController = require('../controllers/customerController');
const shopkeeperProfileController = require('../controllers/shopkeeperProfileController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole(['customer', 'super_admin', 'subadmin', 'ssa']));

router.get('/offers', customerController.listOffers);
router.post('/offers/:id/like', customerController.toggleLike);
router.get('/offers/liked', customerController.getLikedOffers);
router.post('/callbacks', customerController.requestCallback);
router.post('/become-ssa', customerController.becomeSSA);

// Public shop profile for offer details
router.get('/shops/:shopkeeperId/profile', shopkeeperProfileController.getPublicProfile);

module.exports = router;
