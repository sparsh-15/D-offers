const { prisma } = require('../db/prisma');

function getAvailableCredits(wallet) {
  if (!wallet) return 0;
  const monthlyLimit = wallet.monthlyLimit;
  const fromMonthly = monthlyLimit === -1 ? Number.MAX_SAFE_INTEGER : Math.max(0, monthlyLimit - wallet.usedThisCycle);
  return fromMonthly + (wallet.extraCreditsCurrentCycle || 0);
}

async function deductAiCredit(shopkeeperId) {
  const wallet = await prisma.aiWallet.findUnique({
    where: { shopkeeperId },
  });
  if (!wallet) return { ok: false, message: 'No AI wallet found' };
  const available = getAvailableCredits(wallet);
  if (available < 1) {
    return { ok: false, message: 'You have reached your AI banner limit. Buy AI Credit Pack.', code: 'AI_LIMIT_REACHED' };
  }
  const monthlyLimit = wallet.monthlyLimit;
  const used = wallet.usedThisCycle || 0;
  const extra = wallet.extraCreditsCurrentCycle || 0;
  if (monthlyLimit !== -1 && used < monthlyLimit) {
    await prisma.aiWallet.update({
      where: { id: wallet.id },
      data: { usedThisCycle: used + 1 },
    });
  } else {
    await prisma.aiWallet.update({
      where: { id: wallet.id },
      data: { extraCreditsCurrentCycle: Math.max(0, extra - 1) },
    });
  }
  return { ok: true };
}

function buildPlanSnapshot(plan) {
  return {
    name: plan.name,
    displayName: plan.displayName,
    tier: plan.tier || null,
    category: plan.category || 'all',
    monthlyPrice: plan.monthlyPrice,
    features: plan.features || [],
    maxOffers: plan.maxOffers,
    maxPhotosPerOffer: plan.maxPhotosPerOffer,
    monthlyAiLimit: plan.monthlyAiLimit !== undefined ? plan.monthlyAiLimit : 0,
    analyticsEnabled: !!plan.analyticsEnabled,
    prioritySupport: !!plan.prioritySupport,
    rankingTier: plan.rankingTier || 'normal',
    homepageRotation: !!plan.homepageRotation,
    aiOptimizationSuggestions: !!plan.aiOptimizationSuggestions,
    aiCreditTier: plan.aiCreditTier || 'silver',
  };
}

async function upsertWalletForSubscription(subscription) {
  const snapshot = subscription.planSnapshot || {};
  const monthlyLimit = snapshot.monthlyAiLimit !== undefined ? snapshot.monthlyAiLimit : 0;
  const cycleStart = subscription.startDate;
  const cycleEnd = subscription.endDate;

  const existing = await prisma.aiWallet.findUnique({
    where: { shopkeeperId: subscription.shopkeeperId },
  });

  if (existing) {
    return prisma.aiWallet.update({
      where: { id: existing.id },
      data: {
        subscriptionId: subscription.id,
        cycleStart,
        cycleEnd,
        monthlyLimit,
        usedThisCycle: 0,
        extraCreditsCurrentCycle: 0,
      },
    });
  }

  return prisma.aiWallet.create({
    data: {
      shopkeeperId: subscription.shopkeeperId,
      subscriptionId: subscription.id,
      cycleStart,
      cycleEnd,
      monthlyLimit,
      usedThisCycle: 0,
      extraCreditsCurrentCycle: 0,
    },
  });
}

module.exports = {
  buildPlanSnapshot,
  upsertWalletForSubscription,
  getAvailableCredits,
  deductAiCredit,
};
