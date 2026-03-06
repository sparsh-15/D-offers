const { prisma } = require('../db/prisma');
const offerRepository = require('../repositories/offerRepository');
const userRepository = require('../repositories/userRepository');
const { resolvePgId } = require('../repositories/idResolver');

const DEFAULT_AGENT_MAX_DISCOUNT = 50;
const MAX_PERCENTAGE_DISCOUNT = 99;

function ci(value) {
  return String(value || '').trim();
}

function normalizeAgentMaxDiscount(value) {
  if (value === undefined || value === null || value === '') return DEFAULT_AGENT_MAX_DISCOUNT;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return null;
  if (parsed < 1 || parsed > MAX_PERCENTAGE_DISCOUNT) return null;
  return parsed;
}

async function listOffers(req, res, next) {
  try {
    const {
      status,
      limit,
      skip,
      pincode,
      city,
      state,
      q,
      category,
      sort,
      segment,
    } = req.query;

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

    // Start with visible shopkeepers filtered by user location fields
    const visibleShopkeepers = await prisma.user.findMany({
      where: { ...baseUserFilter, ...locationFilter },
      select: { id: true },
    });

    let shopkeeperIds = visibleShopkeepers.map((u) => u.id);

    // If a pincode is provided, also include any shopkeepers whose profile has that pincode,
    // even if their user row doesn't have the pincode synced yet.
    if (ci(pincode)) {
      const profileMatches = await prisma.shopkeeperProfile.findMany({
        where: {
          pincode: ci(pincode),
        },
        select: { userId: true },
      });
      const extraIds = profileMatches.map((p) => p.userId);
      shopkeeperIds = Array.from(new Set([...shopkeeperIds, ...extraIds]));
    }

    // If no specific location matched, fall back to all visible shopkeepers
    if (!shopkeeperIds.length) {
      const allVisible = await prisma.user.findMany({
        where: baseUserFilter,
        select: { id: true },
      });
      shopkeeperIds = allVisible.map((u) => u.id);
    }

    if (!shopkeeperIds.length) {
      return res.status(200).json({ success: true, offers: [] });
    }
    where.shopkeeperId = { in: shopkeeperIds };

    const categoryCi = ci(category);
    if (categoryCi) {
      // Match both canonical codes and human labels (e.g. "clothing" vs "Clothing & Fashion")
      where.category = { contains: categoryCi, mode: 'insensitive' };
    }

    const [offersRaw, subscriptions, profiles] = await Promise.all([
      prisma.offer.findMany({
        where,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.subscription.findMany({
        where: { shopkeeperId: { in: shopkeeperIds }, status: 'active' },
        orderBy: { createdAt: 'desc' },
        select: { shopkeeperId: true, planSnapshot: true },
      }),
      prisma.shopkeeperProfile.findMany({
        where: { userId: { in: shopkeeperIds } },
        select: { userId: true, shopName: true },
      }),
    ]);

    const shopNameByUserId = {};
    profiles.forEach((p) => {
      shopNameByUserId[p.userId] = p.shopName || 'Shop';
    });

    const tierOrder = { top3: 3, priority: 2, normal: 1 };
    const tierByShop = {};
    subscriptions.forEach((s) => {
      if (!tierByShop[s.shopkeeperId]) {
        const tier =
          s.planSnapshot && s.planSnapshot.rankingTier
            ? s.planSnapshot.rankingTier
            : 'normal';
        tierByShop[s.shopkeeperId] = tierOrder[tier] ?? 1;
      }
    });

    const qCi = ci(q).toLowerCase();
    const hasQuery = !!qCi;

    const featuredOnly =
      typeof segment === 'string' &&
      ['featured', 'true', '1'].includes(segment.trim().toLowerCase());

    let offersWithMeta = offersRaw
      .map((o) => {
        const shopName = shopNameByUserId[o.shopkeeperId] || 'Shop';
        const tierScore = tierByShop[o.shopkeeperId] ?? 1;

        let matchesQuery = true;
        if (hasQuery) {
          const haystack = (
            (o.title || '') +
            ' ' +
            (o.description || '') +
            ' ' +
            (o.category || '') +
            ' ' +
            shopName
          )
            .toString()
            .toLowerCase();
          matchesQuery = haystack.includes(qCi);
        }

        return {
          ...o,
          _tierScore: tierScore,
          _shopName: shopName,
          _matchesQuery: matchesQuery,
        };
      })
      .filter((o) => o._matchesQuery);

    if (featuredOnly) {
      offersWithMeta = offersWithMeta.filter((o) => o._tierScore > 1);
    }

    const sortMode = (sort || '').toString().toLowerCase();

    offersWithMeta.sort((a, b) => {
      // Higher subscription tier first for all modes
      if (b._tierScore !== a._tierScore) {
        return b._tierScore - a._tierScore;
      }

      if (sortMode === 'most_liked') {
        if ((b.likesCount || 0) !== (a.likesCount || 0)) {
          return (b.likesCount || 0) - (a.likesCount || 0);
        }
      } else if (sortMode === 'discount_high_to_low') {
        const aVal = a.discountValue ? Number(a.discountValue) : 0;
        const bVal = b.discountValue ? Number(b.discountValue) : 0;
        if (bVal !== aVal) return bVal - aVal;
      } else if (sortMode === 'discount_low_to_high') {
        const aVal = a.discountValue ? Number(a.discountValue) : 0;
        const bVal = b.discountValue ? Number(b.discountValue) : 0;
        if (aVal !== bVal) return aVal - bVal;
      } else {
        // newest (default): fall through to createdAt below
      }

      const aDate = a.createdAt || new Date(0);
      const bDate = b.createdAt || new Date(0);
      return bDate - aDate;
    });

    const sliced = offersWithMeta.slice(skipNum, skipNum + limitNum);

    const pgUserId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const likes = await prisma.offerLike.findMany({
      where: { userId: pgUserId, offerId: { in: sliced.map((o) => o.id) } },
      select: { offerId: true },
    });
    const likedOfferIds = new Set(likes.map((l) => l.offerId));

    res.status(200).json({
      success: true,
      offers: sliced.map((o) => ({
        id: o.id,
        shopkeeperId: o.shopkeeperId,
        shopName: o._shopName || null,
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

async function requestCallback(req, res, next) {
  try {
    const { offerId, message } = req.body || {};

    if (!offerId || typeof offerId !== 'string') {
      const err = new Error('offerId is required');
      err.statusCode = 400;
      return next(err);
    }

    const pgOfferId = (await resolvePgId('offers', offerId)) || offerId;
    const pgUserId = (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const offer = await prisma.offer.findUnique({ where: { id: pgOfferId } });
    if (!offer) {
      const err = new Error('Offer not found');
      err.statusCode = 404;
      return next(err);
    }

    const trimmedMessage = typeof message === 'string' ? message.trim() : null;
    const finalMessage =
      trimmedMessage && trimmedMessage.length > 500
        ? trimmedMessage.slice(0, 500)
        : trimmedMessage;

    const callback = await prisma.callbackRequest.create({
      data: {
        offerId: pgOfferId,
        customerId: pgUserId,
        message: finalMessage,
      },
    });

    res.status(201).json({
      success: true,
      callback: {
        id: callback.id,
        offerId: callback.offerId,
        customerId: callback.customerId,
        status: callback.status,
        createdAt: callback.createdAt.toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function becomeSSA(req, res, next) {
  try {
    const user = await userRepository.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    if (user.role !== 'customer') {
      return res.status(403).json({
        success: false,
        message: 'Only customers can become a Service Sales Agent',
      });
    }

    const { email, pincode, city, state, region, maxCouponDiscountPercent } = req.body || {};
    const pincodeStr = ci(pincode);
    if (!pincodeStr) {
      return res.status(400).json({
        success: false,
        message: 'Pincode is required for SSA onboarding',
      });
    }

    const normalizedMax = normalizeAgentMaxDiscount(maxCouponDiscountPercent);
    if (normalizedMax === null) {
      return res.status(400).json({
        success: false,
        message: 'maxCouponDiscountPercent must be an integer between 1 and 99',
      });
    }

    const updates = {
      role: 'ssa',
      pincode: pincodeStr,
      city: ci(city) || user.city || '',
      state: ci(state) || user.state || '',
      region: ci(region) || user.region || '',
      maxCouponDiscountPercent: normalizedMax,
    };
    if (email !== undefined && email !== null) {
      updates.email = ci(email) || null;
    }
    if (!user.email && !updates.email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required for SSA onboarding',
      });
    }

    const updated = await userRepository.updateById(user.id, updates);
    if (!updated) {
      return res.status(500).json({ success: false, message: 'Failed to update user' });
    }

    const safeUser = {
      id: updated.id,
      name: updated.name,
      phone: updated.phone,
      role: updated.role,
      pincode: updated.pincode,
      city: updated.city,
      state: updated.state,
      address: updated.address || '',
      approvalStatus: updated.approvalStatus,
    };
    res.status(200).json({ success: true, user: safeUser });
  } catch (err) {
    next(err);
  }
}

module.exports = { listOffers, toggleLike, getLikedOffers, requestCallback, becomeSSA };
