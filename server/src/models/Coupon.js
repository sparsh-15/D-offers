const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema(
  {
    code: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
    },
    discountType: {
      type: String,
      enum: ['percentage', 'fixed'],
      required: true,
    },
    discountValue: {
      type: Number,
      required: true,
      min: 0,
    },
    agentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    description: {
      type: String,
      trim: true,
    },
    expiryDate: {
      type: Date,
    },
    maxUses: {
      type: Number,
      default: null, // null means unlimited
    },
    currentUses: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster lookups
couponSchema.index({ code: 1 });
couponSchema.index({ agentId: 1 });
couponSchema.index({ isActive: 1 });

// Method to check if coupon is valid
couponSchema.methods.isValid = function () {
  if (!this.isActive) return false;
  if (this.expiryDate && this.expiryDate < new Date()) return false;
  if (this.maxUses && this.currentUses >= this.maxUses) return false;
  return true;
};

// Method to apply coupon
couponSchema.methods.apply = function (amount) {
  if (!this.isValid()) {
    throw new Error('Coupon is not valid');
  }

  let discount = 0;
  if (this.discountType === 'percentage') {
    discount = (amount * this.discountValue) / 100;
  } else {
    discount = this.discountValue;
  }

  // Ensure discount doesn't exceed the amount
  discount = Math.min(discount, amount);

  return {
    originalAmount: amount,
    discount,
    finalAmount: amount - discount,
  };
};

module.exports = mongoose.model('Coupon', couponSchema);
