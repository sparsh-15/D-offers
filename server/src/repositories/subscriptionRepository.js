const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

async function createSubscription(payload) {
  const shopkeeperId = await resolvePgId('users', payload.shopkeeperId) || payload.shopkeeperId;
  const planId = await resolvePgId('subscription_plans', payload.planId) || payload.planId;
  const cancelledBy = payload.cancelledBy
    ? await resolvePgId('users', payload.cancelledBy) || payload.cancelledBy
    : null;

  return prisma.subscription.create({
    data: {
      shopkeeperId,
      planId,
      planSnapshot: payload.planSnapshot || {},
      status: payload.status || 'pending',
      startDate: payload.startDate || null,
      endDate: payload.endDate || null,
      actualPrice: payload.actualPrice || 0,
      autoRenew: !!payload.autoRenew,
      paymentStatus: payload.paymentStatus || 'pending',
      paymentMethod: payload.paymentMethod || null,
      transactionId: payload.transactionId || null,
      couponCode: payload.couponCode || null,
      discountAmount: payload.discountAmount || 0,
      couponAgentIdSnapshot: payload.couponAgentIdSnapshot || null,
      couponAgentNameSnapshot: payload.couponAgentNameSnapshot || null,
      couponAgentRoleSnapshot: payload.couponAgentRoleSnapshot || null,
      couponCampaignSnapshot: payload.couponCampaignSnapshot || null,
      renewalCount: payload.renewalCount || 0,
      lastRenewalDate: payload.lastRenewalDate || null,
      cancelledAt: payload.cancelledAt || null,
      cancelledBy: cancelledBy || null,
      cancellationReason: payload.cancellationReason || null,
      notes: payload.notes || null,
    },
  });
}

async function updateSubscription(subscriptionId, updates) {
  const pgSubId = await resolvePgId('subscriptions', subscriptionId) || subscriptionId;
  const cancelledBy = updates.cancelledBy
    ? await resolvePgId('users', updates.cancelledBy) || updates.cancelledBy
    : undefined;

  return prisma.subscription.update({
    where: { id: pgSubId },
    data: {
      ...updates,
      ...(cancelledBy !== undefined ? { cancelledBy } : {}),
    },
  });
}

async function expireOldSubscriptions() {
  const result = await prisma.subscription.updateMany({
    where: { status: 'active', endDate: { lt: new Date() } },
    data: { status: 'expired' },
  });
  return { modifiedCount: result.count };
}

module.exports = {
  createSubscription,
  updateSubscription,
  expireOldSubscriptions,
};
