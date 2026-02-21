const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    adminRole: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
      enum: [
        'user_activated',
        'user_deactivated',
        'user_approved',
        'user_rejected',
        'subscription_created',
        'subscription_updated',
        'subscription_cancelled',
        'subscription_renewed',
        'shop_approved',
        'shop_rejected',
        'coupon_activated',
        'agent_assigned',
      ],
    },
    targetUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    targetUserRole: {
      type: String,
    },
    details: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    ipAddress: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

auditLogSchema.index({ adminId: 1, createdAt: -1 });
auditLogSchema.index({ targetUserId: 1 });
auditLogSchema.index({ action: 1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
