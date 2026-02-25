const { prisma } = require('../../db/prisma');
const { resolvePgId } = require('../../repositories/idResolver');
const offerRepository = require('../../repositories/offerRepository');

function ci(value) {
  return String(value || '').trim();
}

function normalizeDiscount(value) {
  if (value === undefined || value === null) return null;
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return num;
}

/**
 * Search active offers for the customer, filtered by optional
 * text query, category, pincode/city/state, and minimum discount.
 * Returns a compact list of offers plus navigation metadata.
 */
async function searchOffers({ user, params }) {
  const {
    query,
    category,
    pincode,
    city,
    state,
    minDiscount,
    limit = 20,
  } = params || {};

  const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 50);

  // Reuse the same filtering strategy as customerController.listOffers
  const userFilter = { role: 'shopkeeper', approvalStatus: 'approved' };
  if (ci(pincode)) userFilter.pincode = ci(pincode);
  if (ci(city)) userFilter.city = { equals: ci(city), mode: 'insensitive' };
  if (ci(state)) userFilter.state = { equals: ci(state), mode: 'insensitive' };

  const approvedShopkeepers = await prisma.user.findMany({
    where: userFilter,
    select: { id: true },
  });
  const shopkeeperIds = approvedShopkeepers.map((u) => u.id);
  if (!shopkeeperIds.length) {
    return { offers: [] };
  }

  const where = {
    shopkeeperId: { in: shopkeeperIds },
    status: 'active',
  };

  if (ci(category)) {
    where.category = { equals: ci(category), mode: 'insensitive' };
  }

  const minDiscountNum = normalizeDiscount(minDiscount);
  if (minDiscountNum !== null) {
    where.discountValue = { gte: minDiscountNum };
  }

  if (ci(query)) {
    where.OR = [
      { title: { contains: ci(query), mode: 'insensitive' } },
      { description: { contains: ci(query), mode: 'insensitive' } },
    ];
  }

  const offers = await prisma.offer.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: limitNum,
  });

  if (!offers.length) {
    return { offers: [] };
  }

  const profiles = await prisma.shopkeeperProfile.findMany({
    where: { userId: { in: shopkeeperIds } },
    select: { userId: true, shopName: true },
  });
  const shopNameByUserId = {};
  profiles.forEach((p) => {
    shopNameByUserId[p.userId] = p.shopName || 'Shop';
  });

  // Mark liked offers for this user
  const pgUserId = (await resolvePgId('users', user.userId)) || user.userId;
  const likes = await prisma.offerLike.findMany({
    where: { userId: pgUserId, offerId: { in: offers.map((o) => o.id) } },
    select: { offerId: true },
  });
  const likedOfferIds = new Set(likes.map((l) => l.offerId));

  const simplifiedOffers = offers.map((o) => ({
    id: o.id,
    title: o.title || '',
    shopName: shopNameByUserId[o.shopkeeperId] || null,
    discountType: o.discountType || '',
    discountValue: o.discountValue,
    category: o.category || '',
    status: o.status || 'active',
    isLiked: likedOfferIds.has(o.id),
    likesCount: o.likesCount || 0,
    deepLink: {
      screen: 'offer_detail',
      offerId: o.id,
    },
  }));

  return { offers: simplifiedOffers };
}

/**
 * Toggle like state to liked=true for the given offer.
 * If already liked, it is a no-op.
 */
async function likeOffer({ user, params }) {
  const { offerId } = params || {};
  if (!offerId) {
    const err = new Error('offerId is required for like_offer');
    err.statusCode = 400;
    throw err;
  }

  const offer = await prisma.offer.findUnique({ where: { id: offerId } });
  if (!offer) {
    const err = new Error('Offer not found');
    err.statusCode = 404;
    throw err;
  }

  const userId = user.userId;
  const existing = await prisma.offerLike.findUnique({
    where: { offerId_userId: { offerId, userId } },
  });

  let isLiked = !!existing;
  let likesCount = offer.likesCount || 0;

  if (!isLiked) {
    likesCount = await offerRepository.toggleLike(offerId, userId, false);
    isLiked = true;
  }

  return {
    offerId,
    isLiked,
    likesCount,
  };
}

/**
 * Toggle like state to liked=false for the given offer.
 * If already unliked, it is a no-op.
 */
async function unlikeOffer({ user, params }) {
  const { offerId } = params || {};
  if (!offerId) {
    const err = new Error('offerId is required for unlike_offer');
    err.statusCode = 400;
    throw err;
  }

  const offer = await prisma.offer.findUnique({ where: { id: offerId } });
  if (!offer) {
    const err = new Error('Offer not found');
    err.statusCode = 404;
    throw err;
  }

  const userId = user.userId;
  const existing = await prisma.offerLike.findUnique({
    where: { offerId_userId: { offerId, userId } },
  });

  let isLiked = !!existing;
  let likesCount = offer.likesCount || 0;

  if (isLiked) {
    likesCount = await offerRepository.toggleLike(offerId, userId, true);
    isLiked = false;
  }

  return {
    offerId,
    isLiked,
    likesCount,
  };
}

module.exports = {
  searchOffers,
  likeOffer,
  unlikeOffer,
};

