const cloudinary = require('../config/cloudinary');

async function uploadToFolder(filePath, folder, transformation) {
  return cloudinary.uploader.upload(filePath, {
    folder,
    resource_type: 'image',
    transformation,
  });
}

async function uploadImage(req, res, next) {
  try {
    if (!req.file) {
      const err = new Error('No file uploaded');
      err.statusCode = 400;
      return next(err);
    }

    // Upload to Cloudinary
    const result = await uploadToFolder(req.file.path, 'd-offers/offer-images', [
      { width: 1920, height: 1080, crop: 'limit' },
      { quality: 'auto:good' },
    ]);

    res.status(200).json({
      success: true,
      url: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    console.error('Upload error:', err);
    next(err);
  }
}

async function uploadMultipleImages(req, res, next) {
  try {
    if (!req.files || req.files.length === 0) {
      const err = new Error('No files uploaded');
      err.statusCode = 400;
      return next(err);
    }

    // Upload all files to Cloudinary
    const uploadPromises = req.files.map((file) =>
      uploadToFolder(file.path, 'd-offers/offer-images', [
        { width: 1920, height: 1080, crop: 'limit' },
        { quality: 'auto:good' },
      ])
    );

    const results = await Promise.all(uploadPromises);

    res.status(200).json({
      success: true,
      images: results.map((result) => ({
        url: result.secure_url,
        publicId: result.public_id,
      })),
    });
  } catch (err) {
    console.error('Upload error:', err);
    next(err);
  }
}

async function uploadShopLogo(req, res, next) {
  try {
    if (!req.file) {
      const err = new Error('No file uploaded');
      err.statusCode = 400;
      return next(err);
    }

    const result = await uploadToFolder(req.file.path, 'd-offers/shop-logos', [
      { width: 600, height: 600, crop: 'limit' },
      { quality: 'auto:good' },
    ]);

    res.status(200).json({
      success: true,
      url: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    console.error('Upload error:', err);
    next(err);
  }
}

async function uploadShopImages(req, res, next) {
  try {
    if (!req.files || req.files.length === 0) {
      const err = new Error('No files uploaded');
      err.statusCode = 400;
      return next(err);
    }

    const uploadPromises = req.files.map((file) =>
      uploadToFolder(file.path, 'd-offers/shop-images', [
        { width: 1920, height: 1080, crop: 'limit' },
        { quality: 'auto:good' },
      ])
    );

    const results = await Promise.all(uploadPromises);

    res.status(200).json({
      success: true,
      images: results.map((result) => ({
        url: result.secure_url,
        publicId: result.public_id,
      })),
    });
  } catch (err) {
    console.error('Upload error:', err);
    next(err);
  }
}

async function deleteImage(req, res, next) {
  try {
    const { publicId } = req.body;

    if (!publicId) {
      const err = new Error('Public ID is required');
      err.statusCode = 400;
      return next(err);
    }

    await cloudinary.uploader.destroy(publicId);

    res.status(200).json({
      success: true,
      message: 'Image deleted successfully',
    });
  } catch (err) {
    console.error('Delete error:', err);
    next(err);
  }
}

module.exports = {
  uploadImage,
  uploadMultipleImages,
  uploadShopLogo,
  uploadShopImages,
  deleteImage,
};
