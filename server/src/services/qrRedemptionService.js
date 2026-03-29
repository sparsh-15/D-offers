const { prisma } = require('../db/prisma');
const { normalizeCode } = require('./couponValidationService');

const VERIFICATION_METHODS = new Set(['qr', 'manual']);

function ci(value) {
  return String(value || '').trim();
}

function parseMethod(value) {
  const normalized = ci(value).toLowerCase();
  if (VERIFICATION_METHODS.has(normalized)) return normalized;
  return 'qr';
}

function createFailure(result, message, reason) {
  return {
    success: false,
    result,
    message,
    reason: reason || message,
  };
}

async function logScanAttempt({
  attemptedCode,
  normalizedCode,
  couponId = null,
  offerId = null,
  actorUserId,
  verificationMethod,
  result,
  reason = null,
  idempotencyKey = null,
  ipAddress = null,
}) {
  try {
    await prisma.couponScanAttempt.create({
      data: {
        attemptedCode: ci(attemptedCode),
        normalizedCode: normalizedCode || null,
        couponId,
        offerId,
        actorUserId,
        verificationMethod: parseMethod(verificationMethod),
        result,
        reason,
        idempotencyKey,
        ipAddress,
      },
    });
  } catch (error) {
    console.error('[QR_REDEMPTION] Failed to write scan attempt log', error);
  }
}

async function evaluateCouponAndOffer({ couponCode, offerId }) {
  const normalizedCode = normalizeCode(couponCode);
  if (!normalizedCode) {
    return createFailure('invalid', 'Coupon code is required', 'missing_coupon_code');
  }

  const offer = await prisma.offer.findUnique({
    where: { id: offerId },
    select: {
      id: true,
      shopkeeperId: true,
      title: true,
      status: true,
      validTo: true,
      discountType: true,
      discountValue: true,
    },
  });

  if (!offer) {
    return createFailure('offer_not_found', 'Offer not found', 'Offer does not exist');
  }

  if (offer.status !== 'active') {
    return createFailure('invalid', 'Offer is not active', 'Offer is not active');
  }

  const now = new Date();
  if (offer.validTo && new Date(offer.validTo) <= now) {
    return createFailure('expired', 'Offer has expired', 'Offer validity has ended');
  }

  const coupon = await prisma.coupon.findFirst({
    where: { code: normalizedCode },
    select: {
      id: true,
      code: true,
      discountType: true,
      discountValue: true,
      isActive: true,
      expiryDate: true,
      maxUses: true,
      currentUses: true,
      agentId: true,
    },
  });

  if (!coupon) {
    return createFailure('coupon_not_found', 'Coupon not found', 'Coupon does not exist');
  }

  if (!coupon.isActive) {
    return createFailure('invalid', 'Coupon is inactive', 'Coupon is inactive');
  }

  if (coupon.expiryDate && new Date(coupon.expiryDate) <= now) {
    return createFailure('expired', 'Coupon has expired', 'Coupon validity has ended');
  }

  if (coupon.maxUses != null && coupon.currentUses >= coupon.maxUses) {
    return createFailure(
      'usage_limit_reached',
      'Coupon usage limit reached',
      'Coupon has already reached its max uses',
    );
  }

  const existingRedemption = await prisma.couponRedemption.findUnique({
    where: {
      couponId_offerId: {
        couponId: coupon.id,
        offerId: offer.id,
      },
    },
    select: {
      id: true,
      status: true,
      redeemedAt: true,
      redeemedByUserId: true,
    },
  });

  if (existingRedemption) {
    return {
      ...createFailure('already_redeemed', 'Coupon already redeemed for this offer', 'Coupon has already been redeemed'),
      coupon,
      offer,
      existingRedemption,
    };
  }

  return {
    success: true,
    result: 'verified',
    coupon,
    offer,
  };
}

function serializeVerificationPayload(payload) {
  return {
    coupon: {
      id: payload.coupon.id,
      code: payload.coupon.code,
      discountType: payload.coupon.discountType,
      discountValue: Number(payload.coupon.discountValue || 0),
      expiryDate: payload.coupon.expiryDate,
      maxUses: payload.coupon.maxUses,
      currentUses: payload.coupon.currentUses,
    },
    offer: {
      id: payload.offer.id,
      title: payload.offer.title,
      shopkeeperId: payload.offer.shopkeeperId,
      discountType: payload.offer.discountType,
      discountValue: Number(payload.offer.discountValue || 0),
      validTo: payload.offer.validTo,
    },
  };
}

async function verifyCouponRedemption({
  couponCode,
  offerId,
  actorUserId,
  verificationMethod,
  ipAddress,
}) {
  const method = parseMethod(verificationMethod);
  const normalizedCode = normalizeCode(couponCode);
  const evaluation = await evaluateCouponAndOffer({ couponCode, offerId });

  if (!evaluation.success) {
    await logScanAttempt({
      attemptedCode: couponCode,
      normalizedCode,
      couponId: evaluation.coupon?.id || null,
      offerId: evaluation.offer?.id || offerId || null,
      actorUserId,
      verificationMethod: method,
      result: evaluation.result,
      reason: evaluation.reason,
      ipAddress,
    });

    return evaluation;
  }

  await logScanAttempt({
    attemptedCode: couponCode,
    normalizedCode,
    couponId: evaluation.coupon.id,
    offerId: evaluation.offer.id,
    actorUserId,
    verificationMethod: method,
    result: 'verified',
    reason: 'Coupon verification successful',
    ipAddress,
  });

  return {
    success: true,
    result: 'verified',
    ...serializeVerificationPayload(evaluation),
  };
}

async function redeemCoupon({
  couponCode,
  offerId,
  actorUserId,
  verificationMethod,
  idempotencyKey,
  ipAddress,
}) {
  const method = parseMethod(verificationMethod);
  const normalizedCode = normalizeCode(couponCode);

  if (idempotencyKey) {
    const existingByKey = await prisma.couponRedemption.findUnique({
      where: { idempotencyKey },
      include: {
        coupon: true,
        offer: true,
      },
    });

    if (existingByKey) {
      return {
        success: true,
        result: 'redeemed',
        idempotentReplay: true,
        redemption: {
          id: existingByKey.id,
          couponId: existingByKey.couponId,
          offerId: existingByKey.offerId,
          redeemedByUserId: existingByKey.redeemedByUserId,
          verificationMethod: existingByKey.verificationMethod,
          status: existingByKey.status,
          redeemedAt: existingByKey.redeemedAt,
        },
      };
    }
  }

  const evaluation = await evaluateCouponAndOffer({ couponCode, offerId });
  if (!evaluation.success) {
    await logScanAttempt({
      attemptedCode: couponCode,
      normalizedCode,
      couponId: evaluation.coupon?.id || null,
      offerId: evaluation.offer?.id || offerId || null,
      actorUserId,
      verificationMethod: method,
      result: evaluation.result,
      reason: evaluation.reason,
      idempotencyKey,
      ipAddress,
    });

    return evaluation;
  }

  const redemption = await prisma.$transaction(async (tx) => {
    const created = await tx.couponRedemption.create({
      data: {
        couponId: evaluation.coupon.id,
        offerId: evaluation.offer.id,
        redeemedByUserId: actorUserId,
        verificationMethod: method,
        status: 'redeemed',
        idempotencyKey: idempotencyKey || null,
        metadata: {
          source: 'business-redemption-api',
        },
      },
    });

    await tx.coupon.update({
      where: { id: evaluation.coupon.id },
      data: {
        currentUses: {
          increment: 1,
        },
      },
    });

    await tx.customerOfferClaim.updateMany({
      where: {
        couponId: evaluation.coupon.id,
        status: 'active',
      },
      data: {
        status: 'redeemed',
        redeemedAt: new Date(),
      },
    });

    return created;
  });

  await logScanAttempt({
    attemptedCode: couponCode,
    normalizedCode,
    couponId: evaluation.coupon.id,
    offerId: evaluation.offer.id,
    actorUserId,
    verificationMethod: method,
    result: 'verified',
    reason: 'Coupon redeemed successfully',
    idempotencyKey,
    ipAddress,
  });

  return {
    success: true,
    result: 'redeemed',
    idempotentReplay: false,
    redemption: {
      id: redemption.id,
      couponId: redemption.couponId,
      offerId: redemption.offerId,
      redeemedByUserId: redemption.redeemedByUserId,
      verificationMethod: redemption.verificationMethod,
      status: redemption.status,
      redeemedAt: redemption.redeemedAt,
    },
    verification: serializeVerificationPayload(evaluation),
  };
}

async function getRedemptionHistory({ actorUserId, role, limit, offset, offerId }) {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safeOffset = Math.max(Number(offset) || 0, 0);

  const where = {};
  if (!['super_admin', 'subadmin'].includes(role)) {
    where.redeemedByUserId = actorUserId;
  }

  if (offerId) {
    where.offerId = offerId;
  }

  const [rows, total] = await Promise.all([
    prisma.couponRedemption.findMany({
      where,
      include: {
        coupon: {
          select: {
            id: true,
            code: true,
            discountType: true,
            discountValue: true,
          },
        },
        offer: {
          select: {
            id: true,
            title: true,
            shopkeeperId: true,
          },
        },
        redeemedByUser: {
          select: {
            id: true,
            name: true,
            phone: true,
            role: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      skip: safeOffset,
      take: safeLimit,
    }),
    prisma.couponRedemption.count({ where }),
  ]);

  return {
    items: rows.map((row) => ({
      id: row.id,
      status: row.status,
      verificationMethod: row.verificationMethod,
      redeemedAt: row.redeemedAt,
      coupon: {
        id: row.coupon.id,
        code: row.coupon.code,
        discountType: row.coupon.discountType,
        discountValue: Number(row.coupon.discountValue || 0),
      },
      offer: {
        id: row.offer.id,
        title: row.offer.title,
        shopkeeperId: row.offer.shopkeeperId,
      },
      redeemedBy: {
        id: row.redeemedByUser.id,
        name: row.redeemedByUser.name,
        phone: row.redeemedByUser.phone,
        role: row.redeemedByUser.role,
      },
    })),
    pageInfo: {
      offset: safeOffset,
      limit: safeLimit,
      total,
      hasMore: safeOffset + rows.length < total,
      nextOffset: safeOffset + rows.length < total ? safeOffset + rows.length : null,
    },
  };
}

module.exports = {
  parseMethod,
  verifyCouponRedemption,
  redeemCoupon,
  getRedemptionHistory,
};
