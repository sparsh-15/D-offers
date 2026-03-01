const { prisma } = require('../db/prisma');
const { logAdminAction } = require('../middleware/roleAuth');
const subscriptionRepository = require('../repositories/subscriptionRepository');
const { resolvePgId } = require('../repositories/idResolver');
const { buildPlanSnapshot, upsertWalletForSubscription } = require('../services/aiWalletService');

async function createSubscription(req, res, next) {
  try {
    const { shopkeeperId, planId, startDate, durationMonths = 1, autoRenew = false, paymentMethod, transactionId, notes } = req.body;
    if (!shopkeeperId || !planId) return res.status(400).json({ success: false, message: 'Shopkeeper ID and Plan ID are required' });
    const pgShopkeeperId = await resolvePgId('users', shopkeeperId) || shopkeeperId;
    const shopkeeper = await prisma.user.findUnique({ where: { id: pgShopkeeperId } });
    if (!shopkeeper || shopkeeper.role !== 'shopkeeper') return res.status(404).json({ success: false, message: 'Shopkeeper not found' });
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Subscription plan not found' });
    if (!plan.isActive) return res.status(400).json({ success: false, message: 'This plan is no longer available' });
    const start = startDate ? new Date(startDate) : new Date();
    const end = new Date(start);
    end.setMonth(end.getMonth() + durationMonths);
    const planSnapshot = buildPlanSnapshot(plan);
    const subscription = await subscriptionRepository.createSubscription({
      shopkeeperId: pgShopkeeperId,
      planId: plan.id,
      planSnapshot,
      status: 'active',
      startDate: start,
      endDate: end,
      actualPrice: Number(plan.monthlyPrice) * Number(durationMonths),
      autoRenew,
      paymentStatus: 'paid',
      paymentMethod,
      transactionId,
      notes,
    });
    await upsertWalletForSubscription(subscription);
    await logAdminAction(req.user.userId, req.user.role, 'subscription_created', shopkeeperId, 'shopkeeper', { subscriptionId: subscription.id, planName: plan.name, duration: durationMonths }, req.ip);
    res.status(201).json({ success: true, message: 'Subscription created successfully', data: subscription });
  } catch (err) {
    next(err);
  }
}

async function getMonitoringDashboard(req, res, next) {
  try {
    const now = new Date();
    const sevenDaysFromNow = new Date(now);
    sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const statusGroups = await prisma.subscription.groupBy({
      by: ['status'],
      _count: { _all: true },
      _sum: { actualPrice: true },
    });
    const statusCounts = statusGroups.reduce((acc, g) => {
      acc[g.status] = { count: g._count._all, revenue: Number(g._sum.actualPrice || 0) };
      return acc;
    }, {});

    const [expiringSoon, recentlyExpired, pending, activeSubscriptions] = await Promise.all([
      prisma.subscription.findMany({
        where: { status: 'active', endDate: { gte: now, lte: sevenDaysFromNow } },
        orderBy: { endDate: 'asc' },
        include: { shopkeeper: { select: { name: true, phone: true } }, plan: { select: { displayName: true, monthlyPrice: true } } },
      }),
      prisma.subscription.findMany({
        where: { status: 'expired', endDate: { gte: sevenDaysAgo, lte: now } },
        orderBy: { endDate: 'desc' },
        include: { shopkeeper: { select: { name: true, phone: true } }, plan: { select: { displayName: true, monthlyPrice: true } } },
      }),
      prisma.subscription.findMany({
        where: { status: 'pending' },
        orderBy: { createdAt: 'desc' },
        include: { shopkeeper: { select: { name: true, phone: true } }, plan: { select: { displayName: true, monthlyPrice: true } } },
      }),
      prisma.subscription.findMany({ where: { status: 'active' } }),
    ]);

    const mrr = activeSubscriptions.reduce((sum, sub) => sum + Number(sub.planSnapshot?.monthlyPrice || 0), 0);

    res.json({
      success: true,
      data: {
        statusCounts,
        expiringSoon: { count: expiringSoon.length, subscriptions: expiringSoon },
        recentlyExpired: { count: recentlyExpired.length, subscriptions: recentlyExpired },
        pending: { count: pending.length, subscriptions: pending },
        mrr,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getRevenueIntelligence(req, res, next) {
  try {
    const now = new Date();
    const sixMonthsAgo = new Date(now);
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const threeMonthsAgo = new Date(now);
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const activeSubscriptions = await prisma.subscription.findMany({ where: { status: 'active' } });
    const currentMRR = activeSubscriptions.reduce((sum, s) => sum + Number(s.planSnapshot?.monthlyPrice || 0), 0);

    const growthSubs = await prisma.subscription.findMany({
      where: { createdAt: { gte: sixMonthsAgo } },
      select: { createdAt: true, actualPrice: true },
    });
    const growthMap = {};
    growthSubs.forEach((s) => {
      const d = new Date(s.createdAt);
      const k = `${d.getUTCFullYear()}-${d.getUTCMonth() + 1}`;
      if (!growthMap[k]) growthMap[k] = { newSubscriptions: 0, revenue: 0, _id: { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1 } };
      growthMap[k].newSubscriptions += 1;
      growthMap[k].revenue += Number(s.actualPrice || 0);
    });
    const growthTrend = Object.values(growthMap).sort((a, b) => (a._id.year - b._id.year) || (a._id.month - b._id.month));

    const churnSubs = await prisma.subscription.findMany({
      where: { status: { in: ['expired', 'cancelled'] }, updatedAt: { gte: threeMonthsAgo } },
      select: { status: true, updatedAt: true },
    });
    const churnMap = {};
    churnSubs.forEach((s) => {
      const d = new Date(s.updatedAt);
      const k = `${d.getUTCFullYear()}-${d.getUTCMonth() + 1}-${s.status}`;
      if (!churnMap[k]) churnMap[k] = { _id: { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, status: s.status }, count: 0 };
      churnMap[k].count += 1;
    });
    const churnData = Object.values(churnMap).sort((a, b) => (a._id.year - b._id.year) || (a._id.month - b._id.month));

    const nextMonthStart = new Date(now);
    nextMonthStart.setMonth(nextMonthStart.getMonth() + 1);
    nextMonthStart.setDate(1);
    const nextMonthEnd = new Date(nextMonthStart);
    nextMonthEnd.setMonth(nextMonthEnd.getMonth() + 1);

    const expiringNextMonth = await prisma.subscription.count({
      where: { status: 'active', endDate: { gte: nextMonthStart, lt: nextMonthEnd }, autoRenew: false },
    });
    const projectedMRR =
      currentMRR - expiringNextMonth * (currentMRR / (activeSubscriptions.length || 1));

    const lastMonthSubs = growthTrend[growthTrend.length - 1]?.newSubscriptions || 0;
    const prevMonthSubs = growthTrend[growthTrend.length - 2]?.newSubscriptions || 0;
    const dropPercentage = prevMonthSubs > 0 ? ((prevMonthSubs - lastMonthSubs) / prevMonthSubs) * 100 : 0;
    const unusualDrop = dropPercentage > 20;

    const planDistributionMap = {};
    activeSubscriptions.forEach((s) => {
      const name = s.planSnapshot?.displayName || s.planSnapshot?.name || 'Unknown';
      if (!planDistributionMap[name]) planDistributionMap[name] = { _id: name, count: 0, revenue: 0 };
      planDistributionMap[name].count += 1;
      planDistributionMap[name].revenue += Number(s.planSnapshot?.monthlyPrice || 0);
    });
    const planDistribution = Object.values(planDistributionMap).sort((a, b) => b.count - a.count);

    res.json({
      success: true,
      data: {
        currentMRR,
        activeSubscriptions: activeSubscriptions.length,
        projectedMRR: Math.max(0, projectedMRR),
        growthTrend,
        churnData,
        planDistribution,
        alerts: {
          unusualDrop,
          dropPercentage: unusualDrop ? dropPercentage.toFixed(2) : 0,
          expiringNextMonth,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getAllSubscriptions(req, res, next) {
  try {
    const { status, planId, shopkeeperId, expiringSoon, page = 1, limit = 20 } = req.query;
    const where = {};
    if (status) where.status = status;
    if (planId) where.planId = planId;
    if (shopkeeperId) where.shopkeeperId = (await resolvePgId('users', shopkeeperId)) || shopkeeperId;
    if (expiringSoon === 'true') {
      const now = new Date();
      const sevenDaysFromNow = new Date(now);
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
      where.status = 'active';
      where.endDate = { gte: now, lte: sevenDaysFromNow };
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const [subscriptions, total] = await Promise.all([
      prisma.subscription.findMany({
        where,
        include: { shopkeeper: { select: { name: true, phone: true } }, plan: { select: { displayName: true, monthlyPrice: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.subscription.count({ where }),
    ]);
    res.json({
      success: true,
      data: {
        subscriptions,
        pagination: { total, page: parseInt(page, 10), limit: parseInt(limit, 10), pages: Math.ceil(total / parseInt(limit, 10)) },
      },
    });
  } catch (err) {
    next(err);
  }
}

async function updateSubscription(req, res, next) {
  try {
    const { subscriptionId } = req.params;
    const { status, endDate, autoRenew, notes } = req.body;
    const existing = await prisma.subscription.findUnique({ where: { id: subscriptionId } });
    if (!existing) return res.status(404).json({ success: false, message: 'Subscription not found' });
    const updated = await subscriptionRepository.updateSubscription(subscriptionId, {
      ...(status !== undefined ? { status } : {}),
      ...(endDate !== undefined ? { endDate: new Date(endDate) } : {}),
      ...(autoRenew !== undefined ? { autoRenew } : {}),
      ...(notes !== undefined ? { notes } : {}),
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_updated', existing.shopkeeperId, 'shopkeeper', { subscriptionId: existing.id, changes: { status, endDate, autoRenew } }, req.ip);
    res.json({ success: true, message: 'Subscription updated successfully', data: updated });
  } catch (err) {
    next(err);
  }
}

async function cancelSubscription(req, res, next) {
  try {
    const { subscriptionId } = req.params;
    const { reason } = req.body;
    const existing = await prisma.subscription.findUnique({ where: { id: subscriptionId } });
    if (!existing) return res.status(404).json({ success: false, message: 'Subscription not found' });
    const updated = await subscriptionRepository.updateSubscription(subscriptionId, {
      status: 'cancelled',
      cancelledAt: new Date(),
      cancelledBy: req.user.userId,
      cancellationReason: reason || '',
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_cancelled', existing.shopkeeperId, 'shopkeeper', { subscriptionId: existing.id, reason }, req.ip);
    res.json({ success: true, message: 'Subscription cancelled successfully', data: updated });
  } catch (err) {
    next(err);
  }
}

async function renewSubscription(req, res, next) {
  try {
    const { subscriptionId } = req.params;
    const { durationMonths = 1, paymentMethod, transactionId } = req.body;
    const existing = await prisma.subscription.findUnique({ where: { id: subscriptionId } });
    if (!existing) return res.status(404).json({ success: false, message: 'Subscription not found' });
    const newCycleStart = new Date(existing.endDate || new Date());
    const newEndDate = new Date(newCycleStart);
    newEndDate.setMonth(newEndDate.getMonth() + durationMonths);
    const updated = await subscriptionRepository.updateSubscription(subscriptionId, {
      status: 'active',
      startDate: newCycleStart,
      endDate: newEndDate,
      renewalCount: (existing.renewalCount || 0) + 1,
      lastRenewalDate: new Date(),
      paymentStatus: 'paid',
      paymentMethod,
      transactionId,
    });
    await upsertWalletForSubscription(updated);
    await logAdminAction(req.user.userId, req.user.role, 'subscription_renewed', existing.shopkeeperId, 'shopkeeper', { subscriptionId: existing.id, duration: durationMonths, newEndDate }, req.ip);
    res.json({ success: true, message: 'Subscription renewed successfully', data: updated });
  } catch (err) {
    next(err);
  }
}

async function runExpiryCheck(req, res, next) {
  try {
    const result = await subscriptionRepository.expireOldSubscriptions();
    res.json({ success: true, message: 'Expiry check completed', data: { modifiedCount: result.modifiedCount } });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createSubscription,
  getMonitoringDashboard,
  getRevenueIntelligence,
  getAllSubscriptions,
  updateSubscription,
  cancelSubscription,
  renewSubscription,
  runExpiryCheck,
};
