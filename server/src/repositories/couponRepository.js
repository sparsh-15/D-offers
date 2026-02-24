const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

async function createCoupon(payload) {
  const agentId = await resolvePgId('users', payload.agentId) || payload.agentId;
  return prisma.coupon.create({
    data: {
      code: payload.code,
      discountType: payload.discountType,
      discountValue: payload.discountValue,
      agentId,
      description: payload.description || null,
      expiryDate: payload.expiryDate || null,
      maxUses: payload.maxUses ?? null,
      currentUses: payload.currentUses || 0,
      isActive: payload.isActive !== false,
    },
  });
}

module.exports = { createCoupon };
