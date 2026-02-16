const express = require('express');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/roleCheck');
const upload = require('../middleware/upload');
const uploadController = require('../controllers/uploadController');

const router = express.Router();

// Protect all upload routes - only authenticated shopkeepers and admins
router.use(authMiddleware);
router.use(requireRole(['shopkeeper', 'admin']));

// Upload single image
router.post('/image', upload.single('image'), uploadController.uploadImage);

// Upload multiple images
router.post('/images', upload.array('images', 10), uploadController.uploadMultipleImages);

// Delete image
router.delete('/image', uploadController.deleteImage);

module.exports = router;
