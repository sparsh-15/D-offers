const mongoose = require('mongoose');

const OFFER_STATUS = ['active', 'inactive', 'expired'];
const DISCOUNT_TYPE = ['percentage', 'fixed'];

const offerSchema = new mongoose.Schema(
  {
    shopkeeperId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    discountType: {
      type: String,
      enum: DISCOUNT_TYPE,
      default: 'percentage',
    },
    discountValue: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    validFrom: {
      type: Date,
      default: null,
    },
    validTo: {
      type: Date,
      default: null,
    },
    status: {
      type: String,
      enum: OFFER_STATUS,
      default: 'active',
    },
    likesCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

offerSchema.index({ shopkeeperId: 1 });
offerSchema.index({ status: 1 });
offerSchema.index({ validTo: 1 });

module.exports = mongoose.model('Offer', offerSchema);
