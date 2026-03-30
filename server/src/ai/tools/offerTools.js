const { prisma } = require('../../db/prisma');
const { resolvePgId } = require('../../repositories/idResolver');
const offerRepository = require('../../repositories/offerRepository');
const {
  BUSINESS_CATEGORY_LIST,
  BUSINESS_CATEGORY_LABELS,
} = require('../../config/businessCategories');

function ci(value) {
  return String(value || '').trim();
}

function normalizeDiscount(value) {
  if (value === undefined || value === null) return null;
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return num;
}

const CATEGORY_ALIAS_MAP = {
  food: 'food_beverage',
  dining: 'food_beverage',
  restaurant: 'restaurant',
  restaurants: 'restaurant',
  cafe: 'food_beverage',
  cafes: 'food_beverage',
  grocery: 'grocery',
  groceries: 'grocery',
  fashion: 'clothing',
  clothes: 'clothing',
  clothing: 'clothing',
  apparel: 'clothing',
  medical: 'pharmacy',
  medicine: 'pharmacy',
  pharma: 'pharmacy',
  gym: 'gym_fitness',
  fitness: 'gym_fitness',
  beauty: 'beauty_salon',
  salon: 'beauty_salon',
  spa: 'beauty_salon',
  electronics: 'electronics',
  travel: 'travel',
  education: 'education',
  healthcare: 'healthcare',
};

function normalizeCategoryInput(input, allowedCategories = BUSINESS_CATEGORY_LIST) {
  const raw = ci(input).toLowerCase();
  if (!raw) {
    return { category: null, valid: false, source: 'empty' };
  }

  const normalizedAllowed = new Set(
    allowedCategories.map((category) => String(category).trim().toLowerCase()),
  );

  if (normalizedAllowed.has(raw)) {
    return { category: raw, valid: true, source: 'exact' };
  }

  const byAlias = CATEGORY_ALIAS_MAP[raw];
  if (byAlias && normalizedAllowed.has(byAlias)) {
    return { category: byAlias, valid: true, source: 'alias' };
  }

  const labelMatch = Object.entries(BUSINESS_CATEGORY_LABELS).find(([, label]) =>
    ci(label).toLowerCase() === raw,
  );
  if (labelMatch && normalizedAllowed.has(labelMatch[0])) {
    return { category: labelMatch[0], valid: true, source: 'label' };
  }

  return { category: null, valid: false, source: 'invalid' };
}

async function getActiveOfferCategories({ limit = 6 } = {}) {
  const rows = await prisma.offer.groupBy({
    by: ['category'],
    where: {
      status: 'active',
      category: {
        not: '',
      },
    },
    _count: {
      _all: true,
    },
    orderBy: {
      _count: {
        category: 'desc',
      },
    },
    take: Math.min(Math.max(Number(limit) || 6, 1), 20),
  });

  return rows
    .map((row) => String(row.category || '').trim().toLowerCase())
    .filter((category) => BUSINESS_CATEGORY_LIST.includes(category));
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

  let normalizedCategory = null;
  if (ci(category)) {
    const activeCategories = await getActiveOfferCategories({ limit: 50 });
    const allowedCategories = activeCategories.length
      ? activeCategories
      : BUSINESS_CATEGORY_LIST;
    const categoryMatch = normalizeCategoryInput(category, allowedCategories);
    if (!categoryMatch.valid) {
      return {
        offers: [],
        invalidCategory: ci(category),
        message: 'Invalid category. Please choose a valid category.',
      };
    }
    normalizedCategory = categoryMatch.category;
  }

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

  if (normalizedCategory) {
    where.category = { equals: normalizedCategory, mode: 'insensitive' };
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
  normalizeCategoryInput,
  getActiveOfferCategories,
};

