const ShopkeeperProfile = require('../models/ShopkeeperProfile');
const mongoose = require('mongoose');

async function getProfile(req, res, next) {
  try {
    let userId = req.user.userId;
    if (req.user.role === 'admin' && req.query.userId) {
      userId = req.query.userId;
    }
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      const err = new Error('Invalid user id');
      err.statusCode = 400;
      return next(err);
    }
    const profile = await ShopkeeperProfile.findOne({ userId }).lean();
    if (!profile) {
      const err = new Error('Profile not found');
      err.statusCode = 404;
      return next(err);
    }
    res.status(200).json({
      success: true,
      profile: {
        id: profile._id,
        userId: profile.userId,
        shopName: profile.shopName,
        address: profile.address,
        pincode: profile.pincode,
        city: profile.city,
        category: profile.category,
        description: profile.description,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function upsertProfile(req, res, next) {
  try {
    const { shopName, address, pincode, city, category, description } = req.body;
    if (!shopName || typeof shopName !== 'string' || !shopName.trim()) {
      const err = new Error('shopName is required');
      err.statusCode = 400;
      return next(err);
    }
    const userId = req.user.userId;
    const update = {
      shopName: shopName.trim(),
      address: address != null ? String(address).trim() : undefined,
      pincode: pincode != null ? String(pincode).trim() : undefined,
      city: city != null ? String(city).trim() : undefined,
      category: category != null ? String(category).trim() : undefined,
      description: description != null ? String(description).trim() : undefined,
    };
    const profile = await ShopkeeperProfile.findOneAndUpdate(
      { userId },
      { $set: update },
      { new: true, upsert: true, runValidators: true }
    );
    res.status(200).json({
      success: true,
      profile: {
        id: profile._id,
        userId: profile.userId,
        shopName: profile.shopName,
        address: profile.address,
        pincode: profile.pincode,
        city: profile.city,
        category: profile.category,
        description: profile.description,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getProfile,
  upsertProfile,
};
