const mongoose = require('mongoose');
const { ROLES } = require('../config');

const APPROVAL_STATUS = ['pending', 'approved', 'rejected'];

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      default: '',
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    role: {
      type: String,
      required: true,
      enum: ROLES,
    },
    pincode: {
      type: String,
      trim: true,
      default: '',
    },
    city: {
      type: String,
      trim: true,
      default: '',
    },
    state: {
      type: String,
      trim: true,
      default: '',
    },
    address: {
      type: String,
      trim: true,
      default: '',
    },
    approvalStatus: {
      type: String,
      enum: APPROVAL_STATUS,
      default: function () {
        // customers and admin are effectively always approved
        if (this.role === 'shopkeeper') return 'pending';
        return 'approved';
      },
    },
  },
  {
    timestamps: true,
  }
);

userSchema.index({ phone: 1 });
userSchema.index({ role: 1, approvalStatus: 1 });

module.exports = mongoose.model('User', userSchema);
