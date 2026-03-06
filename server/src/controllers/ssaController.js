const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');

async function getStats(req, res, next) {
  try {
    const pgSsaId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const assignedCount = await prisma.shopkeeperProfile.count({
      where: { onboardedBy: pgSsaId },
    });

    const shopProfiles = await prisma.shopkeeperProfile.findMany({
      where: { onboardedBy: pgSsaId },
      select: { userId: true },
    });
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

    res.status(200).json({
      success: true,
      stats: {
        assignedShopkeepers: assignedCount,
        activeShops: activeCount,
        activeLeads: 0,
        conversions: 0,
        commission: 0,
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

module.exports = { getStats, getShopkeepers };
