const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const subscriptionRepository = require('../repositories/subscriptionRepository');
const auditLogRepository = require('../repositories/auditLogRepository');
const { buildPlanSnapshot, upsertWalletForSubscription, getAvailableCredits } = require('../services/aiWalletService');
const { validateAndComputeDiscount } = require('../services/couponValidationService');
const {
  FREE_STARTER_PLAN_NAME,
  TRIAL_DURATION_DAYS,
  normalizeBusinessFingerprint,
  hashFingerprint,
  getDefaultTrialWhatsappCap,
  isTrialSubscription,
  isFreeStarterSnapshot,
  getTrialGuardKey,
} = require('../config/subscriptionEntitlements');

function ci(value) {
  return String(value || '').trim();
}

function parseJsonValue(value) {
  try {
    return JSON.parse(String(value || '{}'));
  } catch (error) {
    return {};
  }
}

function isExpired(subscription) {
  return !!subscription?.endDate && new Date(subscription.endDate) <= new Date();
}

async function getLatestSubscription(shopkeeperId) {
  return prisma.subscription.findFirst({
    where: { shopkeeperId },
    orderBy: { createdAt: 'desc' },
  });
}

async function expireIfNeeded(subscription) {
  if (!subscription || subscription.status !== 'active' || !isExpired(subscription)) return subscription;
  return subscriptionRepository.updateSubscription(subscription.id, {
    status: 'expired',
  });
}

async function getActiveFreeStarterPlan() {
  return (
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, name: FREE_STARTER_PLAN_NAME },
    })) ||
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, tier: 'free' },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    }))
  );
}

async function ensureFreeStarterSubscription(shopkeeperId, reason = 'auto_free_fallback') {
  const active = await prisma.subscription.findFirst({
    where: { shopkeeperId, status: 'active' },
    orderBy: { createdAt: 'desc' },
  });

  if (active && !isExpired(active)) {
    return active;
  }

  if (active && isExpired(active)) {
    await subscriptionRepository.updateSubscription(active.id, { status: 'expired' });
  }

  const freePlan = await getActiveFreeStarterPlan();
  if (!freePlan) {
    return null;
  }

  const startDate = new Date();
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + Math.max(30, Number(freePlan.durationDays) || 30));
  const snapshot = {
    ...buildPlanSnapshot(freePlan),
    isFreeStarter: true,
  };

  const subscription = await subscriptionRepository.createSubscription({
    shopkeeperId,
    planId: freePlan.id,
    planSnapshot: snapshot,
    status: 'active',
    startDate,
    endDate,
    actualPrice: 0,
    autoRenew: true,
    paymentStatus: 'paid',
    notes: reason,
  });

  await upsertWalletForSubscription(subscription);
  await prisma.onboardingStatus.upsert({
    where: { userId: shopkeeperId },
    create: { userId: shopkeeperId, subscriptionActivated: true },
    update: { subscriptionActivated: true },
  });

  return subscription;
}

async function getTrialWhatsappCapForCategory(category) {
  const configured = await prisma.appSetting.findUnique({
    where: { key: 'trial_whatsapp_caps_v1' },
  });
  const caps = parseJsonValue(configured?.value);
  const normalizedCategory = String(category || '').trim().toLowerCase();
  if (caps && typeof caps === 'object' && Number.isFinite(Number(caps[normalizedCategory]))) {
    return Number(caps[normalizedCategory]);
  }
  return getDefaultTrialWhatsappCap(normalizedCategory);
}

async function getTrialPlan() {
  return (
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, tier: 'trial' },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    })) ||
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, name: { contains: 'trial', mode: 'insensitive' } },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    })) ||
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, tier: 'gold' },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    })) ||
    (await prisma.subscriptionPlan.findFirst({
      where: { isActive: true, name: { contains: 'gold', mode: 'insensitive' } },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    }))
  );
}

function buildTrialGuardValue({ shopkeeperId, phone, fingerprintHash, source }) {
  return JSON.stringify({
    shopkeeperId,
    phone,
    fingerprintHash,
    source,
    usedAt: new Date().toISOString(),
  });
}

async function hasTrialBeenUsed(shopkeeperId, guardKey) {
  const [guard, historicalTrial] = await Promise.all([
    prisma.appSetting.findUnique({ where: { key: guardKey } }),
    prisma.subscription.findFirst({
      where: {
        shopkeeperId,
        OR: [
          { notes: { contains: 'trial', mode: 'insensitive' } },
          { status: 'expired', notes: { contains: 'trial', mode: 'insensitive' } },
        ],
      },
      select: { id: true },
    }),
  ]);
  return !!guard || !!historicalTrial;
}

async function activateTrialForShopkeeper(shopkeeperId, source = 'manual') {
  const [user, profile, onboarding, activeSubscription] = await Promise.all([
    prisma.user.findUnique({ where: { id: shopkeeperId }, select: { phone: true } }),
    prisma.shopkeeperProfile.findUnique({
      where: { userId: shopkeeperId },
      select: { category: true, shopName: true, address: true },
    }),
    prisma.onboardingStatus.findUnique({ where: { userId: shopkeeperId } }),
    prisma.subscription.findFirst({
      where: { shopkeeperId, status: 'active' },
      orderBy: { createdAt: 'desc' },
    }),
  ]);

  if (activeSubscription && !isExpired(activeSubscription) && isTrialSubscription(activeSubscription)) {
    return activeSubscription;
  }

  if (activeSubscription && !isExpired(activeSubscription) && !isFreeStarterSnapshot(activeSubscription.planSnapshot)) {
    const error = new Error('A paid subscription is already active');
    error.statusCode = 400;
    error.code = 'ACTIVE_SUBSCRIPTION_EXISTS';
    throw error;
  }

  if (!onboarding?.businessProfileCompleted || !onboarding?.termsAccepted) {
    const error = new Error('Complete onboarding to start trial');
    error.statusCode = 400;
    error.code = 'ONBOARDING_INCOMPLETE';
    throw error;
  }

  const trialPlan = await getTrialPlan();
  if (!trialPlan) {
    const error = new Error('No trial plan available for activation');
    error.statusCode = 400;
    error.code = 'TRIAL_PLAN_UNAVAILABLE';
    throw error;
  }

  const fingerprint = normalizeBusinessFingerprint(profile?.shopName, profile?.address);
  const fingerprintHash = hashFingerprint(fingerprint || String(shopkeeperId));
  const guardKey = getTrialGuardKey(user?.phone, fingerprintHash);
  const trialUsed = await hasTrialBeenUsed(shopkeeperId, guardKey);
  if (trialUsed) {
    const error = new Error('Trial already used for this business');
    error.statusCode = 400;
    error.code = 'TRIAL_ALREADY_USED';
    throw error;
  }

  const trialWhatsappCap = await getTrialWhatsappCapForCategory(profile?.category);
  const startDate = new Date();
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + TRIAL_DURATION_DAYS);
  const trialDisplayName = String(trialPlan.displayName || '').trim() || 'Free Trial';
  const trialName = String(trialPlan.name || '').trim() || 'trial_plan';
  const snapshot = {
    ...buildPlanSnapshot(trialPlan),
    name: trialName,
    displayName: trialDisplayName,
    tier: 'trial',
    isTrial: true,
    trialWhatsappCap,
    trialDurationDays: TRIAL_DURATION_DAYS,
    trialDisplayName,
    unlockedFeatures: ['whatsapp_campaigns', 'full_campaign_builder', 'audience_targeting'],
  };

  const subscription = await subscriptionRepository.createSubscription({
    shopkeeperId,
    planId: trialPlan.id,
    planSnapshot: snapshot,
    status: 'active',
    startDate,
    endDate,
    actualPrice: 0,
    autoRenew: false,
    paymentStatus: 'paid',
    notes: `trial:${source}`,
  });

  await Promise.all([
    upsertWalletForSubscription(subscription),
    prisma.appSetting.create({
      data: {
        key: guardKey,
        value: buildTrialGuardValue({
          shopkeeperId,
          phone: user?.phone,
          fingerprintHash,
          source,
        }),
      },
    }),
    prisma.onboardingStatus.upsert({
      where: { userId: shopkeeperId },
      create: {
        userId: shopkeeperId,
        subscriptionActivated: true,
        onboardingCompleted: true,
        currentStep: 4,
      },
      update: {
        subscriptionActivated: true,
        onboardingCompleted: true,
        currentStep: 4,
      },
    }),
  ]);

  return subscription;
}

function serializeSubscription(subscription, wallet) {
  const trial = isTrialSubscription(subscription);
  const freeStarter = isFreeStarterSnapshot(subscription?.planSnapshot);
  const trialDisplayName =
    subscription?.planSnapshot?.trialDisplayName ||
    (trial ? 'Free Trial' : null);
  const base = {
    planType: subscription?.planSnapshot?.name || null,
    planDisplayName: trialDisplayName || subscription?.planSnapshot?.displayName || null,
    planTier: trial ? 'trial' : subscription?.planSnapshot?.tier || null,
    analyticsEnabled: subscription?.planSnapshot?.analyticsEnabled === true,
    planSnapshot: subscription?.planSnapshot || null,
    trial,
    freeStarter,
    trialWhatsappCap: subscription?.planSnapshot?.trialWhatsappCap ?? null,
    status: subscription?.status || 'inactive',
    startDate: subscription?.startDate ?? null,
    endDate: subscription?.endDate ?? null,
    autoRenew: subscription?.autoRenew ?? false,
    isActive: false,
    isExpired: false,
    availableAiCredits: 0,
    usedThisCycle: 0,
    extraCreditsCurrentCycle: 0,
    cycleEnd: null,
  };
  if (!subscription) return base;
  const now = new Date();
  base.isActive =
    subscription.status === 'active' &&
    !!subscription.endDate &&
    new Date(subscription.endDate) > now;
  base.isExpired = !!subscription.endDate && new Date(subscription.endDate) <= now;
  if (wallet) {
    base.availableAiCredits = getAvailableCredits(wallet);
    base.usedThisCycle = wallet.usedThisCycle ?? 0;
    base.extraCreditsCurrentCycle = wallet.extraCreditsCurrentCycle ?? 0;
    base.cycleEnd = wallet.cycleEnd ?? subscription.endDate;
  } else if (subscription.endDate) {
    base.cycleEnd = subscription.endDate;
  }
  return base;
}

async function getSubscription(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const onboarding = await prisma.onboardingStatus.findUnique({ where: { userId: shopkeeperId } });
    let subscription = await getLatestSubscription(shopkeeperId);
    subscription = await expireIfNeeded(subscription);

    const onboardingReady = !!onboarding?.businessProfileCompleted && !!onboarding?.termsAccepted;
    const active = subscription && subscription.status === 'active' && !isExpired(subscription);

    if (onboardingReady && (!active || isFreeStarterSnapshot(subscription.planSnapshot))) {
      try {
        subscription = await activateTrialForShopkeeper(shopkeeperId, 'auto');
      } catch (error) {
        if (error.code !== 'TRIAL_ALREADY_USED' && error.code !== 'ACTIVE_SUBSCRIPTION_EXISTS') {
          throw error;
        }
      }
    }

    const effective = subscription && subscription.status === 'active' && !isExpired(subscription)
      ? subscription
      : await ensureFreeStarterSubscription(shopkeeperId, 'auto_free_fallback');

    const wallet = await prisma.aiWallet.findUnique({ where: { shopkeeperId } });
    res.status(200).json({ success: true, subscription: serializeSubscription(effective, wallet) });
  } catch (err) {
    next(err);
  }
}

async function activateTrial(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const subscription = await activateTrialForShopkeeper(shopkeeperId, 'manual');
    res.status(200).json({ success: true, message: 'Trial subscription activated', subscription: serializeSubscription(subscription) });
  } catch (err) {
    if (err.statusCode) {
      return res.status(err.statusCode).json({
        success: false,
        code: err.code || 'TRIAL_ACTIVATION_FAILED',
        message: err.message || 'Failed to activate trial',
      });
    }
    return next(err);
  }
}

async function getQuote(req, res, next) {
  try {
    const { planId, planType, durationMonths, couponCode } = req.body || {};
    if ((!planType && !planId) || !durationMonths) {
      return res.status(400).json({
        success: false,
        message: 'Plan (planId or planType) and durationMonths are required',
      });
    }
    const plan = planId
      ? await prisma.subscriptionPlan.findUnique({ where: { id: planId } })
      : await prisma.subscriptionPlan.findFirst({ where: { name: planType } });
    if (!plan || !plan.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Selected plan is not available',
      });
    }
    const fullPrice = Number(plan.monthlyPrice) * parseInt(durationMonths, 10);
    const quote = await validateAndComputeDiscount({
      prisma,
      couponCode: couponCode || null,
      fullPrice,
    });
    if (!quote.success) {
      return res.status(400).json({
        success: false,
        errorCode: quote.errorCode,
        message: quote.message,
      });
    }
    res.status(200).json({
      success: true,
      quote: {
        basePrice: quote.basePrice,
        discountAmount: quote.discountAmount,
        finalPrice: quote.finalPrice,
        appliedCouponCode: quote.appliedCouponCode || null,
        attribution: quote.attribution
          ? {
              agentName: quote.attribution.agentName,
              agentRole: quote.attribution.agentRole,
              message: `Referral discount from ${quote.attribution.agentName} (${quote.attribution.agentRole})`,
            }
          : null,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function createSubscription(req, res, next) {
  try {
    const { planType, planId, durationMonths, transactionId, couponCode } =
      req.body || {};
    if ((!planType && !planId) || !durationMonths) {
      return res.status(400).json({
        success: false,
        message: 'Plan type and duration are required',
      });
    }
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const plan = planId
      ? await prisma.subscriptionPlan.findUnique({ where: { id: planId } })
      : await prisma.subscriptionPlan.findFirst({ where: { name: planType } });
    if (!plan || !plan.isActive) {
      return res.status(400).json({ success: false, message: 'Selected plan is not available' });
    }
    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + parseInt(durationMonths, 10));
    const planSnapshot = buildPlanSnapshot(plan);
    const fullPrice = Number(plan.monthlyPrice) * parseInt(durationMonths, 10);

    const quote = await validateAndComputeDiscount({
      prisma,
      couponCode: couponCode || null,
      fullPrice,
    });
    if (!quote.success) {
      return res.status(400).json({
        success: false,
        errorCode: quote.errorCode,
        message: quote.message,
      });
    }

    const subscription = await subscriptionRepository.createSubscription({
      shopkeeperId,
      planId: plan.id,
      planSnapshot,
      status: 'active',
      startDate,
      endDate,
      actualPrice: quote.finalPrice,
      autoRenew: req.body.autoRenew || false,
      paymentStatus: 'paid',
      paymentMethod: req.body.paymentMethod,
      transactionId: transactionId || null,
      couponCode: quote.appliedCouponCode || null,
      discountAmount: quote.discountAmount,
      couponAgentIdSnapshot: quote.attribution?.agentId || null,
      couponAgentNameSnapshot: quote.attribution?.agentName || null,
      couponAgentRoleSnapshot: quote.attribution?.agentRole || null,
      couponCampaignSnapshot: null,
      notes: req.body.notes || '',
    });

    if (quote.appliedCouponCode) {
      await prisma.coupon.updateMany({
        where: { code: quote.appliedCouponCode },
        data: { currentUses: { increment: 1 } },
      });
      if (quote.attribution?.agentId) {
        await auditLogRepository.create({
          adminId: quote.attribution.agentId,
          adminRole: quote.attribution.agentRole || 'ssa',
          action: 'coupon_activated',
          targetUserId: shopkeeperId,
          targetUserRole: 'shopkeeper',
          details: {
            subscriptionId: subscription.id,
            couponCode: quote.appliedCouponCode,
            discountAmount: quote.discountAmount,
            finalPrice: quote.finalPrice,
          },
        });
      }
    }
    await upsertWalletForSubscription(subscription);
    await prisma.onboardingStatus.upsert({
      where: { userId: shopkeeperId },
      create: { userId: shopkeeperId, subscriptionActivated: true },
      update: { subscriptionActivated: true },
    });
    res.status(200).json({
      success: true,
      message: 'Subscription activated',
      subscription: serializeSubscription(subscription),
    });
  } catch (err) {
    next(err);
  }
}

async function cancelSubscription(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId },
      orderBy: { createdAt: 'desc' },
    });
    if (!subscription) return res.status(404).json({ success: false, message: 'No subscription found' });
    const updated = await subscriptionRepository.updateSubscription(subscription.id, {
      status: 'cancelled',
      autoRenew: false,
    });
    res.status(200).json({ success: true, message: 'Subscription cancelled', subscription: serializeSubscription(updated) });
  } catch (err) {
    next(err);
  }
}

async function getPlans(req, res, next) {
  try {
    const plans = await prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
    });
    res.status(200).json({
      success: true,
      plans: plans.map((plan) => ({
        id: plan.id,
        name: plan.displayName || plan.name,
        planType: plan.name,
        price: plan.monthlyPrice,
        duration: Math.max(1, Math.round((plan.durationDays || 30) / 30)),
        durationUnit: 'month',
        features: plan.features || [],
        maxOffers: plan.maxOffers,
        maxPhotosPerOffer: plan.maxPhotosPerOffer,
        category: plan.category,
      })),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getSubscription, activateTrial, getQuote, createSubscription, cancelSubscription, getPlans };
