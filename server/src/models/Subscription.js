const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema(
  {
    shopkeeperId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    planId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'SubscriptionPlan',
      required: true,
    },
    // Store plan details at time of subscription (for historical accuracy)
    planSnapshot: {
      name: String,
      displayName: String,
      monthlyPrice: Number,
      features: [String],
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'expired', 'cancelled', 'pending'],
      default: 'pending',
    },
    startDate: {
      type: Date,
    },
    endDate: {
      type: Date,
    },
    actualPrice: {
      type: Number,
      required: true,
      // Price at time of subscription (may differ from current plan price)
    },
    autoRenew: {
      type: Boolean,
      default: false,
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending',
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'upi', 'card', 'netbanking', 'other'],
    },
    transactionId: {
      type: String,
      trim: true,
    },
    // Coupon tracking
    couponCode: {
      type: String,
      trim: true,
      uppercase: true,
    },
    discountAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    // Renewal tracking
    renewalCount: {
      type: Number,
      default: 0,
    },
    lastRenewalDate: {
      type: Date,
    },
    // Cancellation tracking
    cancelledAt: {
      type: Date,
    },
    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    cancellationReason: {
      type: String,
      trim: true,
    },
    // Notes
    notes: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

subscriptionSchema.index({ shopkeeperId: 1 });
subscriptionSchema.index({ status: 1 });
subscriptionSchema.index({ endDate: 1 });
subscriptionSchema.index({ planId: 1 });

// Virtual for days until expiry
subscriptionSchema.virtual('daysUntilExpiry').get(function () {
  if (!this.endDate) return null;
  const now = new Date();
  const diff = this.endDate - now;
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
});

// Method to check if subscription is expiring soon
subscriptionSchema.methods.isExpiringSoon = function (days = 7) {
  const daysLeft = this.daysUntilExpiry;
  return daysLeft !== null && daysLeft > 0 && daysLeft <= days;
};

// Method to check if subscription is valid
subscriptionSchema.methods.isValid = function () {
  if (this.status !== 'active') return false;
  if (!this.endDate) return false;
  return new Date() < this.endDate;
};

// Static method to expire old subscriptions
subscriptionSchema.statics.expireOldSubscriptions = async function () {
  const now = new Date();
  const result = await this.updateMany(
    {
      status: 'active',
      endDate: { $lt: now },
    },
    {
      $set: { status: 'expired' },
    }
  );
  return result;
};

module.exports = mongoose.model('Subscription', subscriptionSchema);

