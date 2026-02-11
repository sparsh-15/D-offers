const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const customerController = require('../controllers/customerController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole(['customer', 'admin']));

router.get('/offers', customerController.listOffers);

module.exports = router;
