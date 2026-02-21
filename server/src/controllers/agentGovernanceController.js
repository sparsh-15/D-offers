const User = require('../models/User');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');
const Subscription = require('../models/Subscription');
const Offer = require('../models/Offer');
const Coupon = require('../models/Coupon');

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
 * Get coupon list
 */
async function getCouponList(req, res, next) {
  try {
    const { page = 1, limit = 20, search, isActive } = req.query;

    const filter = {};
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (search) {
      filter.code = { $regex: search, $options: 'i' };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [coupons, total] = await Promise.all([
      Coupon.find(filter)
        .populate('agentId', 'name phone role')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Coupon.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        coupons,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] getCouponList error:', err);
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

/**
 * Create a new SSA (State Sales Agent)
 */
async function createSSA(req, res, next) {
  try {
    const { name, email, phone, password, state, region, pincode } = req.body;

    // Validate required fields
    if (!name || !email || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, phone, and password are required',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { phone }],
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email or phone already exists',
      });
    }

    // Create SSA user (password stored as-is for now, can add hashing later)
    const ssaUser = await User.create({
      name,
      email,
      phone,
      password, // Store password directly
      role: 'ssa',
      state,
      region,
      pincode,
      isActive: true,
    });

    // Remove password from response
    const ssaResponse = ssaUser.toObject();
    delete ssaResponse.password;

    res.status(201).json({
      success: true,
      message: 'SSA created successfully',
      data: ssaResponse,
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] createSSA error:', err);
    next(err);
  }
}

/**
 * Create a new Company Sales Agent
 */
async function createCompanySalesAgent(req, res, next) {
  try {
    const { name, email, phone, password, region, territory, pincode } = req.body;

    // Validate required fields
    if (!name || !email || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, phone, and password are required',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { phone }],
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email or phone already exists',
      });
    }

    // Create Company Sales Agent user (password stored as-is for now)
    const csaUser = await User.create({
      name,
      email,
      phone,
      password, // Store password directly
      role: 'company_sales_agent',
      region,
      territory,
      pincode,
      isActive: true,
    });

    // Remove password from response
    const csaResponse = csaUser.toObject();
    delete csaResponse.password;

    res.status(201).json({
      success: true,
      message: 'Company Sales Agent created successfully',
      data: csaResponse,
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] createCompanySalesAgent error:', err);
    next(err);
  }
}

/**
 * Create a new coupon
 */
async function createCoupon(req, res, next) {
  try {
    const {
      code,
      discountType,
      discountValue,
      agentId,
      description,
      expiryDate,
      maxUses,
    } = req.body;

    // Validate required fields
    if (!code || !discountType || !discountValue || !agentId) {
      return res.status(400).json({
        success: false,
        message: 'Code, discount type, discount value, and agent ID are required',
      });
    }

    // Validate discount type
    if (!['percentage', 'fixed'].includes(discountType)) {
      return res.status(400).json({
        success: false,
        message: 'Discount type must be either "percentage" or "fixed"',
      });
    }

    // Validate discount value
    if (discountType === 'percentage' && (discountValue < 0 || discountValue > 100)) {
      return res.status(400).json({
        success: false,
        message: 'Percentage discount must be between 0 and 100',
      });
    }

    // Check if agent exists
    const agent = await User.findById(agentId);
    if (!agent || !['ssa', 'company_sales_agent'].includes(agent.role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid agent ID or agent is not SSA/Company Sales Agent',
      });
    }

    // Check if coupon code already exists
    const existingCoupon = await Coupon.findOne({ code: code.toUpperCase() });
    if (existingCoupon) {
      return res.status(400).json({
        success: false,
        message: 'Coupon code already exists',
      });
    }

    // Create coupon
    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      discountType,
      discountValue,
      agentId,
      description,
      expiryDate: expiryDate ? new Date(expiryDate) : null,
      maxUses,
    });

    // Populate agent details
    await coupon.populate('agentId', 'name phone role');

    res.status(201).json({
      success: true,
      message: 'Coupon created successfully',
      data: coupon,
    });
  } catch (err) {
    console.error('[AGENT_GOVERNANCE] createCoupon error:', err);
    next(err);
  }
}

module.exports = {
  getSSAList,
  getCompanySalesAgentList,
  getCouponList,
  getCouponActivations,
  getAgentGovernanceDashboard,
  createSSA,
  createCompanySalesAgent,
  createCoupon,
};
