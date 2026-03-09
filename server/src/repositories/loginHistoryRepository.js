const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

async function create({ userId, role, phone, ipAddress, userAgent }) {
  const pgUserId = await resolvePgId('users', userId);
  if (!pgUserId) return null;

  return prisma.loginHistory.create({
    data: {
      userId: pgUserId,
      role,
      phone,
      ipAddress: ipAddress || null,
      userAgent: userAgent || null,
    },
  });
}

module.exports = {
  create,
};

