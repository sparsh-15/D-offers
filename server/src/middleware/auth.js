const jwt = require('jsonwebtoken');
const config = require('../config');

function normalizeRole(rawRole) {
  if (rawRole == null) return rawRole;

  const role = String(rawRole).trim().toLowerCase();
  const roleAliases = {
    superadmin: 'super_admin',
    admin: 'super_admin',
    companysalesagent: 'company_sales_agent',
    company_salesagent: 'company_sales_agent',
    companysales_agent: 'company_sales_agent',
  };

  return roleAliases[role] || role;
}

function normalizeRolesFromClaims(primaryRole, permissions) {
  const roles = new Set();
  const normalizedPrimary = normalizeRole(primaryRole);
  if (normalizedPrimary) {
    roles.add(normalizedPrimary);
  }

  // Backward compatibility: historically some customer users were converted to
  // primary role `ssa`. They still need customer-scoped access (e.g. wallet).
  if (normalizedPrimary === 'ssa') {
    roles.add('customer');
  }

  const claims = Array.isArray(permissions) ? permissions : [];
  for (const claim of claims) {
    const normalized = normalizeRole(claim);
    if (normalized && config.ROLES.includes(normalized)) {
      roles.add(normalized);
    }
  }

  return Array.from(roles);
}

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : req.headers['x-access-token'];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    const role = normalizeRole(decoded.role);
    const roles = normalizeRolesFromClaims(role, decoded.permissions);

    req.user = {
      userId: decoded.userId,
      phone: decoded.phone,
      role,
      roles,
      permissions: Array.isArray(decoded.permissions)
        ? decoded.permissions
        : [],
    };
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }
    return res.status(401).json({ success: false, message: 'Authentication failed' });
  }
}

module.exports = authMiddleware;
