const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { buildPlanSnapshot, getAvailableCredits, upsertWalletForSubscription } = require('../services/aiWalletService');
const {
  FREE_INBOX_MESSAGE_LIMIT,
  FREE_STARTER_PLAN_NAME,
  FREE_WHATSAPP_LIMIT,
  getDefaultTrialWhatsappCap,
  isFreeStarterSnapshot,
  isTrialSubscription,
} = require('../config/subscriptionEntitlements');

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isPrismaP1001(error) {
  return error && error.code === 'P1001';
}

function ci(value) {
  return String(value || '').trim().toLowerCase();
}

function isExpired(subscription) {
  return !!subscription?.endDate && new Date() > new Date(subscription.endDate);
}

function normalizeChannels(channels) {
  if (!Array.isArray(channels)) return [];
  return Array.from(new Set(channels.map((channel) => ci(channel)).filter(Boolean)));
}

function hasAdvancedTargeting(payload = {}) {
  const targetGender = ci(payload.targetGender);
  const hasAge = Number.isFinite(Number(payload.targetAgeMin)) || Number.isFinite(Number(payload.targetAgeMax));
  return (
    hasAge ||
    (targetGender && targetGender !== 'all') ||
    ci(payload.targetArea)
  );
}

async function getUpgradeRecommendations(shopkeeperId) {
  const profile = await prisma.shopkeeperProfile.findUnique({
    where: { userId: shopkeeperId },
    select: { category: true },
  });
  const category = ci(profile?.category);
  const plans = await prisma.subscriptionPlan.findMany({
    where: {
      isActive: true,
      name: { not: FREE_STARTER_PLAN_NAME },
      NOT: { tier: 'free' },
      OR: category ? [{ category }, { category: 'all' }] : [{ category: 'all' }],
    },
    orderBy: [{ monthlyPrice: 'asc' }, { sortOrder: 'asc' }],
    take: 3,
    select: {
      id: true,
      name: true,
      displayName: true,
      monthlyPrice: true,
      category: true,
      tier: true,
    },
  });

  return plans.map((plan) => ({
    id: plan.id,
    name: plan.displayName || plan.name,
    planType: plan.name,
    price: Number(plan.monthlyPrice),
    category: plan.category,
    tier: plan.tier,
  }));
}

async function ensureFreeStarterSubscription(shopkeeperId, reason = 'auto_free_fallback') {
  const active = await prisma.subscription.findFirst({
    where: { shopkeeperId, status: 'active' },
    orderBy: { createdAt: 'desc' },
  });
  if (active && !isExpired(active)) return active;

  if (active && isExpired(active)) {
    await prisma.subscription.update({ where: { id: active.id }, data: { status: 'expired' } });
  }

  const freePlan =
    (await prisma.subscriptionPlan.findFirst({ where: { isActive: true, name: FREE_STARTER_PLAN_NAME } })) ||
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, tier: 'free' },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    }));

  if (!freePlan) return null;

  const startDate = new Date();
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + Math.max(30, Number(freePlan.durationDays) || 30));
  const subscription = await prisma.subscription.create({
    data: {
      shopkeeperId,
      planId: freePlan.id,
      planSnapshot: {
        ...buildPlanSnapshot(freePlan),
        isFreeStarter: true,
      },
      status: 'active',
      startDate,
      endDate,
      actualPrice: 0,
      autoRenew: true,
      paymentStatus: 'paid',
      notes: reason,
    },
  });

  await upsertWalletForSubscription(subscription);
  await prisma.onboardingStatus.upsert({
    where: { userId: shopkeeperId },
    create: { userId: shopkeeperId, subscriptionActivated: true },
    update: { subscriptionActivated: true },
  });

  return subscription;
}

async function sendRestriction(res, shopkeeperId, code, message, details = {}) {
  const recommendedPlans = await getUpgradeRecommendations(shopkeeperId);
  return res.status(403).json({
    success: false,
    code,
    message,
    details: {
      ...details,
      recommendedPlans,
    },
  });
}

async function resolveTrialWhatsappCap(subscription, shopkeeperId) {
  const snapshotCap = Number(subscription?.planSnapshot?.trialWhatsappCap);
  if (Number.isFinite(snapshotCap) && snapshotCap >= 0) {
    return snapshotCap;
  }

  const categorySetting = await prisma.appSetting.findUnique({ where: { key: 'trial_whatsapp_caps_v1' } });
  const profile = await prisma.shopkeeperProfile.findUnique({
    where: { userId: shopkeeperId },
    select: { category: true },
  });

  let caps = {};
  try {
    caps = JSON.parse(String(categorySetting?.value || '{}'));
  } catch (error) {
    caps = {};
  }

  const category = ci(profile?.category);
  const fromSettings = Number(caps?.[category]);
  if (Number.isFinite(fromSettings) && fromSettings >= 0) {
    return fromSettings;
  }
  return getDefaultTrialWhatsappCap(category);
}

async function requireActiveSubscription(req, res, next) {
  let lastError;
  try {
    if (req.user.role !== 'shopkeeper') return next();

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    let subscription = null;
    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        subscription = await prisma.subscription.findFirst({
          where: { shopkeeperId, status: 'active' },
          orderBy: { createdAt: 'desc' },
        });
        break;
      } catch (error) {
        lastError = error;
        if (!isPrismaP1001(error) || attempt === 3) {
          throw error;
        }
        const delay = 150 * attempt;
        console.warn(`[SUBSCRIPTION_CHECK] P1001 retry ${attempt}/3 in ${delay}ms`);
        await wait(delay);
      }
    }

    if (!subscription) {
      subscription = await ensureFreeStarterSubscription(shopkeeperId, 'auto_free_fallback');
      if (!subscription) {
        return sendRestriction(
          res,
          shopkeeperId,
          'SUBSCRIPTION_REQUIRED',
          'Active subscription required',
          { reason: 'No plan found. Contact support to configure plans.' },
        );
      }
    }

    if (subscription.endDate && new Date() > new Date(subscription.endDate)) {
      await prisma.subscription.update({ where: { id: subscription.id }, data: { status: 'expired' } });
      const fallback = await ensureFreeStarterSubscription(shopkeeperId, 'trial_or_paid_expired_fallback');
      if (!fallback) {
        return sendRestriction(
          res,
          shopkeeperId,
          'SUBSCRIPTION_EXPIRED',
          'Subscription expired',
          {
            reason: 'Your subscription has expired',
            expiredOn: subscription.endDate,
            action: 'Upgrade to continue premium features',
          },
        );
      }
      subscription = fallback;
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
    if (isPrismaP1001(error || lastError)) {
      return res.status(503).json({
        success: false,
        message: 'Service temporarily unavailable. Please retry in a moment.',
        code: 'DATABASE_TEMPORARILY_UNAVAILABLE',
      });
    }
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
      where: { shopkeeperId, status: 'active' },
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

async function checkAiCreditLimit(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();
    if (!req.subscription) {
      return res.status(403).json({
        success: false,
        message: 'Active subscription required',
        code: 'SUBSCRIPTION_REQUIRED',
      });
    }
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const wallet = await prisma.aiWallet.findUnique({
      where: { shopkeeperId },
    });
    const available = getAvailableCredits(wallet);
    if (available < 1) {
      return res.status(403).json({
        success: false,
        message: 'You have reached your AI banner limit. Buy AI Credit Pack.',
        code: 'AI_LIMIT_REACHED',
        details: { action: 'Purchase an AI credit pack to continue' },
      });
    }
    next();
  } catch (error) {
    console.error('[AI_CREDIT_LIMIT_CHECK] Error:', error);
    next(error);
  }
}

async function checkCampaignFeatureAccess(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();
    if (!req.subscription) {
      return sendRestriction(
        res,
        await resolvePgId('users', req.user.userId),
        'SUBSCRIPTION_REQUIRED',
        'Active subscription required',
      );
    }

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const snapshot = req.subscription.planSnapshot || {};
    const channels = normalizeChannels(req.body?.channels || []);
    const freeStarter = isFreeStarterSnapshot(snapshot);

    if (freeStarter && channels.includes('whatsapp')) {
      return sendRestriction(
        res,
        shopkeeperId,
        'FREE_WHATSAPP_NOT_ALLOWED',
        'WhatsApp campaigns are locked on Free Starter',
        { action: 'Upgrade to Silver, Gold, or Platinum to unlock WhatsApp campaigns.' },
      );
    }

    if (freeStarter && hasAdvancedTargeting(req.body || {})) {
      return sendRestriction(
        res,
        shopkeeperId,
        'ADVANCED_TARGETING_LOCKED',
        'Advanced targeting is part of paid plans',
        { action: 'Upgrade to unlock advanced audience targeting.' },
      );
    }

    return next();
  } catch (error) {
    console.error('[CAMPAIGN_FEATURE_CHECK] Error:', error);
    return next(error);
  }
}

async function checkCampaignMessageQuota(req, res, next) {
  try {
    if (req.user.role !== 'shopkeeper') return next();
    if (!req.subscription) return next();

    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const snapshot = req.subscription.planSnapshot || {};
    const freeStarter = isFreeStarterSnapshot(snapshot);
    const trial = isTrialSubscription(req.subscription);
    if (!freeStarter && !trial) return next();

    let channels = normalizeChannels(req.body?.channels || []);
    let selectedAudienceSize = Math.max(Number(req.body?.selectedAudienceSize) || 0, 0);

    if (req.params?.id) {
      const campaignId = (await resolvePgId('campaigns', req.params.id)) || req.params.id;
      const campaign = await prisma.campaign.findUnique({
        where: { id: campaignId },
        select: {
          id: true,
          shopkeeperId: true,
          channels: true,
          selectedAudienceSize: true,
        },
      });

      if (!campaign || String(campaign.shopkeeperId) !== String(shopkeeperId)) {
        return res.status(404).json({ success: false, message: 'Campaign not found' });
      }

      const hasChannelOverride = Array.isArray(req.body?.channels);
      const hasAudienceOverride = Object.prototype.hasOwnProperty.call(req.body || {}, 'selectedAudienceSize');

      channels = normalizeChannels(
        hasChannelOverride ? req.body.channels : (campaign.channels || []),
      );
      selectedAudienceSize = Math.max(
        Number(
          hasAudienceOverride
            ? req.body.selectedAudienceSize
            : campaign.selectedAudienceSize,
        ) || 0,
        0,
      );
    }

    const windowStart = freeStarter
      ? new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      : req.subscription.startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const windowEnd = trial ? req.subscription.endDate || null : null;

    const usageCampaigns = await prisma.campaign.findMany({
      where: {
        shopkeeperId,
        status: { in: ['paid', 'queued', 'sending', 'completed'] },
        createdAt: {
          gte: windowStart,
          ...(windowEnd ? { lte: windowEnd } : {}),
        },
      },
      select: {
        channels: true,
        selectedAudienceSize: true,
      },
    });

    const usage = usageCampaigns.reduce(
      (acc, item) => {
        const audience = Math.max(Number(item.selectedAudienceSize) || 0, 0);
        const campaignChannels = normalizeChannels(item.channels || []);
        if (campaignChannels.includes('app_inbox')) acc.inbox += audience;
        if (campaignChannels.includes('whatsapp')) acc.whatsapp += audience;
        return acc;
      },
      { inbox: 0, whatsapp: 0 },
    );

    const projectedInbox = usage.inbox + (channels.includes('app_inbox') ? selectedAudienceSize : 0);
    const projectedWhatsapp = usage.whatsapp + (channels.includes('whatsapp') ? selectedAudienceSize : 0);

    if (freeStarter && channels.includes('whatsapp')) {
      return sendRestriction(
        res,
        shopkeeperId,
        'FREE_WHATSAPP_NOT_ALLOWED',
        'WhatsApp campaigns are not available on Free Starter',
        {
          limit: FREE_WHATSAPP_LIMIT,
          used: usage.whatsapp,
          projected: projectedWhatsapp,
        },
      );
    }

    if (freeStarter && projectedInbox > FREE_INBOX_MESSAGE_LIMIT) {
      return sendRestriction(
        res,
        shopkeeperId,
        'FREE_INBOX_LIMIT_REACHED',
        'Free Starter inbox message quota reached',
        {
          limit: FREE_INBOX_MESSAGE_LIMIT,
          used: usage.inbox,
          projected: projectedInbox,
          action: 'Upgrade to continue running inbox campaigns.',
        },
      );
    }

    if (trial && channels.includes('whatsapp')) {
      const whatsappCap = await resolveTrialWhatsappCap(req.subscription, shopkeeperId);
      if (projectedWhatsapp > whatsappCap) {
        return sendRestriction(
          res,
          shopkeeperId,
          'TRIAL_WHATSAPP_LIMIT_REACHED',
          'Trial WhatsApp campaign quota reached',
          {
            limit: whatsappCap,
            used: usage.whatsapp,
            projected: projectedWhatsapp,
            action: 'Upgrade to continue WhatsApp campaigns after trial.',
          },
        );
      }
    }

    req.campaignUsage = {
      ...usage,
      projectedInbox,
      projectedWhatsapp,
      windowStart,
      windowEnd,
    };

    return next();
  } catch (error) {
    console.error('[CAMPAIGN_QUOTA_CHECK] Error:', error);
    return next(error);
  }
}

module.exports = {
  requireActiveSubscription,
  checkSubscriptionStatus,
  checkOfferLimit,
  checkAiCreditLimit,
  checkCampaignFeatureAccess,
  checkCampaignMessageQuota,
};
