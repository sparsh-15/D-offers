const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { ensureCouponsForAgent } = require('./agentGovernanceController');

function ci(value) {
  return String(value || '').trim();
}

async function getStats(req, res, next) {
  try {
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const [assignedCount, shopProfiles, activeLeads, ssaCoupons] =
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

    if (!ci(shopName) || !ci(phone)) {
      return res.status(400).json({
        success: false,
        message: 'Shop name and phone are required',
      });
    }

    let normalizedCouponCode = null;
    if (couponCode && ci(couponCode)) {
      normalizedCouponCode = ci(couponCode).toUpperCase();
      const now = new Date();

      const coupon = await prisma.coupon.findFirst({
        where: {
          code: normalizedCouponCode,
          agentId: pgSsaId,
          isActive: true,
          OR: [{ expiryDate: null }, { expiryDate: { gt: now } }],
        },
      });

      if (!coupon) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired coupon code for this SSA',
        });
      }

      if (coupon.maxUses !== null && coupon.maxUses !== undefined) {
        if (coupon.currentUses >= coupon.maxUses) {
          return res.status(400).json({
            success: false,
            message: 'Coupon has reached its maximum uses',
          });
        }
      }
    }

    const lead = await prisma.shopLead.create({
      data: {
        ssaId: pgSsaId,
        shopName: ci(shopName),
        ownerName: ci(ownerName) || null,
        phone: ci(phone),
        pincode: ci(pincode) || null,
        city: ci(city) || null,
        category: ci(category) || null,
        notes: ci(notes) || null,
        couponCode: normalizedCouponCode,
        status: 'open',
      },
    });

    res.status(201).json({
      success: true,
      lead: {
        id: lead.id,
        shopName: lead.shopName,
        ownerName: lead.ownerName,
        phone: lead.phone,
        pincode: lead.pincode,
        city: lead.city,
        category: lead.category,
        notes: lead.notes,
        couponCode: lead.couponCode,
        status: lead.status,
        createdAt: lead.createdAt.toISOString(),
        updatedAt: lead.updatedAt.toISOString(),
      },
    });
  } catch (err) {
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
      leads: leads.map((lead) => ({
        id: lead.id,
        shopName: lead.shopName,
        ownerName: lead.ownerName,
        phone: lead.phone,
        pincode: lead.pincode,
        city: lead.city,
        category: lead.category,
        notes: lead.notes,
        couponCode: lead.couponCode,
        status: lead.status,
        createdAt: lead.createdAt.toISOString(),
        updatedAt: lead.updatedAt.toISOString(),
      })),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getStats,
  getShopkeepers,
  getCoupons,
  createLead,
  getLeads,
};
