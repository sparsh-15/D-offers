const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const ssaController = require('../controllers/ssaController');

const router = express.Router();

// Sales Service Agent routes
router.use(authMiddleware);
router.use(requireRole('ssa'));

router.get('/stats', ssaController.getStats);
router.get('/shopkeepers', ssaController.getShopkeepers);

module.exports = router;
