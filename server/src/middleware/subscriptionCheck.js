const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { getAvailableCredits } = require('../services/aiWalletService');

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isPrismaP1001(error) {
  return error && error.code === 'P1001';
}

async function requireActiveSubscription(req, res, next) {
  let lastError;
  try {
    if (req.user.role !== 'shopkeeper') return next();

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    let subscription = null;
    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        subscription = await prisma.subscription.findFirst({
          where: { shopkeeperId, status: 'active' },
          orderBy: { createdAt: 'desc' },
        });
        break;
      } catch (error) {
        lastError = error;
        if (!isPrismaP1001(error) || attempt === 3) {
          throw error;
        }
        const delay = 150 * attempt;
        console.warn(`[SUBSCRIPTION_CHECK] P1001 retry ${attempt}/3 in ${delay}ms`);
        await wait(delay);
      }
    }

    if (!subscription) {
      return res.status(403).json({
        success: false,
        message: 'Active subscription required',
        code: 'SUBSCRIPTION_REQUIRED',
        details: { reason: 'No active subscription found', action: 'Please subscribe to a plan to continue' },
      });
    }

    if (subscription.endDate && new Date() > new Date(subscription.endDate)) {
      await prisma.subscription.update({
        where: { id: subscription.id },
        data: { status: 'expired' },
      });
      return res.status(403).json({
        success: false,
        message: 'Subscription expired',
        code: 'SUBSCRIPTION_EXPIRED',
        details: {
          reason: 'Your subscription has expired',
          expiredOn: subscription.endDate,
          action: 'Please renew your subscription to continue',
        },
      });
    }

    if (subscription.endDate) {
      const daysUntilExpiry = Math.ceil(
        (new Date(subscription.endDate) - new Date()) / (1000 * 60 * 60 * 24)
      );
      if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
        res.setHeader('X-Subscription-Warning', 'expiring-soon');
        res.setHeader('X-Days-Until-Expiry', daysUntilExpiry.toString());
      }
    }

    req.subscription = subscription;
    next();
  } catch (error) {
    console.error('[SUBSCRIPTION_CHECK] Error:', error);
    if (isPrismaP1001(error || lastError)) {
      return res.status(503).json({
        success: false,
        message: 'Service temporarily unavailable. Please retry in a moment.',
        code: 'DATABASE_TEMPORARILY_UNAVAILABLE',
      });
    }
    res.status(500).json({ success: false, message: 'Failed to verify subscription' });
  }
}

async function checkSubscriptionStatus(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId },
      orderBy: { createdAt: 'desc' },
    });
    req.subscription = subscription || null;
    next();
  } catch (error) {
    console.error('[SUBSCRIPTION_STATUS] Error:', error);
    req.subscription = null;
    next();
  }
}

async function checkOfferLimit(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();
    if (!req.subscription) {
      return res.status(403).json({
        success: false,
        message: 'Active subscription required to create offers',
        code: 'SUBSCRIPTION_REQUIRED',
      });
    }
    const planSnapshot = req.subscription.planSnapshot;
    if (!planSnapshot || !planSnapshot.maxOffers || planSnapshot.maxOffers === -1) {
      return next();
    }
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const offerCount = await prisma.offer.count({
      where: { shopkeeperId, status: { not: 'inactive' } },
    });
    if (offerCount >= planSnapshot.maxOffers) {
      return res.status(403).json({
        success: false,
        message: 'Offer limit reached',
        code: 'OFFER_LIMIT_REACHED',
        details: {
          currentOffers: offerCount,
          maxOffers: planSnapshot.maxOffers,
          action: 'Upgrade your plan to create more offers',
        },
      });
    }
    next();
  } catch (error) {
    console.error('[OFFER_LIMIT_CHECK] Error:', error);
    next(error);
  }
}

async function checkAiCreditLimit(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();
    if (!req.subscription) {
      return res.status(403).json({
        success: false,
        message: 'Active subscription required',
        code: 'SUBSCRIPTION_REQUIRED',
      });
    }
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const wallet = await prisma.aiWallet.findUnique({
      where: { shopkeeperId },
    });
    const available = getAvailableCredits(wallet);
    if (available < 1) {
      return res.status(403).json({
        success: false,
        message: 'You have reached your AI banner limit. Buy AI Credit Pack.',
        code: 'AI_LIMIT_REACHED',
        details: { action: 'Purchase an AI credit pack to continue' },
      });
    }
    next();
  } catch (error) {
    console.error('[AI_CREDIT_LIMIT_CHECK] Error:', error);
    next(error);
  }
}

module.exports = { requireActiveSubscription, checkSubscriptionStatus, checkOfferLimit, checkAiCreditLimit };
