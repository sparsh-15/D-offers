const Subscription = require('../models/Subscription');
const SubscriptionPlan = require('../models/SubscriptionPlan');
const User = require('../models/User');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');
const { logAdminAction } = require('../middleware/roleAuth');

/**
 * Create subscription for a shopkeeper
 */
async function createSubscription(req, res, next) {
  try {
    const {
      shopkeeperId,
      planId,
      startDate,
      durationMonths = 1,
      autoRenew = false,
      paymentMethod,
      transactionId,
      notes,
    } = req.body;

    // Validate required fields
    if (!shopkeeperId || !planId) {
      return res.status(400).json({
        success: false,
        message: 'Shopkeeper ID and Plan ID are required',
      });
    }

    // Verify shopkeeper exists
    const shopkeeper = await User.findById(shopkeeperId);
    if (!shopkeeper || shopkeeper.role !== 'shopkeeper') {
      return res.status(404).json({
        success: false,
        message: 'Shopkeeper not found',
      });
    }

    // Verify plan exists and is active
    const plan = await SubscriptionPlan.findById(planId);
    if (!plan) {
      return res.status(404).json({
        success: false,
        message: 'Subscription plan not found',
      });
    }

    if (!plan.isActive) {
      return res.status(400).json({
        success: false,
        message: 'This plan is no longer available',
      });
    }

    // Calculate dates
    const start = startDate ? new Date(startDate) : new Date();
    const end = new Date(start);
    end.setMonth(end.getMonth() + durationMonths);

    // Create subscription
    const subscription = await Subscription.create({
      shopkeeperId,
      planId,
      planSnapshot: {
        name: plan.name,
        displayName: plan.displayName,
        monthlyPrice: plan.monthlyPrice,
        features: plan.features,
        maxOffers: plan.maxOffers,
        maxPhotosPerOffer: plan.maxPhotosPerOffer,
      },
      status: 'active',
      startDate: start,
      endDate: end,
      actualPrice: plan.monthlyPrice * durationMonths,
      autoRenew,
      paymentStatus: 'paid',
      paymentMethod,
      transactionId,
      notes,
    });

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_created',
      shopkeeperId,
      'shopkeeper',
      {
        subscriptionId: subscription._id,
        planName: plan.name,
        duration: durationMonths,
      },
      req.ip
    );

    res.status(201).json({
      success: true,
      message: 'Subscription created successfully',
      data: subscription,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] createSubscription error:', err);
    next(err);
  }
}

/**
 * Get subscription monitoring dashboard
 */
async function getMonitoringDashboard(req, res, next) {
  try {
    const now = new Date();
    const sevenDaysFromNow = new Date(now);
    sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

    // Get subscription counts by status
    const statusCounts = await Subscription.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalRevenue: { $sum: '$actualPrice' },
        },
      },
    ]);

    // Get subscriptions expiring soon
    const expiringSoon = await Subscription.find({
      status: 'active',
      endDate: {
        $gte: now,
        $lte: sevenDaysFromNow,
      },
    })
      .populate('shopkeeperId', 'name phone')
      .populate('planId', 'displayName monthlyPrice')
      .sort({ endDate: 1 })
      .lean();

    // Get recently expired subscriptions (last 7 days)
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recentlyExpired = await Subscription.find({
      status: 'expired',
      endDate: {
        $gte: sevenDaysAgo,
        $lte: now,
      },
    })
      .populate('shopkeeperId', 'name phone')
      .populate('planId', 'displayName monthlyPrice')
      .sort({ endDate: -1 })
      .lean();

    // Get pending subscriptions
    const pending = await Subscription.find({
      status: 'pending',
    })
      .populate('shopkeeperId', 'name phone')
      .populate('planId', 'displayName monthlyPrice')
      .sort({ createdAt: -1 })
      .lean();

    // Calculate MRR (Monthly Recurring Revenue)
    const activeSubscriptions = await Subscription.find({
      status: 'active',
    })
      .populate('planId', 'monthlyPrice')
      .lean();

    const mrr = activeSubscriptions.reduce((sum, sub) => {
      return sum + (sub.planSnapshot?.monthlyPrice || 0);
    }, 0);

    res.json({
      success: true,
      data: {
        statusCounts: statusCounts.reduce((acc, item) => {
          acc[item._id] = {
            count: item.count,
            revenue: item.totalRevenue,
          };
          return acc;
        }, {}),
        expiringSoon: {
          count: expiringSoon.length,
          subscriptions: expiringSoon,
        },
        recentlyExpired: {
          count: recentlyExpired.length,
          subscriptions: recentlyExpired,
        },
        pending: {
          count: pending.length,
          subscriptions: pending,
        },
        mrr,
      },
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] getMonitoringDashboard error:', err);
    next(err);
  }
}

/**
 * Get revenue intelligence and analytics
 */
async function getRevenueIntelligence(req, res, next) {
  try {
    const now = new Date();

    // Get current month MRR
    const currentMRR = await Subscription.aggregate([
      {
        $match: {
          status: 'active',
        },
      },
      {
        $lookup: {
          from: 'subscriptionplans',
          localField: 'planId',
          foreignField: '_id',
          as: 'plan',
        },
      },
      {
        $unwind: '$plan',
      },
      {
        $group: {
          _id: null,
          totalMRR: { $sum: '$plan.monthlyPrice' },
          count: { $sum: 1 },
        },
      },
    ]);

    // Get subscription growth trend (last 6 months)
    const sixMonthsAgo = new Date(now);
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const growthTrend = await Subscription.aggregate([
      {
        $match: {
          createdAt: { $gte: sixMonthsAgo },
        },
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
          },
          newSubscriptions: { $sum: 1 },
          revenue: { $sum: '$actualPrice' },
        },
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 },
      },
    ]);

    // Get churn analysis (last 3 months)
    const threeMonthsAgo = new Date(now);
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const churnData = await Subscription.aggregate([
      {
        $match: {
          status: { $in: ['expired', 'cancelled'] },
          updatedAt: { $gte: threeMonthsAgo },
        },
      },
      {
        $group: {
          _id: {
            year: { $year: '$updatedAt' },
            month: { $month: '$updatedAt' },
            status: '$status',
          },
          count: { $sum: 1 },
        },
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 },
      },
    ]);

    // Calculate projected MRR (next month)
    const nextMonthStart = new Date(now);
    nextMonthStart.setMonth(nextMonthStart.getMonth() + 1);
    nextMonthStart.setDate(1);

    const nextMonthEnd = new Date(nextMonthStart);
    nextMonthEnd.setMonth(nextMonthEnd.getMonth() + 1);

    const expiringNextMonth = await Subscription.countDocuments({
      status: 'active',
      endDate: {
        $gte: nextMonthStart,
        $lt: nextMonthEnd,
      },
      autoRenew: false,
    });

    const projectedMRR =
      (currentMRR[0]?.totalMRR || 0) -
      expiringNextMonth * (currentMRR[0]?.totalMRR || 0) / (currentMRR[0]?.count || 1);

    // Detect unusual drops (more than 20% drop in new subscriptions)
    const lastMonthSubs = growthTrend[growthTrend.length - 1]?.newSubscriptions || 0;
    const prevMonthSubs = growthTrend[growthTrend.length - 2]?.newSubscriptions || 0;
    const dropPercentage =
      prevMonthSubs > 0 ? ((prevMonthSubs - lastMonthSubs) / prevMonthSubs) * 100 : 0;

    const unusualDrop = dropPercentage > 20;

    // Get plan distribution
    const planDistribution = await Subscription.aggregate([
      {
        $match: {
          status: 'active',
        },
      },
      {
        $lookup: {
          from: 'subscriptionplans',
          localField: 'planId',
          foreignField: '_id',
          as: 'plan',
        },
      },
      {
        $unwind: '$plan',
      },
      {
        $group: {
          _id: '$plan.displayName',
          count: { $sum: 1 },
          revenue: { $sum: '$plan.monthlyPrice' },
        },
      },
      {
        $sort: { count: -1 },
      },
    ]);

    res.json({
      success: true,
      data: {
        currentMRR: currentMRR[0]?.totalMRR || 0,
        activeSubscriptions: currentMRR[0]?.count || 0,
        projectedMRR: Math.max(0, projectedMRR),
        growthTrend,
        churnData,
        planDistribution,
        alerts: {
          unusualDrop,
          dropPercentage: unusualDrop ? dropPercentage.toFixed(2) : 0,
          expiringNextMonth,
        },
      },
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] getRevenueIntelligence error:', err);
    next(err);
  }
}

/**
 * Get all subscriptions with filters
 */
async function getAllSubscriptions(req, res, next) {
  try {
    const {
      status,
      planId,
      shopkeeperId,
      expiringSoon,
      page = 1,
      limit = 20,
    } = req.query;

    const filter = {};
    if (status) filter.status = status;
    if (planId) filter.planId = planId;
    if (shopkeeperId) filter.shopkeeperId = shopkeeperId;

    if (expiringSoon === 'true') {
      const now = new Date();
      const sevenDaysFromNow = new Date(now);
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
      filter.status = 'active';
      filter.endDate = { $gte: now, $lte: sevenDaysFromNow };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [subscriptions, total] = await Promise.all([
      Subscription.find(filter)
        .populate('shopkeeperId', 'name phone')
        .populate('planId', 'displayName monthlyPrice')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Subscription.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        subscriptions,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] getAllSubscriptions error:', err);
    next(err);
  }
}

/**
 * Update subscription
 */
async function updateSubscription(req, res, next) {
  try {
    const { subscriptionId } = req.params;
    const { status, endDate, autoRenew, notes } = req.body;

    const subscription = await Subscription.findById(subscriptionId);
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Subscription not found',
      });
    }

    // Update fields
    if (status !== undefined) subscription.status = status;
    if (endDate !== undefined) subscription.endDate = new Date(endDate);
    if (autoRenew !== undefined) subscription.autoRenew = autoRenew;
    if (notes !== undefined) subscription.notes = notes;

    await subscription.save();

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_updated',
      subscription.shopkeeperId,
      'shopkeeper',
      {
        subscriptionId: subscription._id,
        changes: { status, endDate, autoRenew },
      },
      req.ip
    );

    res.json({
      success: true,
      message: 'Subscription updated successfully',
      data: subscription,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] updateSubscription error:', err);
    next(err);
  }
}

/**
 * Cancel subscription
 */
async function cancelSubscription(req, res, next) {
  try {
    const { subscriptionId } = req.params;
    const { reason } = req.body;

    const subscription = await Subscription.findById(subscriptionId);
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Subscription not found',
      });
    }

    subscription.status = 'cancelled';
    subscription.cancelledAt = new Date();
    subscription.cancelledBy = req.user.userId;
    subscription.cancellationReason = reason || '';
    await subscription.save();

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_cancelled',
      subscription.shopkeeperId,
      'shopkeeper',
      {
        subscriptionId: subscription._id,
        reason,
      },
      req.ip
    );

    res.json({
      success: true,
      message: 'Subscription cancelled successfully',
      data: subscription,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] cancelSubscription error:', err);
    next(err);
  }
}

/**
 * Renew subscription
 */
async function renewSubscription(req, res, next) {
  try {
    const { subscriptionId } = req.params;
    const { durationMonths = 1, paymentMethod, transactionId } = req.body;

    const subscription = await Subscription.findById(subscriptionId).populate('planId');
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Subscription not found',
      });
    }

    // Calculate new end date
    const newEndDate = new Date(subscription.endDate || new Date());
    newEndDate.setMonth(newEndDate.getMonth() + durationMonths);

    subscription.status = 'active';
    subscription.endDate = newEndDate;
    subscription.renewalCount += 1;
    subscription.lastRenewalDate = new Date();
    subscription.paymentStatus = 'paid';
    subscription.paymentMethod = paymentMethod;
    subscription.transactionId = transactionId;

    await subscription.save();

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_renewed',
      subscription.shopkeeperId,
      'shopkeeper',
      {
        subscriptionId: subscription._id,
        duration: durationMonths,
        newEndDate,
      },
      req.ip
    );

    res.json({
      success: true,
      message: 'Subscription renewed successfully',
      data: subscription,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] renewSubscription error:', err);
    next(err);
  }
}

/**
 * Run subscription expiry check (cron job endpoint)
 */
async function runExpiryCheck(req, res, next) {
  try {
    const result = await Subscription.expireOldSubscriptions();

    res.json({
      success: true,
      message: 'Expiry check completed',
      data: {
        modifiedCount: result.modifiedCount,
      },
    });
  } catch (err) {
    console.error('[SUBSCRIPTION] runExpiryCheck error:', err);
    next(err);
  }
}

module.exports = {
  createSubscription,
  getMonitoringDashboard,
  getRevenueIntelligence,
  getAllSubscriptions,
  updateSubscription,
  cancelSubscription,
  renewSubscription,
  runExpiryCheck,
};
