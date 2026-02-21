const User = require('../models/User');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');
const Subscription = require('../models/Subscription');
const Offer = require('../models/Offer');

/**
 * Get SSA (Sub Sales Agent) list with statistics
 */
async function getSSAList(req, res, next) {
  try {
    const { page = 1, limit = 20, search, isActive } = req.query;

    const filter = { role: 'ssa' };
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [ssaUsers, total] = await Promise.all([
      User.find(filter)
        .select('name phone pincode city isActive createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      User.countDocuments(filter),
    ]);

    // Get onboarding count for each SSA
    const ssaWithStats = await Promise.all(
      ssaUsers.map(async (ssa) => {
        // Count shopkeepers onboarded by this SSA (stored in shopkeeper's metadata)
        const onboardingCount = await ShopkeeperProfile.countDocuments({
          onboardedBy: ssa._id,
        });

        return {
          ...ssa,
          onboardingCount,
        };
      })
    );

    res.json({
      success: true,
      data: {
        ssaList: ssaWithStats,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] getSSAList error:', err);
    next(err);
  }
}

/**
 * Get Company Sales Agent list with statistics
 */
async function getCompanySalesAgentList(req, res, next) {
  try {
    const { page = 1, limit = 20, search, isActive } = req.query;

    const filter = { role: 'company_sales_agent' };
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [csaUsers, total] = await Promise.all([
      User.find(filter)
        .select('name phone pincode city isActive createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      User.countDocuments(filter),
    ]);

    // Get onboarding count for each CSA
    const csaWithStats = await Promise.all(
      csaUsers.map(async (csa) => {
        const onboardingCount = await ShopkeeperProfile.countDocuments({
          onboardedBy: csa._id,
        });

        return {
          ...csa,
          onboardingCount,
        };
      })
    );

    res.json({
      success: true,
      data: {
        csaList: csaWithStats,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] getCompanySalesAgentList error:', err);
    next(err);
  }
}

/**
 * Get coupon activation tracking
 */
async function getCouponActivations(req, res, next) {
  try {
    const { page = 1, limit = 20, startDate, endDate, couponCode } = req.query;

    const filter = {};
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }
    if (couponCode) {
      filter.couponCode = { $regex: couponCode, $options: 'i' };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get subscriptions with coupon codes
    const [subscriptions, total] = await Promise.all([
      Subscription.find({ ...filter, couponCode: { $exists: true, $ne: null } })
        .populate('shopkeeperId', 'name phone')
        .populate('planId', 'displayName monthlyPrice')
        .select('shopkeeperId planId couponCode discountAmount actualPrice createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Subscription.countDocuments({ ...filter, couponCode: { $exists: true, $ne: null } }),
    ]);

    // Calculate total discount distributed
    const totalDiscountResult = await Subscription.aggregate([
      {
        $match: {
          couponCode: { $exists: true, $ne: null },
          ...(startDate || endDate ? { createdAt: filter.createdAt } : {}),
        },
      },
      {
        $group: {
          _id: null,
          totalDiscount: { $sum: '$discountAmount' },
          totalActivations: { $sum: 1 },
        },
      },
    ]);

    const totalDiscount = totalDiscountResult[0]?.totalDiscount || 0;
    const totalActivations = totalDiscountResult[0]?.totalActivations || 0;

    res.json({
      success: true,
      data: {
        activations: subscriptions,
        summary: {
          totalDiscount,
          totalActivations,
        },
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] getCouponActivations error:', err);
    next(err);
  }
}

/**
 * Get agent governance dashboard overview
 */
async function getAgentGovernanceDashboard(req, res, next) {
  try {
    // Count SSAs
    const [totalSSA, activeSSA] = await Promise.all([
      User.countDocuments({ role: 'ssa' }),
      User.countDocuments({ role: 'ssa', isActive: true }),
    ]);

    // Count Company Sales Agents
    const [totalCSA, activeCSA] = await Promise.all([
      User.countDocuments({ role: 'company_sales_agent' }),
      User.countDocuments({ role: 'company_sales_agent', isActive: true }),
    ]);

    // Total onboarding count
    const totalOnboardings = await ShopkeeperProfile.countDocuments({
      onboardedBy: { $exists: true, $ne: null },
    });

    // Coupon statistics
    const couponStats = await Subscription.aggregate([
      {
        $match: {
          couponCode: { $exists: true, $ne: null },
        },
      },
      {
        $group: {
          _id: null,
          totalActivations: { $sum: 1 },
          totalDiscount: { $sum: '$discountAmount' },
        },
      },
    ]);

    const totalCouponActivations = couponStats[0]?.totalActivations || 0;
    const totalDiscountDistributed = couponStats[0]?.totalDiscount || 0;

    // Top performing agents (by onboarding count)
    const topSSA = await ShopkeeperProfile.aggregate([
      {
        $match: {
          onboardedBy: { $exists: true, $ne: null },
        },
      },
      {
        $group: {
          _id: '$onboardedBy',
          onboardingCount: { $sum: 1 },
        },
      },
      {
        $sort: { onboardingCount: -1 },
      },
      {
        $limit: 5,
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'agent',
        },
      },
      {
        $unwind: '$agent',
      },
      {
        $project: {
          agentId: '$_id',
          agentName: '$agent.name',
          agentPhone: '$agent.phone',
          agentRole: '$agent.role',
          onboardingCount: 1,
        },
      },
    ]);

    res.json({
      success: true,
      data: {
        ssa: {
          total: totalSSA,
          active: activeSSA,
          inactive: totalSSA - activeSSA,
        },
        csa: {
          total: totalCSA,
          active: activeCSA,
          inactive: totalCSA - activeCSA,
        },
        onboarding: {
          total: totalOnboardings,
        },
        coupons: {
          totalActivations: totalCouponActivations,
          totalDiscountDistributed,
        },
        topPerformers: topSSA,
      },
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] getAgentGovernanceDashboard error:', err);
    next(err);
  }
}

module.exports = {
  getSSAList,
  getCompanySalesAgentList,
  getCouponActivations,
  getAgentGovernanceDashboard,
};
