const Subscription = require('../models/Subscription');
const User = require('../models/User');

/**
 * Middleware to check if shopkeeper has valid subscription
 * Blocks access if subscription is expired or inactive
 */
async function requireActiveSubscription(req, res, next) {
  try {
    // Only check for shopkeepers
    if (req.user.role !== 'shopkeeper') {
      return next();
    }

    // Find active subscription for this shopkeeper
    const subscription = await Subscription.findOne({
      shopkeeperId: req.user.userId,
      status: 'active',
    }).lean();

    // No active subscription found
    if (!subscription) {
      return res.status(403).json({
        success: false,
        message: 'Active subscription required',
        code: 'SUBSCRIPTION_REQUIRED',
        details: {
          reason: 'No active subscription found',
          action: 'Please subscribe to a plan to continue',
        },
      });
    }

    // Check if subscription is expired
    if (subscription.endDate && new Date() > new Date(subscription.endDate)) {
      // Auto-expire the subscription
      await Subscription.findByIdAndUpdate(subscription._id, {
        status: 'expired',
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

    // Check if subscription is expiring soon (within 7 days)
    const daysUntilExpiry = Math.ceil(
      (new Date(subscription.endDate) - new Date()) / (1000 * 60 * 60 * 24)
    );

    if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
      // Add warning to response headers
      res.setHeader('X-Subscription-Warning', 'expiring-soon');
      res.setHeader('X-Days-Until-Expiry', daysUntilExpiry.toString());
    }

    // Attach subscription info to request
    req.subscription = subscription;
    next();
  } catch (error) {
    console.error('[SUBSCRIPTION_CHECK] Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to verify subscription',
    });
  }
}

/**
 * Middleware to check subscription and add info without blocking
 * Used for endpoints that should work regardless of subscription status
 */
async function checkSubscriptionStatus(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') {
      return next();
    }

    const subscription = await Subscription.findOne({
      shopkeeperId: req.user.userId,
    })
      .sort({ createdAt: -1 })
      .lean();

    req.subscription = subscription || null;
    next();
  } catch (error) {
    console.error('[SUBSCRIPTION_STATUS] Error:', error);
    req.subscription = null;
    next();
  }
}

/**
 * Check if shopkeeper can create more offers based on plan limits
 */
async function checkOfferLimit(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') {
      return next();
    }

    if (!req.subscription) {
      return res.status(403).json({
        success: false,
        message: 'Active subscription required to create offers',
        code: 'SUBSCRIPTION_REQUIRED',
      });
    }

    // Get plan details
    const planSnapshot = req.subscription.planSnapshot;
    if (!planSnapshot || !planSnapshot.maxOffers || planSnapshot.maxOffers === -1) {
      // Unlimited offers
      return next();
    }

    // Count current offers
    const Offer = require('../models/Offer');
    const offerCount = await Offer.countDocuments({
      shopkeeperId: req.user.userId,
      status: { $ne: 'deleted' },
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

module.exports = {
  requireActiveSubscription,
  checkSubscriptionStatus,
  checkOfferLimit,
};
