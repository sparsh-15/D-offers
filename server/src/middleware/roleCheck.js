const { ROLES } = require('../config');

/**
 * Middleware to require specific role(s)
 * @param {string|string[]} roles - Single role or array of allowed roles
 */
function requireRole(roles) {
  const allowed = Array.isArray(roles) ? roles : [roles];
  
  // Validate that all specified roles are valid
  const invalidRoles = allowed.filter(role => !ROLES.includes(role));
  if (invalidRoles.length > 0) {
    throw new Error(`Invalid roles specified: ${invalidRoles.join(', ')}`);
  }

  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }
    
    if (!allowed.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        message: 'Insufficient permissions',
        code: 'INSUFFICIENT_PERMISSIONS',
        requiredRoles: allowed,
        userRole: req.user.role
      });
    }
    
    next();
  };
}

/**
 * Middleware to check if user is any type of admin
 */
function requireAdmin(req, res, next) {
  const adminRoles = ['super_admin', 'subadmin'];
  
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required',
      code: 'AUTH_REQUIRED'
    });
  }
  
  if (!adminRoles.includes(req.user.role)) {
    return res.status(403).json({ 
      success: false, 
      message: 'Admin access required',
      code: 'ADMIN_ACCESS_REQUIRED'
    });
  }
  
  next();
}

/**
 * Middleware to check if user is super admin only
 */
function requireSuperAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      message: 'Authentication required',
      code: 'AUTH_REQUIRED'
    });
  }
  
  if (req.user.role !== 'super_admin') {
    return res.status(403).json({ 
      success: false, 
      message: 'Super admin access required',
      code: 'SUPER_ADMIN_REQUIRED'
    });
  }
  
  next();
}

module.exports = { 
  requireRole, 
  requireAdmin, 
  requireSuperAdmin 
};
