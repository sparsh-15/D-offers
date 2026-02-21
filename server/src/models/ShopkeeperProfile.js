const mongoose = require('mongoose');
const { BUSINESS_CATEGORY_LIST } = require('../config/businessCategories');

const shopkeeperProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    shopName: {
      type: String,
      required: true,
      trim: true,
    },
    address: {
      type: String,
      trim: true,
    },
    pincode: {
      type: String,
      trim: true,
    },
    city: {
      type: String,
      trim: true,
    },
    category: {
      type: String,
      enum: BUSINESS_CATEGORY_LIST,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    // Agent tracking
    onboardedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
  }
);

shopkeeperProfileSchema.index({ userId: 1 }, { unique: true });
shopkeeperProfileSchema.index({ category: 1 });

module.exports = mongoose.model('ShopkeeperProfile', shopkeeperProfileSchema);
