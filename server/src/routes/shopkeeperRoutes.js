const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const shopkeeperProfileController = require('../controllers/shopkeeperProfileController');
const offerController = require('../controllers/offerController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole(['shopkeeper', 'admin']));

router.get('/profile', shopkeeperProfileController.getProfile);
router.put('/profile', shopkeeperProfileController.upsertProfile);

router.post('/offers', offerController.create);
router.get('/offers', offerController.list);
router.get('/offers/:id', offerController.getOne);
router.put('/offers/:id', offerController.update);
router.delete('/offers/:id', offerController.remove);

module.exports = router;
