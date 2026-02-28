const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireAdmin } = require('../middleware/roleCheck');
const adminController = require('../controllers/adminController');

const router = express.Router();

router.use(authMiddleware);
router.use(requireAdmin); // Allows super_admin and subadmin

router.get('/stats', adminController.getStats);
router.get('/users/stats', adminController.getUsersStats);
router.get('/users', adminController.listUsers);
router.get('/meta/locations', adminController.getLocationOptions);
router.get('/shopkeepers', adminController.listShopkeepers);
router.patch('/shopkeepers/:id/approve', adminController.approveShopkeeper);
router.patch('/shopkeepers/:id/reject', adminController.rejectShopkeeper);

module.exports = router;

