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
    email: {
      type: String,
      trim: true,
      sparse: true, // Allows null/undefined but enforces uniqueness when present
      lowercase: true,
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    password: {
      type: String,
      select: false, // Don't include password in queries by default
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
    region: {
      type: String,
      trim: true,
      default: '',
    },
    territory: {
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
        // Shopkeepers require approval
        if (this.role === 'shopkeeper') return 'pending';
        // All other roles are auto-approved
        return 'approved';
      },
    },
    // Additional fields for admin roles
    permissions: {
      type: [String],
      default: [],
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

userSchema.index({ phone: 1 });
userSchema.index({ email: 1 });
userSchema.index({ role: 1, approvalStatus: 1 });

module.exports = mongoose.model('User', userSchema);
