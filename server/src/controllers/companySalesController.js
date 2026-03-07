const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { ensureCouponsForAgent } = require('./agentGovernanceController');
const {
  LeadConflictError,
  createOrLinkLead,
  retryLeadInvite,
  mapLead,
} = require('../services/leadOnboardingService');

function ci(value) {
  return String(value || '').trim();
}

function getMonthBounds(reference = new Date()) {
  const start = new Date(reference);
  start.setDate(1);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setMonth(end.getMonth() + 1);
  return { start, end };
}

async function getStats(req, res, next) {
  try {
    const pgAgentId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const { start: monthStart, end: monthEnd } = getMonthBounds();

    const [shopProfiles, inviteSentCount, inviteFailedCount, leadLoggedInCount] = await Promise.all([
      prisma.shopkeeperProfile.findMany({
      where: { onboardedBy: pgAgentId },
      select: { userId: true, createdAt: true },
      }),
      prisma.shopLead.count({
        where: { csaId: pgAgentId, inviteStatus: 'sent' },
      }),
      prisma.shopLead.count({
        where: { csaId: pgAgentId, inviteStatus: 'failed' },
      }),
      prisma.shopLead.count({
        where: { csaId: pgAgentId, claimedAt: { not: null } },
      }),
    ]);

    const totalOnboardings = shopProfiles.length;
    const monthOnboardings = shopProfiles.filter(
      (p) => p.createdAt >= monthStart && p.createdAt < monthEnd,
    ).length;

    const shopkeeperIds = [
      ...new Set(shopProfiles.map((p) => p.userId).filter(Boolean)),
    ];

    let subscriptions = [];
    if (shopkeeperIds.length) {
      subscriptions = await prisma.subscription.findMany({
        where: { shopkeeperId: { in: shopkeeperIds } },
        select: {
          shopkeeperId: true,
          status: true,
          actualPrice: true,
          discountAmount: true,
          startDate: true,
          endDate: true,
        },
        orderBy: { createdAt: 'desc' },
      });
    }

    const latestByShop = {};
    subscriptions.forEach((sub) => {
      if (!latestByShop[sub.shopkeeperId]) {
        latestByShop[sub.shopkeeperId] = sub;
      }
    });

    let activeShops = 0;
    let churnedShops = 0;
    Object.values(latestByShop).forEach((sub) => {
      if (sub.status === 'active') activeShops += 1;
      if (sub.status === 'expired' || sub.status === 'cancelled')
        churnedShops += 1;
    });

    let totalRevenue = 0;
    let monthRevenue = 0;
    let totalDiscount = 0;
    let monthDiscount = 0;

    subscriptions.forEach((sub) => {
      const revenue = Number(sub.actualPrice || 0);
      const discount = Number(sub.discountAmount || 0);
      totalRevenue += revenue;
      totalDiscount += discount;
      if (sub.startDate && sub.startDate >= monthStart && sub.startDate < monthEnd) {
        monthRevenue += revenue;
        monthDiscount += discount;
      }
    });

    // Simple base commission estimate (e.g. 5% of this month's revenue)
    const estimatedCommission = monthRevenue * 0.05;

    res.json({
      success: true,
      stats: {
        onboardings: {
          total: totalOnboardings,
          thisMonth: monthOnboardings,
        },
        shops: {
          total: shopkeeperIds.length,
          active: activeShops,
          churned: churnedShops,
        },
        revenue: {
          total: totalRevenue,
          thisMonth: monthRevenue,
          totalDiscount,
          monthDiscount,
        },
        incentives: {
          estimated: estimatedCommission,
        },
        leads: {
          inviteSent: inviteSentCount,
          inviteFailed: inviteFailedCount,
          loggedIn: leadLoggedInCount,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getShops(req, res, next) {
  try {
    const pgAgentId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const { status, page = 1, limit = 20 } = req.query;

    const shopProfiles = await prisma.shopkeeperProfile.findMany({
      where: { onboardedBy: pgAgentId },
      select: { userId: true },
    });

    const shopkeeperIds = [
      ...new Set(shopProfiles.map((p) => p.userId).filter(Boolean)),
    ];

    if (!shopkeeperIds.length) {
      return res.json({
        success: true,
        data: {
          shops: [],
          summary: { total: 0, active: 0, expired: 0, none: 0 },
          pagination: { total: 0, page: 1, limit: Number(limit), pages: 0 },
        },
      });
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

    const [shopUsers, subscriptions] = await Promise.all([
      prisma.user.findMany({
        where: { id: { in: shopkeeperIds } },
        select: {
          id: true,
          name: true,
          phone: true,
          city: true,
          state: true,
          isActive: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit, 10),
      }),
      prisma.subscription.findMany({
        where: { shopkeeperId: { in: shopkeeperIds } },
        include: {
          plan: { select: { displayName: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const latestSubByShop = {};
    subscriptions.forEach((sub) => {
      if (!latestSubByShop[sub.shopkeeperId]) {
        latestSubByShop[sub.shopkeeperId] = sub;
      }
    });

    const items = [];
    let summaryActive = 0;
    let summaryExpired = 0;
    let summaryNone = 0;

    shopUsers.forEach((shop) => {
      const latest = latestSubByShop[shop.id] || null;
      let subscriptionStatus = 'none';
      if (latest) {
        if (latest.status === 'active') subscriptionStatus = 'active';
        else if (latest.status === 'expired' || latest.status === 'cancelled')
          subscriptionStatus = 'expired';
        else subscriptionStatus = latest.status || 'none';
      }

      if (!status || status === subscriptionStatus) {
        items.push({
          shopId: shop.id,
          name: shop.name,
          phone: shop.phone,
          city: shop.city,
          state: shop.state,
          isActive: shop.isActive,
          subscription: latest
            ? {
                status: subscriptionStatus,
                planName: latest.plan?.displayName || null,
                startDate: latest.startDate,
                endDate: latest.endDate,
              }
            : null,
        });
      }

      if (subscriptionStatus === 'active') summaryActive += 1;
      else if (subscriptionStatus === 'expired') summaryExpired += 1;
      else summaryNone += 1;
    });

    res.json({
      success: true,
      data: {
        shops: items,
        summary: {
          total: shopkeeperIds.length,
          active: summaryActive,
          expired: summaryExpired,
          none: summaryNone,
        },
        pagination: {
          total: shopkeeperIds.length,
          page: parseInt(page, 10),
          limit: parseInt(limit, 10),
          pages: Math.ceil(shopkeeperIds.length / parseInt(limit, 10)),
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getCoupons(req, res, next) {
  try {
    const pgAgentId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const agent = await prisma.user.findUnique({
      where: { id: pgAgentId, role: 'company_sales_agent' },
    });
    if (!agent) {
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }
    await ensureCouponsForAgent(agent);

    const now = new Date();
    const coupons = await prisma.coupon.findMany({
      where: {
        agentId: pgAgentId,
        isActive: true,
        OR: [{ expiryDate: null }, { expiryDate: { gt: now } }],
      },
      orderBy: { discountValue: 'asc' },
    });

    res.status(200).json({
      success: true,
      coupons: coupons.map((c) => ({
        id: c.id,
        code: c.code,
        discountType: c.discountType,
        discountValue: c.discountValue,
        description: c.description || '',
        expiryDate: c.expiryDate ? c.expiryDate.toISOString() : null,
        maxUses: c.maxUses,
        currentUses: c.currentUses,
        isActive: c.isActive,
        createdAt: c.createdAt.toISOString(),
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function getReports(req, res, next) {
  try {
    const pgAgentId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const { month } = req.query;

    const reference = month ? new Date(`${month}-01T00:00:00Z`) : new Date();
    const { start: monthStart, end: monthEnd } = getMonthBounds(reference);

    const shopProfiles = await prisma.shopkeeperProfile.findMany({
      where: { onboardedBy: pgAgentId },
      select: { userId: true },
    });
    const shopkeeperIds = [
      ...new Set(shopProfiles.map((p) => p.userId).filter(Boolean)),
    ];

    let onboardings = [];
    let subs = [];

    if (shopkeeperIds.length) {
      onboardings = await prisma.shopkeeperProfile.findMany({
        where: {
          onboardedBy: pgAgentId,
          createdAt: { gte: monthStart, lt: monthEnd },
        },
        select: { createdAt: true },
      });

      subs = await prisma.subscription.findMany({
        where: {
          shopkeeperId: { in: shopkeeperIds },
          createdAt: { gte: monthStart, lt: monthEnd },
        },
        select: {
          status: true,
          actualPrice: true,
        },
      });
    }

    const timelineMap = {};
    onboardings.forEach((o) => {
      const d = new Date(o.createdAt);
      const key = d.toISOString().slice(0, 10);
      timelineMap[key] = (timelineMap[key] || 0) + 1;
    });

    const onboardingTimeline = Object.entries(timelineMap)
      .sort(([a], [b]) => (a < b ? -1 : 1))
      .map(([date, count]) => ({ date, count }));

    let activeCount = 0;
    let churnedCount = 0;
    let earned = 0;

    subs.forEach((s) => {
      if (s.status === 'active') activeCount += 1;
      if (s.status === 'expired' || s.status === 'cancelled')
        churnedCount += 1;
      earned += Number(s.actualPrice || 0);
    });

    res.json({
      success: true,
      data: {
        month:
          month ||
          `${monthStart.getFullYear()}-${String(
            monthStart.getMonth() + 1,
          ).padStart(2, '0')}`,
        onboardingTimeline,
        shopStatus: {
          active: activeCount,
          churned: churnedCount,
        },
        commissions: {
          earned,
          // detailed paid/pending breakdown can be added when payment tracking is available
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

async function createLead(req, res, next) {
  try {
    const pgCsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const {
      shopName,
      ownerName,
      phone,
      pincode,
      city,
      category,
      notes,
      couponCode,
    } = req.body || {};

    const lead = await createOrLinkLead({
      agentId: pgCsaId,
      agentRole: 'company_sales_agent',
      shopName,
      ownerName,
      phone,
      pincode,
      city,
      category,
      notes,
      couponCode,
      ipAddress: req.ip || req.connection?.remoteAddress || null,
    });

    res.status(201).json({
      success: true,
      lead,
    });
  } catch (err) {
    if (err instanceof LeadConflictError) {
      return res.status(err.statusCode || 409).json({
        success: false,
        errorCode: err.code,
        message: err.message,
        owner: err.details?.owner || null,
      });
    }
    next(err);
  }
}

async function getLeads(req, res, next) {
  try {
    const pgCsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const { status, search } = req.query || {};

    const where = { csaId: pgCsaId };
    if (status && ci(status)) {
      where.status = ci(status).toLowerCase();
    }
    if (search && ci(search)) {
      where.OR = [
        { shopName: { contains: ci(search), mode: 'insensitive' } },
        { ownerName: { contains: ci(search), mode: 'insensitive' } },
        { phone: { contains: ci(search), mode: 'insensitive' } },
      ];
    }

    const leads = await prisma.shopLead.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({
      success: true,
      leads: leads.map((lead) => mapLead(lead)),
    });
  } catch (err) {
    next(err);
  }
}

async function retryLeadInviteOtp(req, res, next) {
  try {
    const pgCsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const leadId = req.params?.leadId;
    const updated = await retryLeadInvite({
      leadId,
      agentId: pgCsaId,
      agentRole: 'company_sales_agent',
      ipAddress: req.ip || req.connection?.remoteAddress || null,
    });
    res.status(200).json({
      success: true,
      lead: updated,
    });
  } catch (err) {
    if (err instanceof LeadConflictError) {
      return res.status(err.statusCode || 409).json({
        success: false,
        errorCode: err.code,
        message: err.message,
      });
    }
    next(err);
  }
}

module.exports = {
  getStats,
  getShops,
  getReports,
  getCoupons,
  createLead,
  getLeads,
  retryLeadInviteOtp,
};

