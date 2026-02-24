const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

async function create(data) {
  const adminId = await resolvePgId('users', data.adminId);
  if (!adminId) return null;

  const targetUserId = data.targetUserId
    ? await resolvePgId('users', data.targetUserId)
    : null;

  return prisma.auditLog.create({
    data: {
      adminId,
      adminRole: data.adminRole,
      action: data.action,
      targetUserId: targetUserId || null,
      targetUserRole: data.targetUserRole || null,
      details: data.details || {},
      ipAddress: data.ipAddress || null,
    },
  });
}

module.exports = { create };
