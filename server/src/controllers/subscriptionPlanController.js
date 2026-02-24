const { prisma } = require('../db/prisma');
const { logAdminAction } = require('../middleware/roleAuth');
const {
  isValidCategory,
  ALL_CATEGORIES,
  getAllCategories,
} = require('../config/businessCategories');
const subscriptionPlanRepository = require('../repositories/subscriptionPlanRepository');
const { resolvePgId } = require('../repositories/idResolver');

async function getCategories(req, res, next) {
  try {
    res.json({ success: true, data: getAllCategories() });
  } catch (err) {
    next(err);
  }
}

async function createPlan(req, res, next) {
  try {
    const { name, displayName, description, monthlyPrice, durationDays, category, features, maxOffers, maxPhotosPerOffer, analyticsEnabled, prioritySupport, sortOrder } = req.body;
    if (!name || !displayName || monthlyPrice === undefined || !category) {
      return res.status(400).json({ success: false, message: 'Name, display name, monthly price, and category are required' });
    }
    if (!isValidCategory(category)) {
      return res.status(400).json({ success: false, message: 'Invalid category' });
    }
    const existing = await prisma.subscriptionPlan.findFirst({ where: { name } });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Plan with this name already exists' });
    }
    const plan = await subscriptionPlanRepository.createPlan({
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
      isActive: true,
    });
    await prisma.subscriptionPlanPriceHistory.create({
      data: {
        planId: plan.id,
        price: monthlyPrice,
        changedBy: await resolvePgId('users', req.user.userId),
        reason: 'Initial price',
      },
    });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_created', null, null, { planId: plan.id, planName: plan.name, category: plan.category }, req.ip);
    res.status(201).json({ success: true, message: 'Subscription plan created successfully', data: plan });
  } catch (err) {
    next(err);
  }
}

async function getAllPlans(req, res, next) {
  try {
    const { isActive, category } = req.query;
    const where = {};
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (category) where.category = category;
    const plans = await prisma.subscriptionPlan.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    });
    res.json({ success: true, data: plans });
  } catch (err) {
    next(err);
  }
}

async function getPlanById(req, res, next) {
  try {
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: req.params.planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Plan not found' });
    const activeSubscriptions = await prisma.subscription.count({
      where: { planId: plan.id, status: 'active' },
    });
    res.json({ success: true, data: { ...plan, activeSubscriptions } });
  } catch (err) {
    next(err);
  }
}

async function updatePlan(req, res, next) {
  try {
    const { planId } = req.params;
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Plan not found' });
    const { displayName, description, monthlyPrice, durationDays, category, features, maxOffers, maxPhotosPerOffer, analyticsEnabled, prioritySupport, sortOrder, isActive, priceChangeReason } = req.body;
    if (category !== undefined && !isValidCategory(category)) {
      return res.status(400).json({ success: false, message: 'Invalid category' });
    }
    const priceChanged = monthlyPrice !== undefined && Number(monthlyPrice) !== Number(plan.monthlyPrice);
    const updated = await subscriptionPlanRepository.updatePlan(planId, {
      ...(displayName !== undefined ? { displayName } : {}),
      ...(description !== undefined ? { description } : {}),
      ...(monthlyPrice !== undefined ? { monthlyPrice } : {}),
      ...(durationDays !== undefined ? { durationDays } : {}),
      ...(category !== undefined ? { category } : {}),
      ...(features !== undefined ? { features } : {}),
      ...(maxOffers !== undefined ? { maxOffers } : {}),
      ...(maxPhotosPerOffer !== undefined ? { maxPhotosPerOffer } : {}),
      ...(analyticsEnabled !== undefined ? { analyticsEnabled } : {}),
      ...(prioritySupport !== undefined ? { prioritySupport } : {}),
      ...(sortOrder !== undefined ? { sortOrder } : {}),
      ...(isActive !== undefined ? { isActive } : {}),
    });
    if (priceChanged) {
      await prisma.subscriptionPlanPriceHistory.create({
        data: {
          planId,
          price: monthlyPrice,
          changedBy: await resolvePgId('users', req.user.userId),
          reason: priceChangeReason || 'Price update',
        },
      });
    }
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_updated', null, null, { planId: updated.id, planName: updated.name, priceChanged, newPrice: priceChanged ? monthlyPrice : undefined }, req.ip);
    res.json({ success: true, message: 'Plan updated successfully', data: updated });
  } catch (err) {
    next(err);
  }
}

async function deletePlan(req, res, next) {
  try {
    const plan = await prisma.subscriptionPlan.findUnique({ where: { id: req.params.planId } });
    if (!plan) return res.status(404).json({ success: false, message: 'Plan not found' });
    const activeSubscriptions = await prisma.subscription.count({
      where: { planId: plan.id, status: 'active' },
    });
    if (activeSubscriptions > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete plan with active subscriptions',
        details: { activeSubscriptions, action: 'Deactivate the plan instead or wait for subscriptions to expire' },
      });
    }
    await subscriptionPlanRepository.updatePlan(plan.id, { isActive: false });
    await logAdminAction(req.user.userId, req.user.role, 'subscription_plan_deleted', null, null, { planId: plan.id, planName: plan.name }, req.ip);
    res.json({ success: true, message: 'Plan deactivated successfully' });
  } catch (err) {
    next(err);
  }
}

async function getRecommendedPlans(req, res, next) {
  try {
    const { category } = req.query;
    if (!category) return res.status(400).json({ success: false, message: 'Category is required' });
    if (!isValidCategory(category)) return res.status(400).json({ success: false, message: 'Invalid category' });
    const plans = await prisma.subscriptionPlan.findMany({
      where: { isActive: true, OR: [{ category }, { category: ALL_CATEGORIES }] },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    });
    res.json({ success: true, data: plans });
  } catch (err) {
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
