const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');

async function requireActiveSubscription(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId, status: 'active' },
      orderBy: { createdAt: 'desc' },
    });

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

module.exports = { requireActiveSubscription, checkSubscriptionStatus, checkOfferLimit };
