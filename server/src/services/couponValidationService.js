/**
 * Shared coupon validation and pricing for subscription quote and create.
 * Single source of truth for discount computation and attribution.
 */

const APP_SETTING_KEY_COUPON_CAP = 'max_coupon_discount_percent';
const DEFAULT_AGENT_CAP = 50;

function ci(value) {
  return String(value || '').trim();
}

function normalizeCode(value) {
  const trimmed = ci(value);
  return trimmed ? trimmed.toUpperCase() : null;
}

/**
 * Fetch global coupon cap from app_settings (optional override for agent cap).
 * @param {object} prisma
 * @returns {Promise<number>}
 */
async function getGlobalCouponCap(prisma) {
  try {
    const row = await prisma.appSetting.findUnique({
      where: { key: APP_SETTING_KEY_COUPON_CAP },
    });
    if (row && row.value) {
      const n = parseInt(row.value, 10);
      if (Number.isFinite(n) && n >= 1 && n <= 99) return n;
    }
  } catch (_) {}
  return DEFAULT_AGENT_CAP;
}

/**
 * Validate coupon and compute discount for a given base price.
 * Does NOT increment coupon usage; callers must do that on actual subscription create.
 *
 * @param {object} params
 * @param {object} params.prisma - Prisma client
 * @param {string|null} params.couponCode - Raw coupon code (optional)
 * @param {number} params.fullPrice - Base price (e.g. monthlyPrice * durationMonths)
 * @param {number} [params.durationMonths] - Duration in months (for logging only)
 * @returns {Promise<{
 *   success: boolean,
 *   errorCode?: string,
 *   message?: string,
 *   basePrice: number,
 *   discountAmount: number,
 *   finalPrice: number,
 *   appliedCouponCode?: string,
 *   attribution?: { agentId: string, agentName: string, agentRole: string }
 * }>}
 */
async function validateAndComputeDiscount({ prisma, couponCode, fullPrice }) {
  const basePrice = Number(fullPrice);
  const result = {
    success: true,
    basePrice: basePrice,
    discountAmount: 0,
    finalPrice: basePrice,
  };

  if (!couponCode || !ci(couponCode)) {
    return result;
  }

  const code = normalizeCode(couponCode);
  const now = new Date();

  const coupon = await prisma.coupon.findFirst({
    where: {
      code,
      isActive: true,
      OR: [{ expiryDate: null }, { expiryDate: { gt: now } }],
    },
    include: {
      agent: {
        select: {
          id: true,
          name: true,
          role: true,
          maxCouponDiscountPercent: true,
        },
      },
    },
  });

  if (!coupon) {
    return {
      ...result,
      success: false,
      errorCode: 'invalid_coupon',
      message: 'Invalid or expired coupon code',
    };
  }

  if (coupon.expiryDate && new Date(coupon.expiryDate) <= now) {
    return {
      ...result,
      success: false,
      errorCode: 'expired_coupon',
      message: 'Coupon has expired',
    };
  }

  if (coupon.maxUses != null && coupon.currentUses >= coupon.maxUses) {
    return {
      ...result,
      success: false,
      errorCode: 'usage_limit_reached',
      message: 'Coupon has reached its maximum uses',
    };
  }

  const rawDiscount = Number(coupon.discountValue || 0);
  if (!Number.isFinite(rawDiscount) || rawDiscount <= 0) {
    return {
      ...result,
      success: false,
      errorCode: 'invalid_discount_value',
      message: 'Coupon has invalid discount value',
    };
  }

  let discountAmount = 0;
  if (coupon.discountType === 'percentage') {
    const agentCap =
      (coupon.agent &&
        coupon.agent.maxCouponDiscountPercent != null &&
        Number(coupon.agent.maxCouponDiscountPercent)) ||
      DEFAULT_AGENT_CAP;
    const globalCap = await getGlobalCouponCap(prisma);
    const cap = Math.min(agentCap, globalCap);
    const pct = Math.min(Math.max(1, Math.round(rawDiscount)), Math.min(cap, 99));
    discountAmount = (basePrice * pct) / 100;
  } else {
    discountAmount = Math.min(rawDiscount, basePrice);
  }

  const finalPrice = Math.max(0, basePrice - discountAmount);

  const attribution = coupon.agent
    ? {
        agentId: coupon.agent.id,
        agentName: coupon.agent.name || 'Agent',
        agentRole: coupon.agent.role || 'ssa',
      }
    : undefined;

  return {
    ...result,
    discountAmount,
    finalPrice,
    appliedCouponCode: code,
    attribution,
  };
}

module.exports = {
  normalizeCode,
  getGlobalCouponCap,
  validateAndComputeDiscount,
};
