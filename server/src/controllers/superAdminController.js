const User = require('../models/User');
const ShopkeeperProfile = require('../models/ShopkeeperProfile');
const Subscription = require('../models/Subscription');
const AuditLog = require('../models/AuditLog');
const { logAdminAction } = require('../middleware/roleAuth');

/**
 * Get dashboard analytics
 */
async function getDashboardAnalytics(req, res, next) {
  try {
    // Total users by role
    const usersByRole = await User.aggregate([
      {
        $group: {
          _id: '$role',
          count: { $sum: 1 },
          active: {
            $sum: { $cond: [{ $eq: ['$isActive', true] }, 1, 0] },
          },
          inactive: {
            $sum: { $cond: [{ $eq: ['$isActive', false] }, 1, 0] },
          },
        },
      },
    ]);

    // Total shops
    const totalShops = await ShopkeeperProfile.countDocuments();

    // Subscription stats
    const subscriptionStats = await Subscription.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalRevenue: { $sum: '$monthlyPrice' },
        },
      },
    ]);

    // Calculate MRR (Monthly Recurring Revenue)
    const activeSubscriptions = subscriptionStats.find(s => s._id === 'active') || { count: 0, totalRevenue: 0 };
    const mrr = activeSubscriptions.totalRevenue;

    // Recent activity count
    const recentActivityCount = await AuditLog.countDocuments({
      createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
    });

    res.json({
      success: true,
      data: {
        usersByRole: usersByRole.reduce((acc, item) => {
          acc[item._id] = {
            total: item.count,
            active: item.active,
            inactive: item.inactive,
          };
          return acc;
        }, {}),
        totalShops,
        subscriptions: {
          byStatus: subscriptionStats.reduce((acc, item) => {
            acc[item._id] = {
              count: item.count,
              revenue: item.totalRevenue,
            };
            return acc;
          }, {}),
          mrr,
        },
        recentActivityCount,
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] getDashboardAnalytics error:', err);
    next(err);
  }
}

/**
 * Get all users with filters
 */
async function getAllUsers(req, res, next) {
  try {
    const {
      role,
      isActive,
      approvalStatus,
      pincode,
      search,
      page = 1,
      limit = 20,
    } = req.query;

    const filter = {};

    if (role) filter.role = role;
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (approvalStatus) filter.approvalStatus = approvalStatus;
    if (pincode) filter.pincode = pincode;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('-__v')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      User.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] getAllUsers error:', err);
    next(err);
  }
}

/**
 * Get all shops with filters
 */
async function getAllShops(req, res, next) {
  try {
    const {
      subscriptionStatus,
      pincode,
      city,
      category,
      search,
      page = 1,
      limit = 20,
    } = req.query;

    const userFilter = { role: 'shopkeeper' };
    if (pincode) userFilter.pincode = pincode;
    if (city) userFilter.city = city;

    const shopFilter = {};
    if (category) shopFilter.category = category;
    if (search) {
      shopFilter.shopName = { $regex: search, $options: 'i' };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get shopkeeper users
    const shopkeeperUsers = await User.find(userFilter).select('_id').lean();
    const shopkeeperIds = shopkeeperUsers.map(u => u._id);

    shopFilter.userId = { $in: shopkeeperIds };

    // Get shops with user and subscription data
    const shops = await ShopkeeperProfile.find(shopFilter)
      .populate({
        path: 'userId',
        select: 'name phone pincode city isActive approvalStatus createdAt',
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    // Get subscription data for each shop
    const shopsWithSubscription = await Promise.all(
      shops.map(async shop => {
        const subscription = await Subscription.findOne({
          shopkeeperId: shop.userId._id,
        })
          .sort({ createdAt: -1 })
          .lean();

        return {
          ...shop,
          subscription: subscription || null,
        };
      })
    );

    // Filter by subscription status if provided
    let filteredShops = shopsWithSubscription;
    if (subscriptionStatus) {
      filteredShops = shopsWithSubscription.filter(
        shop => shop.subscription?.status === subscriptionStatus
      );
    }

    const total = await ShopkeeperProfile.countDocuments(shopFilter);

    res.json({
      success: true,
      data: {
        shops: filteredShops,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] getAllShops error:', err);
    next(err);
  }
}

/**
 * Activate/Deactivate user
 */
async function toggleUserStatus(req, res, next) {
  try {
    const { userId } = req.params;
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive must be a boolean value',
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Prevent super admin from deactivating themselves
    if (user._id.toString() === req.user.userId && !isActive) {
      return res.status(400).json({
        success: false,
        message: 'Cannot deactivate your own account',
      });
    }

    user.isActive = isActive;
    await user.save();

    // Log the action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      isActive ? 'user_activated' : 'user_deactivated',
      user._id,
      user.role,
      {
        previousStatus: !isActive,
        newStatus: isActive,
      },
      req.ip
    );

    res.json({
      success: true,
      message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        userId: user._id,
        isActive: user.isActive,
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] toggleUserStatus error:', err);
    next(err);
  }
}

/**
 * Update user approval status
 */
async function updateApprovalStatus(req, res, next) {
  try {
    const { userId } = req.params;
    const { approvalStatus } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(approvalStatus)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid approval status',
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const previousStatus = user.approvalStatus;
    user.approvalStatus = approvalStatus;
    await user.save();

    // Log the action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      approvalStatus === 'approved' ? 'user_approved' : 'user_rejected',
      user._id,
      user.role,
      {
        previousStatus,
        newStatus: approvalStatus,
      },
      req.ip
    );

    res.json({
      success: true,
      message: `User ${approvalStatus} successfully`,
      data: {
        userId: user._id,
        approvalStatus: user.approvalStatus,
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] updateApprovalStatus error:', err);
    next(err);
  }
}

/**
 * Get audit logs
 */
async function getAuditLogs(req, res, next) {
  try {
    const {
      action,
      adminId,
      targetUserId,
      startDate,
      endDate,
      page = 1,
      limit = 50,
    } = req.query;

    const filter = {};

    if (action) filter.action = action;
    if (adminId) filter.adminId = adminId;
    if (targetUserId) filter.targetUserId = targetUserId;
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [logs, total] = await Promise.all([
      AuditLog.find(filter)
        .populate('adminId', 'name phone role')
        .populate('targetUserId', 'name phone role')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      AuditLog.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        logs,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] getAuditLogs error:', err);
    next(err);
  }
}

/**
 * Get user details
 */
async function getUserDetails(req, res, next) {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select('-__v').lean();
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    let additionalData = {};

    // If shopkeeper, get profile and subscription
    if (user.role === 'shopkeeper') {
      const [profile, subscription] = await Promise.all([
        ShopkeeperProfile.findOne({ userId: user._id }).lean(),
        Subscription.findOne({ shopkeeperId: user._id })
          .sort({ createdAt: -1 })
          .lean(),
      ]);

      additionalData = {
        profile,
        subscription,
      };
    }

    // Get recent audit logs for this user
    const recentLogs = await AuditLog.find({ targetUserId: user._id })
      .populate('adminId', 'name phone role')
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();

    res.json({
      success: true,
      data: {
        user,
        ...additionalData,
        recentLogs,
      },
    });
  } catch (err) {
    console.error('[SUPER_ADMIN] getUserDetails error:', err);
    next(err);
  }
}

module.exports = {
  getDashboardAnalytics,
  getAllUsers,
  getAllShops,
  toggleUserStatus,
  updateApprovalStatus,
  getAuditLogs,
  getUserDetails,
};
