const { prisma } = require('../db/prisma');
const offerRepository = require('../repositories/offerRepository');
const { resolvePgId } = require('../repositories/idResolver');

function ci(value) {
  return String(value || '').trim();
}

async function listOffers(req, res, next) {
  try {
    const { status, limit, skip, pincode, city, state } = req.query;
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 100, 1), 200);
    const skipNum = Math.max(parseInt(skip, 10) || 0, 0);

    const where = {};
    if (status) where.status = status;

    const baseUserFilter = {
      role: 'shopkeeper',
      isActive: true,
      approvalStatus: { not: 'rejected' },
    };

    const locationFilter = {};
    if (ci(pincode)) locationFilter.pincode = ci(pincode);
    if (ci(city))
      locationFilter.city = { equals: ci(city), mode: 'insensitive' };
    if (ci(state))
      locationFilter.state = { equals: ci(state), mode: 'insensitive' };

    // First try with location filters, then fall back to all visible shopkeepers
    let visibleShopkeepers = await prisma.user.findMany({
      where: { ...baseUserFilter, ...locationFilter },
      select: { id: true },
    });

    if (!visibleShopkeepers.length && Object.keys(locationFilter).length > 0) {
      visibleShopkeepers = await prisma.user.findMany({
        where: baseUserFilter,
        select: { id: true },
      });
    }

    const shopkeeperIds = visibleShopkeepers.map((u) => u.id);
    if (!shopkeeperIds.length) return res.status(200).json({ success: true, offers: [] });
    where.shopkeeperId = { in: shopkeeperIds };

    const [offersRaw, subscriptions] = await Promise.all([
      prisma.offer.findMany({
        where,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.subscription.findMany({
        where: { shopkeeperId: { in: shopkeeperIds }, status: 'active' },
        orderBy: { createdAt: 'desc' },
        select: { shopkeeperId: true, planSnapshot: true },
      }),
    ]);

    const tierOrder = { top3: 3, priority: 2, normal: 1 };
    const tierByShop = {};
    subscriptions.forEach((s) => {
      if (!tierByShop[s.shopkeeperId]) {
        const tier = (s.planSnapshot && s.planSnapshot.rankingTier) ? s.planSnapshot.rankingTier : 'normal';
        tierByShop[s.shopkeeperId] = tierOrder[tier] ?? 1;
      }
    });

    const offers = offersRaw
      .map((o) => ({
        ...o,
        _tierScore: tierByShop[o.shopkeeperId] ?? 1,
      }))
      .sort((a, b) => {
        if (b._tierScore !== a._tierScore) return b._tierScore - a._tierScore;
        if ((b.likesCount || 0) !== (a.likesCount || 0)) return (b.likesCount || 0) - (a.likesCount || 0);
        return new Date(b.createdAt) - new Date(a.createdAt);
      })
      .slice(skipNum, skipNum + limitNum);

    const profiles = await prisma.shopkeeperProfile.findMany({
      where: { userId: { in: shopkeeperIds } },
      select: { userId: true, shopName: true },
    });
    const shopNameByUserId = {};
    profiles.forEach((p) => {
      shopNameByUserId[p.userId] = p.shopName || 'Shop';
    });

    const pgUserId = await resolvePgId('users', req.user.userId);
    const likes = await prisma.offerLike.findMany({
      where: { userId: pgUserId, offerId: { in: offers.map((o) => o.id) } },
      select: { offerId: true },
    });
    const likedOfferIds = new Set(likes.map((l) => l.offerId));

    res.status(200).json({
      success: true,
      offers: offers.map((o) => ({
        id: o.id,
        shopkeeperId: o.shopkeeperId,
        shopName: shopNameByUserId[o.shopkeeperId] || null,
        title: o.title || '',
        description: o.description || '',
        photos: o.photos || [],
        termsAndConditions: o.termsAndConditions || '',
        category: o.category || '',
        discountType: o.discountType || '',
        discountValue: o.discountValue,
        validFrom: o.validFrom ? o.validFrom.toISOString() : null,
        validTo: o.validTo ? o.validTo.toISOString() : null,
        status: o.status || 'active',
        likesCount: o.likesCount || 0,
        isLiked: likedOfferIds.has(o.id),
        createdAt: o.createdAt ? o.createdAt.toISOString() : null,
        updatedAt: o.updatedAt ? o.updatedAt.toISOString() : null,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function toggleLike(req, res, next) {
  try {
    const offerId = (await resolvePgId('offers', req.params.id)) || req.params.id;
    const userId = (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const offer = await prisma.offer.findUnique({ where: { id: offerId } });
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }
    const existing = await prisma.offerLike.findUnique({
      where: { offerId_userId: { offerId, userId } },
    });
    const isLiked = !!existing;
    const likesCount = await offerRepository.toggleLike(offerId, userId, isLiked);
    res.status(200).json({ success: true, isLiked: !isLiked, likesCount });
  } catch (err) {
    next(err);
  }
}

async function getLikedOffers(req, res, next) {
  try {
    const userId = (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const likes = await prisma.offerLike.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { offerId: true },
    });
    const offerIds = likes.map((l) => l.offerId);
    if (!offerIds.length) return res.status(200).json({ success: true, offers: [] });
    const offers = await prisma.offer.findMany({
      where: { id: { in: offerIds } },
      orderBy: { createdAt: 'desc' },
    });
    const profiles = await prisma.shopkeeperProfile.findMany({
      where: { userId: { in: offers.map((o) => o.shopkeeperId) } },
      select: { userId: true, shopName: true },
    });
    const shopNameByUserId = {};
    profiles.forEach((p) => {
      shopNameByUserId[p.userId] = p.shopName || 'Shop';
    });
    res.status(200).json({
      success: true,
      offers: offers.map((o) => ({
        id: o.id,
        shopkeeperId: o.shopkeeperId,
        shopName: shopNameByUserId[o.shopkeeperId] || null,
        title: o.title || '',
        description: o.description || '',
        photos: o.photos || [],
        termsAndConditions: o.termsAndConditions || '',
        category: o.category || '',
        discountType: o.discountType || '',
        discountValue: o.discountValue,
        validFrom: o.validFrom ? o.validFrom.toISOString() : null,
        validTo: o.validTo ? o.validTo.toISOString() : null,
        status: o.status || 'active',
        likesCount: o.likesCount || 0,
        isLiked: true,
        createdAt: o.createdAt ? o.createdAt.toISOString() : null,
        updatedAt: o.updatedAt ? o.updatedAt.toISOString() : null,
      })),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { listOffers, toggleLike, getLikedOffers };
