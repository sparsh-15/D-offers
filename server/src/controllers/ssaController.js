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

async function getStats(req, res, next) {
  try {
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const [assignedCount, shopProfiles, activeLeads, ssaCoupons, invitesSent, invitesFailed, leadLogins] =
      await Promise.all([
        prisma.shopkeeperProfile.count({
          where: { onboardedBy: pgSsaId },
        }),
        prisma.shopkeeperProfile.findMany({
          where: { onboardedBy: pgSsaId },
          select: { userId: true },
        }),
        prisma.shopLead.count({
          where: {
            ssaId: pgSsaId,
            status: { in: ['open', 'contacted'] },
          },
        }),
        prisma.coupon.findMany({
          where: { agentId: pgSsaId },
          select: { code: true },
        }),
        prisma.shopLead.count({
          where: { ssaId: pgSsaId, inviteStatus: 'sent' },
        }),
        prisma.shopLead.count({
          where: { ssaId: pgSsaId, inviteStatus: 'failed' },
        }),
        prisma.shopLead.count({
          where: { ssaId: pgSsaId, claimedAt: { not: null } },
        }),
      ]);

    const shopkeeperIds = [
      ...new Set(shopProfiles.map((p) => p.userId).filter(Boolean)),
    ];

    let activeCount = 0;
    if (shopkeeperIds.length > 0) {
      const activeSubs = await prisma.subscription.findMany({
        where: {
          shopkeeperId: { in: shopkeeperIds },
          status: 'active',
        },
        select: { shopkeeperId: true },
      });
      activeCount = new Set(activeSubs.map((s) => s.shopkeeperId)).size;
    }

    const couponCodes = ssaCoupons.map((c) => c.code);
    let conversions = 0;
    let commission = 0;
    if (couponCodes.length > 0) {
      const subs = await prisma.subscription.findMany({
        where: {
          couponCode: { in: couponCodes },
          status: 'active',
        },
        select: { id: true, discountAmount: true, actualPrice: true },
      });
      conversions = subs.length;
      // Simple commission rule: 5% of actualPrice for subs created via SSA coupons.
      commission = subs.reduce(
        (sum, s) => sum + Number(s.actualPrice || 0) * 0.05,
        0,
      );
    }

    res.status(200).json({
      success: true,
      stats: {
        assignedShopkeepers: assignedCount,
        activeShops: activeCount,
        activeLeads,
        leadInviteSent: invitesSent,
        leadInviteFailed: invitesFailed,
        leadLoggedIn: leadLogins,
        conversions,
        commission,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getShopkeepers(req, res, next) {
  try {
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const profiles = await prisma.shopkeeperProfile.findMany({
      where: { onboardedBy: pgSsaId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            city: true,
            state: true,
            isActive: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const shopkeepers = profiles.map((p) => ({
      id: p.id,
      userId: p.userId,
      shopName: p.shopName,
      address: p.address,
      pincode: p.pincode,
      city: p.city ?? p.user?.city,
      category: p.category,
      name: p.user?.name,
      phone: p.user?.phone,
      state: p.user?.state,
      isActive: p.user?.isActive ?? true,
      createdAt: p.createdAt,
    }));

    res.status(200).json({
      success: true,
      shopkeepers,
    });
  } catch (err) {
    next(err);
  }
}

async function getCoupons(req, res, next) {
  try {
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const agent = await prisma.user.findUnique({
      where: { id: pgSsaId, role: 'ssa' },
    });
    if (!agent) {
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }
    await ensureCouponsForAgent(agent);

    const now = new Date();
    const coupons = await prisma.coupon.findMany({
      where: {
        agentId: pgSsaId,
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

async function createLead(req, res, next) {
  try {
    const pgSsaId =
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
      agentId: pgSsaId,
      agentRole: 'ssa',
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
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const { status, search } = req.query || {};

    const where = { ssaId: pgSsaId };
    if (status && ci(status)) {
      where.status = ci(status).toLowerCase();
    }
    if (search && ci(search)) {
      const q = `%${ci(search).toLowerCase()}%`;
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
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const leadId = req.params?.leadId;
    const updated = await retryLeadInvite({
      leadId,
      agentId: pgSsaId,
      agentRole: 'ssa',
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
  getShopkeepers,
  getCoupons,
  createLead,
  getLeads,
  retryLeadInviteOtp,
};
