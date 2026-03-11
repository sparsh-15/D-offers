const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const upload = require('../middleware/upload');
const uploadController = require('../controllers/uploadController');

const router = express.Router();

// Protect all upload routes - only authenticated shopkeepers and admins
router.use(authMiddleware);
router.use(requireRole(['shopkeeper', 'super_admin', 'subadmin']));

// Upload single image
router.post('/image', upload.single('image'), uploadController.uploadImage);

router.post('/shop-logo', upload.single('image'), uploadController.uploadShopLogo);

// Upload multiple images
router.post('/images', upload.array('images', 10), uploadController.uploadMultipleImages);
router.post('/shop-images', upload.array('images', 10), uploadController.uploadShopImages);

// Delete image
router.delete('/image', uploadController.deleteImage);

module.exports = router;
