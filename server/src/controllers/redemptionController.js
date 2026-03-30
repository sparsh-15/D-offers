const { resolvePgId } = require('../repositories/idResolver');
const {
  verifyCouponRedemption,
  redeemCoupon,
  getRedemptionHistory,
} = require('../services/qrRedemptionService');
const rewardService = require('../services/rewardService');

function ci(value) {
  return String(value || '').trim();
}

function getClientIp(req) {
  const forwardedFor = req.headers['x-forwarded-for'];
  if (typeof forwardedFor === 'string' && forwardedFor.trim()) {
    return forwardedFor.split(',')[0].trim();
  }
  return req.ip || req.connection?.remoteAddress || null;
}

function mapStatusCode(result) {
  switch (result) {
    case 'offer_not_found':
    case 'coupon_not_found':
      return 404;
    case 'already_redeemed':
      return 409;
    case 'usage_limit_reached':
      return 409;
    case 'invalid':
    case 'expired':
      return 400;
    default:
      return 400;
  }
}

async function runVerify(req, res, next, method) {
  try {
    const couponCode = ci(req.body?.couponCode);
    const offerIdInput = ci(req.body?.offerId);

    if (!couponCode) {
      return res.status(400).json({ success: false, message: 'couponCode is required' });
    }

    if (!offerIdInput) {
      return res.status(400).json({ success: false, message: 'offerId is required' });
    }

    const actorUserId = await resolvePgId('users', req.user.userId);
    const offerId = await resolvePgId('offers', offerIdInput);

    if (!actorUserId) {
      return res.status(401).json({ success: false, message: 'Invalid authenticated user' });
    }

    if (!offerId) {
      return res.status(400).json({ success: false, message: 'Invalid offerId' });
    }

    const result = await verifyCouponRedemption({
      couponCode,
      offerId,
      actorUserId,
      verificationMethod: method,
      ipAddress: getClientIp(req),
    });

    if (!result.success) {
      return res.status(mapStatusCode(result.result)).json({
        success: false,
        message: result.message,
        result: result.result,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Coupon verification successful',
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

async function verify(req, res, next) {
  return runVerify(req, res, next, 'qr');
}

async function manualVerify(req, res, next) {
  return runVerify(req, res, next, 'manual');
}

async function redeem(req, res, next) {
  try {
    const couponCode = ci(req.body?.couponCode);
    const offerIdInput = ci(req.body?.offerId);

    if (!couponCode) {
      return res.status(400).json({ success: false, message: 'couponCode is required' });
    }

    if (!offerIdInput) {
      return res.status(400).json({ success: false, message: 'offerId is required' });
    }

    const actorUserId = await resolvePgId('users', req.user.userId);
    const offerId = await resolvePgId('offers', offerIdInput);

    if (!actorUserId) {
      return res.status(401).json({ success: false, message: 'Invalid authenticated user' });
    }

    if (!offerId) {
      return res.status(400).json({ success: false, message: 'Invalid offerId' });
    }

    const idempotencyKey = ci(req.headers['x-idempotency-key']) || null;
    const verificationMethod = ci(req.body?.verificationMethod) || 'qr';

    const result = await redeemCoupon({
      couponCode,
      offerId,
      actorUserId,
      verificationMethod,
      idempotencyKey,
      ipAddress: getClientIp(req),
    });

    if (!result.success) {
      return res.status(mapStatusCode(result.result)).json({
        success: false,
        message: result.message,
        result: result.result,
      });
    }

    // Award coins to shopkeeper (sale_closed)
    if (!result.idempotentReplay) {
      try {
        await rewardService.awardReward({
          userId: req.user.userId,
          userRole: req.user.role,
          userRoles: req.user.roles,
          actionType: 'sale_closed',
          sourceRef: result.redemption.id,
          idempotencyKey: ci(req.headers['x-idempotency-key']) || null,
          metadata: {
            redemptionId: result.redemption.id,
            offerId: result.redemption.offerId,
            couponId: result.redemption.couponId,
          },
        });
      } catch (rewardErr) {
        console.error('[REDEMPTION] Failed to award shopkeeper coins:', rewardErr);
      }

      // Award coins to all customers who claimed this coupon (purchase_success)
      if (result.redemption.customerIds && result.redemption.customerIds.length > 0) {
        for (const customerId of result.redemption.customerIds) {
          try {
            await rewardService.awardReward({
              userId: customerId,
              userRole: 'customer',
              userRoles: ['customer'],
              actionType: 'purchase_success',
              sourceRef: result.redemption.id,
              idempotencyKey: null,
              metadata: {
                redemptionId: result.redemption.id,
                offerId: result.redemption.offerId,
                couponId: result.redemption.couponId,
                awardedFrom: 'sale_redemption',
              },
            });
          } catch (rewardErr) {
            console.error('[REDEMPTION] Failed to award customer coins:', rewardErr);
          }
        }
      }
    }

    return res.status(200).json({
      success: true,
      message: result.idempotentReplay
        ? 'Redemption already processed for this idempotency key'
        : 'Coupon redeemed successfully',
      data: result,
    });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(409).json({
        success: false,
        message: 'Coupon already redeemed for this offer',
        result: 'already_redeemed',
      });
    }
    next(error);
  }
}

async function history(req, res, next) {
  try {
    const actorUserId = await resolvePgId('users', req.user.userId);
    if (!actorUserId) {
      return res.status(401).json({ success: false, message: 'Invalid authenticated user' });
    }

    const offerIdInput = ci(req.query.offerId);
    const offerId = offerIdInput ? await resolvePgId('offers', offerIdInput) : null;
    if (offerIdInput && !offerId) {
      return res.status(400).json({ success: false, message: 'Invalid offerId filter' });
    }

    const historyResult = await getRedemptionHistory({
      actorUserId,
      role: req.user.role,
      limit: req.query.limit,
      offset: req.query.offset,
      offerId,
    });

    return res.status(200).json({
      success: true,
      redemptions: historyResult.items,
      pageInfo: historyResult.pageInfo,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  verify,
  manualVerify,
  redeem,
  history,
};
