const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const adminController = require('../controllers/adminController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole(['admin']));

router.get('/shopkeepers', adminController.listShopkeepers);
router.patch('/shopkeepers/:id/approve', adminController.approveShopkeeper);
router.patch('/shopkeepers/:id/reject', adminController.rejectShopkeeper);

module.exports = router;

