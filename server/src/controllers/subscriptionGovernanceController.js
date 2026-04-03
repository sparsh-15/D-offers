const { prisma } = require('../db/prisma');
const { logAdminAction } = require('../middleware/roleAuth');
const subscriptionRepository = require('../repositories/subscriptionRepository');
const { resolvePgId } = require('../repositories/idResolver');
const { buildPlanSnapshot, upsertWalletForSubscription } = require('../services/aiWalletService');
const { resolveCityStateFromPincode } = require('../services/pincodeService');

function toSafeInt(value, fallback, min, max) {
  const parsed = Number.parseInt(value, 10);
  const finalValue = Number.isFinite(parsed) ? parsed : fallback;
  return Math.min(max, Math.max(min, finalValue));
}

function buildGeoSummary(rows) {
  const cityDistribution = {};
  const pincodeDistribution = {};
  rows.forEach((row) => {
    const city = String(row.city || row.shopProfile?.city || '').trim();
    const pincode = String(row.pincode || row.shopProfile?.pincode || '').trim();
    if (city) cityDistribution[city] = (cityDistribution[city] || 0) + 1;
    if (pincode) pincodeDistribution[pincode] = (pincodeDistribution[pincode] || 0) + 1;
  });

  return {
    city: Object.keys(cityDistribution)[0] || null,
    pincode: Object.keys(pincodeDistribution)[0] || null,
    cityDistribution,
    pincodeDistribution,
  };
}

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

/**
 * Subscription metrics with simple filters.
 * Example: how many Gold subscriptions in this city / category.
 *
 * Query params:
 * - status: subscription status (default: active)
 * - city: shopkeeper user city (optional, case-insensitive)
 * - pincode: shopkeeper pincode (optional) – will also resolve city/state
 * - category: plan category (optional)
 */
async function getSubscriptionMetrics(req, res, next) {
  try {
    const { status = 'active', city, pincode, category } = req.query;

    const where = {};

    if (status && status !== 'all') {
      where.status = status;
    }

    // Filter by shopkeeper location (user table)
    if (city && String(city).trim()) {
      where.shopkeeper = {
        ...(where.shopkeeper || {}),
        city: { equals: String(city).trim(), mode: 'insensitive' },
      };
    }

    let resolvedLocation = null;
    if (pincode && String(pincode).trim()) {
      const normalizedPincode = String(pincode).trim();
      // Always filter by exact pincode
      where.shopkeeper = {
        ...(where.shopkeeper || {}),
        pincode: normalizedPincode,
      };

      // Additionally resolve city/state for display (does not change filter)
      try {
        const resolved = await resolveCityStateFromPincode(normalizedPincode);
        resolvedLocation = {
          pincode: resolved.pincode,
          state: resolved.state,
          district: resolved.district,
          areas: resolved.areas,
        };
      } catch (e) {
        // If resolution fails, continue with pincode-only filter
        resolvedLocation = {
          pincode: normalizedPincode,
        };
      }
    }

    // Filter by plan category
    if (category && String(category).trim()) {
      where.plan = {
        ...(where.plan || {}),
        category: String(category).trim(),
      };
    }

    // Pull subscriptions with related plan + shopkeeper city, then aggregate in JS.
    const subscriptions = await prisma.subscription.findMany({
      where,
      select: {
        id: true,
        plan: {
          select: {
            tier: true,
          },
        },
      },
    });

    const totals = {
      total: 0,
      byTier: {
        silver: 0,
        gold: 0,
        platinum: 0,
        other: 0,
      },
    };

    subscriptions.forEach((sub) => {
      totals.total += 1;
      const tier = (sub.plan?.tier || '').toLowerCase();
      if (tier === 'silver') totals.byTier.silver += 1;
      else if (tier === 'gold') totals.byTier.gold += 1;
      else if (tier === 'platinum') totals.byTier.platinum += 1;
      else totals.byTier.other += 1;
    });

    res.json({
      success: true,
      data: {
        totals,
        filters: {
          status,
          city: city || null,
          pincode: pincode || null,
          category: category || null,
          resolvedLocation,
        },
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
    const { status, planId, shopkeeperId, expiringSoon, city, pincode, page = 1, limit = 20 } = req.query;
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
    // Filter by shopkeeper city (case-insensitive) and/or pincode
    if (city && String(city).trim()) {
      where.shopkeeper = {
        ...(where.shopkeeper || {}),
        city: { equals: String(city).trim(), mode: 'insensitive' },
      };
    }
    if (pincode && String(pincode).trim()) {
      where.shopkeeper = {
        ...(where.shopkeeper || {}),
        pincode: String(pincode).trim(),
      };
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

async function bulkCreateUsers(req, res, next) {
  try {
    const inputUsers = req.body?.users && typeof req.body.users === 'object' ? req.body.users : {};
    const allUsers = {
      shopkeeper: Array.isArray(inputUsers.shopkeeper) ? inputUsers.shopkeeper : [],
      customer: Array.isArray(inputUsers.customer) ? inputUsers.customer : [],
    };

    if (allUsers.shopkeeper.length === 0 && allUsers.customer.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Provide users.shopkeeper and/or users.customer arrays',
      });
    }

    const summary = {
      roles: {
        shopkeeper: { requested: allUsers.shopkeeper.length, created: 0, skipped: 0, failed: 0 },
        customer: { requested: allUsers.customer.length, created: 0, skipped: 0, failed: 0 },
      },
      geoSummary: buildGeoSummary([...allUsers.shopkeeper, ...allUsers.customer]),
      createdSample: [],
      errors: [],
    };

    for (const role of ['shopkeeper', 'customer']) {
      for (const row of allUsers[role]) {
        try {
          const phone = String(row.phone || '').trim();
          if (!phone) {
            summary.roles[role].failed += 1;
            summary.errors.push({ role, phone: null, message: 'phone is required' });
            continue;
          }

          const existing = await prisma.user.findUnique({ where: { phone } });
          if (existing) {
            summary.roles[role].skipped += 1;
            continue;
          }

          const created = await prisma.user.create({
            data: {
              name: String(row.name || `${role}_${phone.slice(-4)}`).trim(),
              email: row.email ? String(row.email).trim() : null,
              phone,
              password: row.password ? String(row.password) : null,
              role,
              pincode: row.pincode ? String(row.pincode).trim() : '',
              city: row.city ? String(row.city).trim() : '',
              state: row.state ? String(row.state).trim() : '',
              region: row.region ? String(row.region).trim() : '',
              territory: row.territory ? String(row.territory).trim() : '',
              address: row.address ? String(row.address).trim() : '',
              gender: row.gender ? String(row.gender).trim() : null,
              dob: row.dob ? new Date(row.dob) : null,
              occupation: row.occupation ? String(row.occupation).trim() : null,
              aboutMe: row.aboutMe ? String(row.aboutMe).trim() : null,
              workingHours: row.workingHours ? String(row.workingHours).trim() : null,
              shopRegistrationNumber: row.shopRegistrationNumber ? String(row.shopRegistrationNumber).trim() : null,
              gstNumber: row.gstNumber ? String(row.gstNumber).trim() : null,
              electricityConsumerNumber: row.electricityConsumerNumber ? String(row.electricityConsumerNumber).trim() : null,
              aadhaarNumber: row.aadhaarNumber ? String(row.aadhaarNumber).trim() : null,
              panNumber: row.panNumber ? String(row.panNumber).trim() : null,
              shopRegistrationDocumentUrl: row.shopRegistrationDocumentUrl ? String(row.shopRegistrationDocumentUrl).trim() : null,
              gstDocumentUrl: row.gstDocumentUrl ? String(row.gstDocumentUrl).trim() : null,
              electricityBillDocumentUrl: row.electricityBillDocumentUrl ? String(row.electricityBillDocumentUrl).trim() : null,
              aadhaarDocumentUrl: row.aadhaarDocumentUrl ? String(row.aadhaarDocumentUrl).trim() : null,
              panDocumentUrl: row.panDocumentUrl ? String(row.panDocumentUrl).trim() : null,
              maxCouponDiscountPercent: row.maxCouponDiscountPercent !== undefined
                ? toSafeInt(row.maxCouponDiscountPercent, 50, 1, 99)
                : 50,
              approvalStatus: row.approvalStatus || 'approved',
              permissions: Array.isArray(row.permissions) ? row.permissions : [],
              isActive: row.isActive !== false,
            },
          });

          if (role === 'shopkeeper') {
            const profile = row.shopProfile || {};
            await prisma.shopkeeperProfile.upsert({
              where: { userId: created.id },
              update: {
                shopName: profile.shopName || `${created.name} Shop`,
                category: profile.category || 'all',
                city: profile.city || created.city || null,
                pincode: profile.pincode || created.pincode || null,
                address: profile.address || created.address || null,
              },
              create: {
                userId: created.id,
                shopName: profile.shopName || `${created.name} Shop`,
                category: profile.category || 'all',
                city: profile.city || created.city || null,
                pincode: profile.pincode || created.pincode || null,
                address: profile.address || created.address || null,
              },
            });
          }

          summary.roles[role].created += 1;
          if (summary.createdSample.length < 10) {
            summary.createdSample.push({ id: created.id, role: created.role, phone: created.phone, city: created.city, pincode: created.pincode });
          }
        } catch (err) {
          summary.roles[role].failed += 1;
          summary.errors.push({ role, phone: row?.phone || null, message: err.message });
        }
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Bulk users processed (shopkeeper + customer)',
      bodyFormat: {
        users: {
          shopkeeper: '[{ name, phone, email?, password?, city?, state?, region?, territory?, pincode?, address?, gender?, dob?, occupation?, aboutMe?, workingHours?, shopRegistrationNumber?, gstNumber?, electricityConsumerNumber?, aadhaarNumber?, panNumber?, shopRegistrationDocumentUrl?, gstDocumentUrl?, electricityBillDocumentUrl?, aadhaarDocumentUrl?, panDocumentUrl?, maxCouponDiscountPercent?, approvalStatus?, permissions?, isActive?, shopProfile? }]',
          customer: '[{ name, phone, email?, password?, city?, state?, pincode?, address?, gender?, dob?, occupation?, aboutMe?, approvalStatus?, permissions?, isActive? }]'
        }
      },
      data: summary,
    });
  } catch (err) {
    next(err);
  }
}

async function bulkSubscribeUsersToPlans(req, res, next) {
  try {
    const rows = Array.isArray(req.body?.subscriptions) ? req.body.subscriptions : [];
    if (rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'subscriptions array is required and cannot be empty',
      });
    }

    const summary = {
      requested: rows.length,
      created: 0,
      skipped: 0,
      failed: 0,
      items: [],
      errors: [],
    };

    for (const row of rows) {
      try {
        const phone = row.shopkeeperPhone ? String(row.shopkeeperPhone).trim() : null;
        const shopkeeperIdRaw = row.shopkeeperId ? String(row.shopkeeperId).trim() : null;

        if (!phone && !shopkeeperIdRaw) {
          throw new Error('shopkeeperId or shopkeeperPhone is required');
        }

        let shopkeeper = null;
        if (shopkeeperIdRaw) {
          const pgShopkeeperId = await resolvePgId('users', shopkeeperIdRaw) || shopkeeperIdRaw;
          shopkeeper = await prisma.user.findUnique({ where: { id: pgShopkeeperId } });
        } else {
          shopkeeper = await prisma.user.findUnique({ where: { phone } });
        }

        if (!shopkeeper || shopkeeper.role !== 'shopkeeper') {
          throw new Error('Shopkeeper not found');
        }

        let plan = null;
        if (row.planId) {
          plan = await prisma.subscriptionPlan.findUnique({ where: { id: String(row.planId) } });
        }
        if (!plan && row.planName) {
          plan = await prisma.subscriptionPlan.findFirst({
            where: { name: { equals: String(row.planName).trim(), mode: 'insensitive' } },
          });
        }
        if (!plan && row.planTier) {
          plan = await prisma.subscriptionPlan.findFirst({
            where: { tier: { equals: String(row.planTier).trim().toLowerCase(), mode: 'insensitive' }, isActive: true },
            orderBy: { sortOrder: 'asc' },
          });
        }

        if (!plan) throw new Error('Plan not found');
        if (!plan.isActive) throw new Error('Plan is inactive');

        const existingActive = await prisma.subscription.findFirst({
          where: { shopkeeperId: shopkeeper.id, status: 'active' },
          orderBy: { createdAt: 'desc' },
        });

        if (existingActive && row.forceNew !== true) {
          summary.skipped += 1;
          summary.items.push({
            shopkeeperId: shopkeeper.id,
            shopkeeperPhone: shopkeeper.phone,
            planId: plan.id,
            planName: plan.name,
            subscriptionId: existingActive.id,
            status: 'skipped',
            reason: 'already_has_active_subscription',
          });
          continue;
        }

        const durationMonths = toSafeInt(row.durationMonths, 1, 1, 24);
        const start = row.startDate ? new Date(row.startDate) : new Date();
        const end = new Date(start);
        end.setMonth(end.getMonth() + durationMonths);

        const subscription = await subscriptionRepository.createSubscription({
          shopkeeperId: shopkeeper.id,
          planId: plan.id,
          planSnapshot: buildPlanSnapshot(plan),
          status: 'active',
          startDate: start,
          endDate: end,
          actualPrice: Number(plan.monthlyPrice) * Number(durationMonths),
          autoRenew: row.autoRenew === true,
          paymentStatus: 'paid',
          paymentMethod: row.paymentMethod || 'upi',
          transactionId: row.transactionId || null,
          notes: row.notes || 'Bulk subscription API',
        });

        await upsertWalletForSubscription(subscription);

        summary.created += 1;
        summary.items.push({
          shopkeeperId: shopkeeper.id,
          shopkeeperPhone: shopkeeper.phone,
          planId: plan.id,
          planName: plan.name,
          subscriptionId: subscription.id,
          status: 'created',
        });
      } catch (err) {
        summary.failed += 1;
        summary.errors.push({
          shopkeeperId: row?.shopkeeperId || null,
          shopkeeperPhone: row?.shopkeeperPhone || null,
          planId: row?.planId || null,
          planName: row?.planName || null,
          message: err.message,
        });
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Bulk subscriptions processed',
      bodyFormat: {
        subscriptions: '[{ shopkeeperId? | shopkeeperPhone?, planId? | planName? | planTier?, durationMonths?, startDate?, autoRenew?, paymentMethod?, transactionId?, notes?, forceNew? }]'
      },
      data: summary,
    });
  } catch (err) {
    next(err);
  }
}

async function bulkCreateAiPacks(req, res, next) {
  try {
    const packs = Array.isArray(req.body?.packs) ? req.body.packs : [];
    if (packs.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'packs array is required and cannot be empty',
      });
    }

    const summary = {
      requested: packs.length,
      created: 0,
      updated: 0,
      failed: 0,
      items: [],
      errors: [],
    };

    for (const row of packs) {
      try {
        const sku = String(row.sku || '').trim().toLowerCase();
        const displayName = String(row.displayName || '').trim();
        if (!sku || !displayName) {
          throw new Error('sku and displayName are required');
        }

        const payload = {
          sku,
          displayName,
          category: row.category ? String(row.category).trim() : 'all',
          credits: toSafeInt(row.credits, 1, 1, 100000),
          priceSilver: Number(row.priceSilver),
          priceGold: Number(row.priceGold),
          pricePlatinum: Number(row.pricePlatinum),
          sortOrder: toSafeInt(row.sortOrder, 0, 0, 100000),
          isActive: row.isActive !== false,
        };

        if (![payload.priceSilver, payload.priceGold, payload.pricePlatinum].every((v) => Number.isFinite(v))) {
          throw new Error('priceSilver, priceGold and pricePlatinum must be valid numbers');
        }

        const existing = await prisma.aiCreditPack.findUnique({ where: { sku } });
        if (existing) {
          const updated = await prisma.aiCreditPack.update({
            where: { id: existing.id },
            data: payload,
          });
          summary.updated += 1;
          summary.items.push({ sku: updated.sku, id: updated.id, status: 'updated' });
        } else {
          const created = await prisma.aiCreditPack.create({ data: payload });
          summary.created += 1;
          summary.items.push({ sku: created.sku, id: created.id, status: 'created' });
        }
      } catch (err) {
        summary.failed += 1;
        summary.errors.push({ sku: row?.sku || null, message: err.message });
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Bulk AI packs processed',
      bodyFormat: {
        packs: '[{ sku, displayName, category?, credits, priceSilver, priceGold, pricePlatinum, sortOrder?, isActive? }]'
      },
      data: summary,
    });
  } catch (err) {
    next(err);
  }
}

async function bulkCreateOffers(req, res, next) {
  try {
    const rows = Array.isArray(req.body?.offers) ? req.body.offers : [];
    if (rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'offers array is required and cannot be empty',
      });
    }

    const summary = {
      requested: rows.length,
      created: 0,
      skipped: 0,
      failed: 0,
      items: [],
      errors: [],
    };

    for (const row of rows) {
      try {
        const phone = row.shopkeeperPhone ? String(row.shopkeeperPhone).trim() : null;
        const shopkeeperIdRaw = row.shopkeeperId ? String(row.shopkeeperId).trim() : null;
        if (!phone && !shopkeeperIdRaw) {
          throw new Error('shopkeeperId or shopkeeperPhone is required');
        }

        let shopkeeper = null;
        if (shopkeeperIdRaw) {
          const pgShopkeeperId = await resolvePgId('users', shopkeeperIdRaw) || shopkeeperIdRaw;
          shopkeeper = await prisma.user.findUnique({ where: { id: pgShopkeeperId } });
        } else {
          shopkeeper = await prisma.user.findUnique({ where: { phone } });
        }

        if (!shopkeeper || shopkeeper.role !== 'shopkeeper') {
          throw new Error('Shopkeeper not found');
        }

        const title = String(row.title || '').trim();
        if (!title) throw new Error('title is required');

        const discountType = row.discountType === 'fixed' ? 'fixed' : 'percentage';
        const discountValue = Number(row.discountValue);
        if (!Number.isFinite(discountValue) || discountValue <= 0) {
          throw new Error('discountValue must be a positive number');
        }

        const validFrom = row.validFrom ? new Date(row.validFrom) : new Date();
        const validTo = row.validTo
          ? new Date(row.validTo)
          : new Date(Date.now() + 15 * 24 * 60 * 60 * 1000);

        const profile = await prisma.shopkeeperProfile.findUnique({ where: { userId: shopkeeper.id } });
        const existing = await prisma.offer.findFirst({
          where: {
            shopkeeperId: shopkeeper.id,
            title,
            status: 'active',
          },
        });

        if (existing && row.forceNew !== true) {
          summary.skipped += 1;
          summary.items.push({
            shopkeeperId: shopkeeper.id,
            shopkeeperPhone: shopkeeper.phone,
            offerId: existing.id,
            title: existing.title,
            status: 'skipped',
            reason: 'active_offer_with_same_title_exists',
          });
          continue;
        }

        const offer = await prisma.offer.create({
          data: {
            shopkeeperId: shopkeeper.id,
            title,
            description: row.description ? String(row.description).trim() : null,
            photos: Array.isArray(row.photos) ? row.photos.map((p) => String(p).trim()).filter(Boolean) : [],
            termsAndConditions: row.termsAndConditions ? String(row.termsAndConditions).trim() : null,
            category: profile?.category?.trim() || 'all',
            discountType,
            discountValue,
            validFrom,
            validTo,
            status: row.status || 'active',
          },
        });

        summary.created += 1;
        summary.items.push({
          shopkeeperId: shopkeeper.id,
          shopkeeperPhone: shopkeeper.phone,
          offerId: offer.id,
          title: offer.title,
          status: 'created',
        });
      } catch (err) {
        summary.failed += 1;
        summary.errors.push({
          shopkeeperId: row?.shopkeeperId || null,
          shopkeeperPhone: row?.shopkeeperPhone || null,
          title: row?.title || null,
          message: err.message,
        });
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Bulk offers processed',
      bodyFormat: {
        offers: '[{ shopkeeperId? | shopkeeperPhone?, title, description?, discountType?(percentage|fixed), discountValue, photos?, termsAndConditions?, validFrom?, validTo?, status?, forceNew? }]'
      },
      data: summary,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createSubscription,
  getMonitoringDashboard,
  getRevenueIntelligence,
  getSubscriptionMetrics,
  getAllSubscriptions,
  updateSubscription,
  cancelSubscription,
  renewSubscription,
  runExpiryCheck,
  bulkCreateUsers,
  bulkSubscribeUsersToPlans,
  bulkCreateOffers,
  bulkCreateAiPacks,
};
