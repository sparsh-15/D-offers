const SubscriptionPlan = require('../models/SubscriptionPlan');
const Subscription = require('../models/Subscription');
const { logAdminAction } = require('../middleware/roleAuth');
const { isValidCategory, ALL_CATEGORIES, getAllCategories } = require('../config/businessCategories');

/**
 * Get all business categories
 */
async function getCategories(req, res, next) {
  try {
    const categories = getAllCategories();
    
    res.json({
      success: true,
      data: categories,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] getCategories error:', err);
    next(err);
  }
}

/**
 * Create a new subscription plan
 */
async function createPlan(req, res, next) {
  try {
    const {
      name,
      displayName,
      description,
      monthlyPrice,
      durationDays,
      category,
      features,
      maxOffers,
      maxPhotosPerOffer,
      analyticsEnabled,
      prioritySupport,
      sortOrder,
    } = req.body;

    // Validate required fields
    if (!name || !displayName || monthlyPrice === undefined || !category) {
      return res.status(400).json({
        success: false,
        message: 'Name, display name, monthly price, and category are required',
      });
    }

    // Validate category
    if (!isValidCategory(category)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category',
      });
    }

    // Check if plan with same name exists
    const existingPlan = await SubscriptionPlan.findOne({ name });
    if (existingPlan) {
      return res.status(400).json({
        success: false,
        message: 'Plan with this name already exists',
      });
    }

    // Create plan
    const plan = await SubscriptionPlan.create({
      name,
      displayName,
      description,
      monthlyPrice,
      durationDays: durationDays || 30,
      category,
      features: features || [],
      maxOffers: maxOffers !== undefined ? maxOffers : -1,
      maxPhotosPerOffer: maxPhotosPerOffer || 5,
      analyticsEnabled: analyticsEnabled || false,
      prioritySupport: prioritySupport || false,
      sortOrder: sortOrder || 0,
      priceHistory: [
        {
          price: monthlyPrice,
          changedBy: req.user.userId,
          changedAt: new Date(),
          reason: 'Initial price',
        },
      ],
    });

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_plan_created',
      null,
      null,
      { planId: plan._id, planName: plan.name, category: plan.category },
      req.ip
    );

    res.status(201).json({
      success: true,
      message: 'Subscription plan created successfully',
      data: plan,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] createPlan error:', err);
    next(err);
  }
}

/**
 * Get all subscription plans
 */
async function getAllPlans(req, res, next) {
  try {
    const { isActive, category } = req.query;

    const filter = {};
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }
    if (category) {
      filter.category = category;
    }

    const plans = await SubscriptionPlan.find(filter)
      .sort({ sortOrder: 1, monthlyPrice: 1 })
      .lean();

    res.json({
      success: true,
      data: plans,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] getAllPlans error:', err);
    next(err);
  }
}

/**
 * Get plan by ID
 */
async function getPlanById(req, res, next) {
  try {
    const { planId } = req.params;

    const plan = await SubscriptionPlan.findById(planId).lean();
    if (!plan) {
      return res.status(404).json({
        success: false,
        message: 'Plan not found',
      });
    }

    // Get subscription count for this plan
    const subscriptionCount = await Subscription.countDocuments({
      planId: plan._id,
      status: 'active',
    });

    res.json({
      success: true,
      data: {
        ...plan,
        activeSubscriptions: subscriptionCount,
      },
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] getPlanById error:', err);
    next(err);
  }
}

/**
 * Update subscription plan
 */
async function updatePlan(req, res, next) {
  try {
    const { planId } = req.params;
    const {
      displayName,
      description,
      monthlyPrice,
      durationDays,
      category,
      features,
      maxOffers,
      maxPhotosPerOffer,
      analyticsEnabled,
      prioritySupport,
      sortOrder,
      isActive,
      priceChangeReason,
    } = req.body;

    const plan = await SubscriptionPlan.findById(planId);
    if (!plan) {
      return res.status(404).json({
        success: false,
        message: 'Plan not found',
      });
    }

    // Validate category if provided
    if (category !== undefined && !isValidCategory(category)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category',
      });
    }

    // Track if price is changing
    const priceChanged = monthlyPrice !== undefined && monthlyPrice !== plan.monthlyPrice;

    // Update fields
    if (displayName !== undefined) plan.displayName = displayName;
    if (description !== undefined) plan.description = description;
    if (durationDays !== undefined) plan.durationDays = durationDays;
    if (category !== undefined) plan.category = category;
    if (features !== undefined) plan.features = features;
    if (maxOffers !== undefined) plan.maxOffers = maxOffers;
    if (maxPhotosPerOffer !== undefined) plan.maxPhotosPerOffer = maxPhotosPerOffer;
    if (analyticsEnabled !== undefined) plan.analyticsEnabled = analyticsEnabled;
    if (prioritySupport !== undefined) plan.prioritySupport = prioritySupport;
    if (sortOrder !== undefined) plan.sortOrder = sortOrder;
    if (isActive !== undefined) plan.isActive = isActive;

    // Handle price change with history
    if (priceChanged) {
      await plan.updatePrice(
        monthlyPrice,
        req.user.userId,
        priceChangeReason || 'Price update'
      );
    } else {
      await plan.save();
    }

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_plan_updated',
      null,
      null,
      {
        planId: plan._id,
        planName: plan.name,
        priceChanged,
        newPrice: priceChanged ? monthlyPrice : undefined,
      },
      req.ip
    );

    res.json({
      success: true,
      message: 'Plan updated successfully',
      data: plan,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] updatePlan error:', err);
    next(err);
  }
}

/**
 * Delete subscription plan (soft delete by deactivating)
 */
async function deletePlan(req, res, next) {
  try {
    const { planId } = req.params;

    const plan = await SubscriptionPlan.findById(planId);
    if (!plan) {
      return res.status(404).json({
        success: false,
        message: 'Plan not found',
      });
    }

    // Check if plan has active subscriptions
    const activeSubscriptions = await Subscription.countDocuments({
      planId: plan._id,
      status: 'active',
    });

    if (activeSubscriptions > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete plan with active subscriptions',
        details: {
          activeSubscriptions,
          action: 'Deactivate the plan instead or wait for subscriptions to expire',
        },
      });
    }

    // Soft delete by deactivating
    plan.isActive = false;
    await plan.save();

    // Log action
    await logAdminAction(
      req.user.userId,
      req.user.role,
      'subscription_plan_deleted',
      null,
      null,
      { planId: plan._id, planName: plan.name },
      req.ip
    );

    res.json({
      success: true,
      message: 'Plan deactivated successfully',
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] deletePlan error:', err);
    next(err);
  }
}

/**
 * Get plan recommendations for a category
 */
async function getRecommendedPlans(req, res, next) {
  try {
    const { category } = req.query;

    if (!category) {
      return res.status(400).json({
        success: false,
        message: 'Category is required',
      });
    }

    // Validate category
    if (!isValidCategory(category)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category',
      });
    }

    // Find plans for this category or 'all' categories
    const plans = await SubscriptionPlan.find({
      isActive: true,
      $or: [{ category: category }, { category: ALL_CATEGORIES }],
    })
      .sort({ sortOrder: 1, monthlyPrice: 1 })
      .lean();

    res.json({
      success: true,
      data: plans,
    });
  } catch (err) {
    console.error('[SUBSCRIPTION_PLAN] getRecommendedPlans error:', err);
    next(err);
  }
}

module.exports = {
  getCategories,
  createPlan,
  getAllPlans,
  getPlanById,
  updatePlan,
  deletePlan,
  getRecommendedPlans,
};
