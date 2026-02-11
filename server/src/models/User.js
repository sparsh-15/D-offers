const mongoose = require('mongoose');
const { ROLES } = require('../config');

const userSchema = new mongoose.Schema(
  {
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
  },
  {
    timestamps: true,
  }
);

userSchema.index({ phone: 1 });

module.exports = mongoose.model('User', userSchema);
