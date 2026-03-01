const { prisma } = require('../db/prisma');
const { resolvePgId } = require('./idResolver');

async function createPlan(payload) {
  return prisma.subscriptionPlan.create({
    data: {
      name: payload.name,
      displayName: payload.displayName,
      description: payload.description || '',
      monthlyPrice: payload.monthlyPrice,
      durationDays: payload.durationDays || 30,
      category: payload.category,
      features: payload.features || [],
      maxOffers: payload.maxOffers !== undefined ? payload.maxOffers : -1,
      maxPhotosPerOffer: payload.maxPhotosPerOffer || 5,
      analyticsEnabled: !!payload.analyticsEnabled,
      prioritySupport: !!payload.prioritySupport,
      isActive: payload.isActive !== false,
      sortOrder: payload.sortOrder || 0,
      monthlyAiLimit: payload.monthlyAiLimit !== undefined ? payload.monthlyAiLimit : 0,
      rankingTier: payload.rankingTier || 'normal',
      boostCredits: payload.boostCredits !== undefined ? payload.boostCredits : 0,
      homepageRotation: !!payload.homepageRotation,
      aiOptimizationSuggestions: !!payload.aiOptimizationSuggestions,
      aiCreditTier: payload.aiCreditTier || 'silver',
      tier: payload.tier ?? undefined,
    },
  });
}

async function updatePlan(planId, data) {
  const pgPlanId = await resolvePgId('subscription_plans', planId) || planId;
  return prisma.subscriptionPlan.update({
    where: { id: pgPlanId },
    data,
  });
}

module.exports = { createPlan, updatePlan };
