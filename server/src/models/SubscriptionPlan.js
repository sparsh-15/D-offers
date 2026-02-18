const mongoose = require('mongoose');

const subscriptionPlanSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    displayName: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default: '',
    },
    monthlyPrice: {
      type: Number,
      required: true,
      min: 0,
    },
    categories: {
      type: [String],
      default: [],
      // Categories this plan applies to (e.g., ['restaurant', 'retail', 'services'])
    },
    features: {
      type: [String],
      default: [],
      // List of features included in this plan
    },
    maxOffers: {
      type: Number,
      default: -1, // -1 means unlimited
    },
    maxPhotosPerOffer: {
      type: Number,
      default: 5,
    },
    analyticsEnabled: {
      type: Boolean,
      default: false,
    },
    prioritySupport: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
      // For displaying plans in order
    },
    // Pricing history for audit trail
    priceHistory: [
      {
        price: Number,
        changedBy: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        changedAt: {
          type: Date,
          default: Date.now,
        },
        reason: String,
      },
    ],
  },
  {
    timestamps: true,
  }
);

subscriptionPlanSchema.index({ name: 1 });
subscriptionPlanSchema.index({ isActive: 1 });
subscriptionPlanSchema.index({ categories: 1 });

// Method to update price with history tracking
subscriptionPlanSchema.methods.updatePrice = function (newPrice, adminId, reason) {
  this.priceHistory.push({
    price: this.monthlyPrice,
    changedBy: adminId,
    changedAt: new Date(),
    reason: reason || 'Price update',
  });
  this.monthlyPrice = newPrice;
  return this.save();
};

module.exports = mongoose.model('SubscriptionPlan', subscriptionPlanSchema);
