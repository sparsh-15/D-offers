const auditLogRepository = require('../repositories/auditLogRepository');

/**
 * Middleware to check if user has required role
 * @param {string[]} allowedRoles - Array of allowed roles
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Insufficient permissions.',
      });
    }

    next();
  };
}

/**
 * Middleware specifically for super admin only
 */
function requireSuperAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required',
    });
  }

  if (req.user.role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Super Admin access required.',
    });
  }

  next();
}

/**
 * Helper function to log admin actions
 */
async function logAdminAction(adminId, adminRole, action, targetUserId, targetUserRole, details, ipAddress) {
  try {
    await auditLogRepository.create({
      adminId,
      adminRole,
      action,
      targetUserId,
      targetUserRole,
      details,
      ipAddress,
    });
  } catch (error) {
    console.error('[AUDIT] Failed to log action:', error);
  }
}

module.exports = {
  requireRole,
  requireSuperAdmin,
  logAdminAction,
};
