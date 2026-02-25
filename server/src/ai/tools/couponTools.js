const { prisma } = require('../../db/prisma');

const DEFAULT_AGENT_MAX_DISCOUNT = 50;

function normalizeCouponListItem(coupon) {
  const agentCap =
    coupon.agent?.maxCouponDiscountPercent || DEFAULT_AGENT_MAX_DISCOUNT;
  const isPercentage = coupon.discountType === 'percentage';
  const discount = Number(coupon.discountValue || 0);
  const remainingIncentivePercent = isPercentage
    ? Math.max(0, agentCap - discount)
    : null;

  const now = new Date();
  const expiry = coupon.expiryDate ? new Date(coupon.expiryDate) : null;
  const isExpired = expiry != null && expiry < now;

  return {
    code: coupon.code,
    discountType: coupon.discountType,
    discountValue: coupon.discountValue,
    isActive: coupon.isActive && !isExpired,
    isExpired,
    remainingIncentivePercent,
    agentName: coupon.agent?.name || null,
    agentRole: coupon.agent?.role || null,
  };
}

/**
 * Get a general list of active coupons that a customer might use.
 * Currently this is not personalized; it simply returns active, non-expired coupons.
 */
async function getUserCoupons() {
  const now = new Date();

  const coupons = await prisma.coupon.findMany({
    where: {
      isActive: true,
      OR: [
        { expiryDate: null },
        { expiryDate: { gt: now } },
      ],
    },
    include: {
      agent: {
        select: {
          name: true,
          role: true,
          maxCouponDiscountPercent: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
    take: 20,
  });

  return {
    coupons: coupons.map(normalizeCouponListItem),
  };
}

/**
 * Simple placeholder for \"best coupons for a plan\".
 * For now, it returns the top N percentage coupons by discount.
 */
async function getBestCouponsForPlan({ params }) {
  const { limit = 5 } = params || {};
  const now = new Date();

  const coupons = await prisma.coupon.findMany({
    where: {
      isActive: true,
      discountType: 'percentage',
      OR: [
        { expiryDate: null },
        { expiryDate: { gt: now } },
      ],
    },
    include: {
      agent: {
        select: {
          name: true,
          role: true,
          maxCouponDiscountPercent: true,
        },
      },
    },
    orderBy: { discountValue: 'desc' },
    take: Math.min(Math.max(parseInt(limit, 10) || 5, 1), 10),
  });

  return {
    coupons: coupons.map(normalizeCouponListItem),
  };
}

module.exports = {
  getUserCoupons,
  getBestCouponsForPlan,
};

