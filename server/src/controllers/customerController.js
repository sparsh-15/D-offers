const { prisma } = require('../db/prisma');
const crypto = require('crypto');
const offerRepository = require('../repositories/offerRepository');
const userRepository = require('../repositories/userRepository');
const { resolvePgId } = require('../repositories/idResolver');

const DEFAULT_AGENT_MAX_DISCOUNT = 50;
const MAX_PERCENTAGE_DISCOUNT = 99;

function ci(value) {
  return String(value || '').trim();
}

function hasEffectiveRole(user, targetRole) {
  const userRoles = Array.isArray(user?.roles) && user.roles.length > 0
    ? user.roles
    : [user?.role];
  return userRoles.includes(targetRole);
}

function normalizeCity(value) {
  return ci(value).replace(/\s+/g, ' ');
}

function normalizeAgentMaxDiscount(value) {
  if (value === undefined || value === null || value === '') return DEFAULT_AGENT_MAX_DISCOUNT;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return null;
  if (parsed < 1 || parsed > MAX_PERCENTAGE_DISCOUNT) return null;
  return parsed;
}

function buildClaimCouponCode() {
  const random = crypto.randomBytes(3).toString('hex').toUpperCase();
  const stamp = Date.now().toString(36).toUpperCase();
  return `DL${stamp}${random}`;
}

async function generateUniqueClaimCouponCode() {
  for (let attempt = 0; attempt < 6; attempt += 1) {
    const code = buildClaimCouponCode();
    // eslint-disable-next-line no-await-in-loop
    const existing = await prisma.coupon.findUnique({ where: { code } });
    if (!existing) return code;
  }
  throw new Error('Could not generate unique claim coupon code');
}

function serializeClaim(claim) {
  const couponCode = claim.coupon?.code || '';
  const payload = {
    claimId: claim.id,
    offerId: claim.offerId,
    couponCode,
  };

  return {
    id: claim.id,
    status: claim.status,
    claimedAt: claim.claimedAt,
    redeemedAt: claim.redeemedAt,
    expiresAt: claim.expiresAt,
    offer: claim.offer
      ? {
          id: claim.offer.id,
          title: claim.offer.title,
          shopkeeperId: claim.offer.shopkeeperId,
          validTo: claim.offer.validTo,
          discountType: claim.offer.discountType,
          discountValue: Number(claim.offer.discountValue || 0),
        }
      : null,
    coupon: claim.coupon
      ? {
          id: claim.coupon.id,
          code: claim.coupon.code,
          discountType: claim.coupon.discountType,
          discountValue: Number(claim.coupon.discountValue || 0),
          expiryDate: claim.coupon.expiryDate,
          maxUses: claim.coupon.maxUses,
          currentUses: claim.coupon.currentUses,
        }
      : null,
    qrPayload: JSON.stringify(payload),
  };
}

async function listOffers(req, res, next) {
  try {
    const {
      status,
      limit,
      offset,
      skip,
      pincode,
      city,
      state,
      q,
      category,
      sort,
      segment,
    } = req.query;

    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 30, 1), 100);
    const rawOffset = offset !== undefined ? offset : skip;
    const offsetNum = Math.max(parseInt(rawOffset, 10) || 0, 0);

    const pgUserId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const requester = await prisma.user.findUnique({
      where: { id: pgUserId },
      select: { pincode: true, city: true, state: true },
    });

    const explicitPincode = ci(pincode);
    const explicitCity = normalizeCity(city);
    const explicitState = ci(state);

    // Priority: explicit pincode > explicit city > explicit state > profile city > profile state
    // Do not auto-fallback to profile pincode; this blocks intentional city-only searches.
    const requestedPincode = explicitPincode;
    const requestedCity =
      !requestedPincode && (explicitCity || normalizeCity(requester?.city));
    const requestedState =
      !requestedPincode && !requestedCity && (explicitState || ci(requester?.state));

    // Location-first feed: if we still don't have any location context, return empty.
    if (!requestedPincode && !requestedCity && !requestedState) {
      return res.status(200).json({
        success: true,
        offers: [],
        pageInfo: {
          offset: offsetNum,
          limit: limitNum,
          total: 0,
          hasMore: false,
          nextOffset: null,
        },
      });
    }

    const where = {
      status: status || 'active',
    };

    const baseUserFilter = {
      role: 'shopkeeper',
      isActive: true,
      approvalStatus: { not: 'rejected' },
    };

    let shopkeeperIds = [];
    let filterSource = 'none';

    if (requestedPincode) {
      filterSource = 'pincode';
      const [visibleShopkeepers, profileMatches] = await Promise.all([
        prisma.user.findMany({
          where: { ...baseUserFilter, pincode: requestedPincode },
          select: { id: true },
        }),
        prisma.shopkeeperProfile.findMany({
          where: { pincode: requestedPincode },
          select: { userId: true },
        }),
      ]);
      shopkeeperIds = Array.from(
        new Set([
          ...visibleShopkeepers.map((u) => u.id),
          ...profileMatches.map((p) => p.userId),
        ]),
      );
    } else if (requestedCity) {
      filterSource = 'city';
      const [visibleShopkeepers, profileMatches] = await Promise.all([
        prisma.user.findMany({
          where: {
            ...baseUserFilter,
            city: { equals: requestedCity, mode: 'insensitive' },
          },
          select: { id: true },
        }),
        prisma.shopkeeperProfile.findMany({
          where: { city: { equals: requestedCity, mode: 'insensitive' } },
          select: { userId: true },
        }),
      ]);
      shopkeeperIds = Array.from(
        new Set([
          ...visibleShopkeepers.map((u) => u.id),
          ...profileMatches.map((p) => p.userId),
        ]),
      );
    } else if (requestedState) {
      filterSource = 'state';
      const visibleShopkeepers = await prisma.user.findMany({
        where: {
          ...baseUserFilter,
          state: { equals: requestedState, mode: 'insensitive' },
        },
        select: { id: true },
      });
      shopkeeperIds = visibleShopkeepers.map((u) => u.id);
    }

    if (!shopkeeperIds.length) {
      return res.status(200).json({
        success: true,
        offers: [],
        pageInfo: {
          offset: offsetNum,
          limit: limitNum,
          total: 0,
          hasMore: false,
          nextOffset: null,
        },
        filterContext: {
          source: filterSource,
        },
      });
    }

    where.shopkeeperId = { in: shopkeeperIds };

    const categoryCi = ci(category);
    if (categoryCi) {
      where.category = { contains: categoryCi, mode: 'insensitive' };
    }

    const qCi = ci(q);
    if (qCi) {
      where.OR = [
        { title: { contains: qCi, mode: 'insensitive' } },
        { description: { contains: qCi, mode: 'insensitive' } },
        { category: { contains: qCi, mode: 'insensitive' } },
      ];
    }

    const featuredOnly =
      typeof segment === 'string' &&
      ['featured', 'true', '1'].includes(segment.trim().toLowerCase());

    if (featuredOnly) {
      const subscriptions = await prisma.subscription.findMany({
        where: { shopkeeperId: { in: shopkeeperIds }, status: 'active' },
        orderBy: { createdAt: 'desc' },
        select: { shopkeeperId: true, planSnapshot: true },
      });
      const featuredShopkeepers = new Set();
      subscriptions.forEach((s) => {
        const tier =
          s.planSnapshot && s.planSnapshot.rankingTier
            ? String(s.planSnapshot.rankingTier).toLowerCase()
            : 'normal';
        if (tier === 'top3' || tier === 'priority') {
          featuredShopkeepers.add(s.shopkeeperId);
        }
      });
      const featuredIds = Array.from(featuredShopkeepers);
      if (!featuredIds.length) {
        return res.status(200).json({
          success: true,
          offers: [],
          pageInfo: {
            offset: offsetNum,
            limit: limitNum,
            total: 0,
            hasMore: false,
            nextOffset: null,
          },
          filterContext: {
            source: filterSource,
          },
        });
      }
      where.shopkeeperId = { in: featuredIds };
    }

    const sortMode = (sort || '').toString().toLowerCase();
    const orderBy = [];
    if (sortMode === 'most_liked') {
      orderBy.push({ likesCount: 'desc' });
    } else if (sortMode === 'discount_high_to_low') {
      orderBy.push({ discountValue: 'desc' });
    } else if (sortMode === 'discount_low_to_high') {
      orderBy.push({ discountValue: 'asc' });
    }
    orderBy.push({ createdAt: 'desc' });

    const [offersRaw, total] = await Promise.all([
      prisma.offer.findMany({
        where,
        orderBy,
        skip: offsetNum,
        take: limitNum,
      }),
      prisma.offer.count({ where }),
    ]);

    const offerShopkeeperIds = Array.from(
      new Set(offersRaw.map((o) => o.shopkeeperId)),
    );
    const profiles = offerShopkeeperIds.length
      ? await prisma.shopkeeperProfile.findMany({
          where: { userId: { in: offerShopkeeperIds } },
          select: { userId: true, shopName: true, logoUrl: true },
        })
      : [];

    const shopNameByUserId = {};
    const shopLogoByUserId = {};
    profiles.forEach((p) => {
      shopNameByUserId[p.userId] = p.shopName || 'Shop';
      shopLogoByUserId[p.userId] = p.logoUrl || null;
    });

    const likes = await prisma.offerLike.findMany({
      where: { userId: pgUserId, offerId: { in: offersRaw.map((o) => o.id) } },
      select: { offerId: true },
    });
    const likedOfferIds = new Set(likes.map((l) => l.offerId));

    const claims = await prisma.customerOfferClaim.findMany({
      where: {
        customerId: pgUserId,
        offerId: { in: offersRaw.map((o) => o.id) },
      },
      select: { offerId: true },
    });
    const claimedOfferIds = new Set(claims.map((c) => c.offerId));

    const nextOffset = offsetNum + offersRaw.length;
    const hasMore = nextOffset < total;

    res.status(200).json({
      success: true,
      offers: offersRaw.map((o) => ({
        id: o.id,
        shopkeeperId: o.shopkeeperId,
        shopName: shopNameByUserId[o.shopkeeperId] || null,
        shopLogoUrl: shopLogoByUserId[o.shopkeeperId] || null,
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
        isClaimed: claimedOfferIds.has(o.id),
        createdAt: o.createdAt ? o.createdAt.toISOString() : null,
        updatedAt: o.updatedAt ? o.updatedAt.toISOString() : null,
      })),
      pageInfo: {
        offset: offsetNum,
        limit: limitNum,
        total,
        hasMore,
        nextOffset: hasMore ? nextOffset : null,
      },
      filterContext: {
        source: filterSource,
      },
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
      select: { userId: true, shopName: true, logoUrl: true },
    });
    const shopNameByUserId = {};
    const shopLogoByUserId = {};
    profiles.forEach((p) => {
      shopNameByUserId[p.userId] = p.shopName || 'Shop';
      shopLogoByUserId[p.userId] = p.logoUrl || null;
    });

    const claims = await prisma.customerOfferClaim.findMany({
      where: {
        customerId: userId,
        offerId: { in: offerIds },
      },
      select: { offerId: true },
    });
    const claimedOfferIds = new Set(claims.map((c) => c.offerId));

    res.status(200).json({
      success: true,
      offers: offers.map((o) => ({
        id: o.id,
        shopkeeperId: o.shopkeeperId,
        shopName: shopNameByUserId[o.shopkeeperId] || null,
        shopLogoUrl: shopLogoByUserId[o.shopkeeperId] || null,
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
        isClaimed: claimedOfferIds.has(o.id),
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

async function claimOffer(req, res, next) {
  try {
    if (!hasEffectiveRole(req.user, 'customer')) {
      return res.status(403).json({
        success: false,
        message: 'Only customers can claim offers',
      });
    }

    const offerIdInput = ci(req.params.id);
    if (!offerIdInput) {
      return res.status(400).json({ success: false, message: 'offerId is required' });
    }

    const offerId = await resolvePgId('offers', offerIdInput);
    const customerId = await resolvePgId('users', req.user.userId);

    if (!offerId) {
      return res.status(404).json({ success: false, message: 'Offer not found' });
    }
    if (!customerId) {
      return res.status(401).json({ success: false, message: 'Invalid authenticated user' });
    }

    const offer = await prisma.offer.findUnique({ where: { id: offerId } });
    if (!offer) {
      return res.status(404).json({ success: false, message: 'Offer not found' });
    }
    if (offer.status !== 'active') {
      return res.status(400).json({ success: false, message: 'Offer is not active' });
    }
    if (offer.validTo && new Date(offer.validTo) <= new Date()) {
      return res.status(400).json({ success: false, message: 'Offer has expired' });
    }

    const existingClaim = await prisma.customerOfferClaim.findUnique({
      where: {
        customerId_offerId: {
          customerId,
          offerId,
        },
      },
      include: {
        offer: true,
        coupon: true,
      },
    });

    if (existingClaim) {
      return res.status(200).json({
        success: true,
        alreadyClaimed: true,
        message: 'Offer already claimed',
        claim: serializeClaim(existingClaim),
      });
    }

    const code = await generateUniqueClaimCouponCode();

    const claim = await prisma.$transaction(async (tx) => {
      const coupon = await tx.coupon.create({
        data: {
          code,
          discountType: offer.discountType,
          discountValue: offer.discountValue || 0,
          agentId: offer.shopkeeperId,
          description: `Customer claim coupon for offer ${offer.id}`,
          expiryDate: offer.validTo || null,
          maxUses: 1,
          currentUses: 0,
          isActive: true,
        },
      });

      return tx.customerOfferClaim.create({
        data: {
          customerId,
          offerId: offer.id,
          couponId: coupon.id,
          status: 'active',
          expiresAt: offer.validTo || null,
          metadata: {
            source: 'customer-claim-api',
          },
        },
        include: {
          offer: true,
          coupon: true,
        },
      });
    });

    return res.status(201).json({
      success: true,
      alreadyClaimed: false,
      message: 'Offer claimed successfully',
      claim: serializeClaim(claim),
    });
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({
        success: false,
        message: 'Offer already claimed',
      });
    }
    next(err);
  }
}

async function listMyClaims(req, res, next) {
  try {
    if (!hasEffectiveRole(req.user, 'customer')) {
      return res.status(403).json({
        success: false,
        message: 'Only customers can view their claims',
      });
    }

    const customerId = await resolvePgId('users', req.user.userId);
    if (!customerId) {
      return res.status(401).json({ success: false, message: 'Invalid authenticated user' });
    }

    const safeLimit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
    const safeOffset = Math.max(parseInt(req.query.offset, 10) || 0, 0);
    const status = ci(req.query.status).toLowerCase();

    const where = {
      customerId,
      ...(status ? { status } : {}),
    };

    const [claims, total] = await Promise.all([
      prisma.customerOfferClaim.findMany({
        where,
        include: {
          offer: true,
          coupon: true,
        },
        orderBy: {
          claimedAt: 'desc',
        },
        skip: safeOffset,
        take: safeLimit,
      }),
      prisma.customerOfferClaim.count({ where }),
    ]);

    return res.status(200).json({
      success: true,
      claims: claims.map(serializeClaim),
      pageInfo: {
        offset: safeOffset,
        limit: safeLimit,
        total,
        hasMore: safeOffset + claims.length < total,
        nextOffset: safeOffset + claims.length < total ? safeOffset + claims.length : null,
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
    const existingPermissions = Array.isArray(user.permissions)
      ? user.permissions
      : [];
    const hasCustomerCapability =
      user.role === 'customer' || existingPermissions.includes('customer');

    if (!hasCustomerCapability) {
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

    const mergedPermissions = Array.from(
      new Set([...existingPermissions, 'customer']),
    );

    const updates = {
      role: 'ssa',
      permissions: mergedPermissions,
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

async function getOfferById(req, res, next) {
  try {
    const { id } = req.params;
    const pgUserId =
      (await resolvePgId('users', req.user.userId)) || req.user.userId;

    const offer = await prisma.offer.findUnique({ where: { id } });
    if (!offer) {
      return res.status(404).json({ success: false, message: 'Offer not found' });
    }

    const [profile, like] = await Promise.all([
      prisma.shopkeeperProfile.findFirst({
        where: { userId: offer.shopkeeperId },
        select: { shopName: true, logoUrl: true },
      }),
      prisma.offerLike.findFirst({
        where: { userId: pgUserId, offerId: offer.id },
      }),
    ]);

    res.status(200).json({
      success: true,
      offer: {
        id: offer.id,
        shopkeeperId: offer.shopkeeperId,
        shopName: profile?.shopName || null,
        shopLogoUrl: profile?.logoUrl || null,
        title: offer.title || '',
        description: offer.description || '',
        photos: offer.photos || [],
        termsAndConditions: offer.termsAndConditions || '',
        category: offer.category || '',
        discountType: offer.discountType || '',
        discountValue: offer.discountValue,
        validFrom: offer.validFrom ? offer.validFrom.toISOString() : null,
        validTo: offer.validTo ? offer.validTo.toISOString() : null,
        status: offer.status || 'active',
        likesCount: offer.likesCount || 0,
        isLiked: !!like,
        createdAt: offer.createdAt ? offer.createdAt.toISOString() : null,
        updatedAt: offer.updatedAt ? offer.updatedAt.toISOString() : null,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listOffers,
  getOfferById,
  toggleLike,
  getLikedOffers,
  requestCallback,
  claimOffer,
  listMyClaims,
  becomeSSA,
};
