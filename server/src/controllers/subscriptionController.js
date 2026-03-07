const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const subscriptionRepository = require('../repositories/subscriptionRepository');
const auditLogRepository = require('../repositories/auditLogRepository');
const { buildPlanSnapshot, upsertWalletForSubscription, getAvailableCredits } = require('../services/aiWalletService');
const { validateAndComputeDiscount } = require('../services/couponValidationService');

function ci(value) {
  return String(value || '').trim();
}

function serializeSubscription(subscription, wallet) {
  const base = {
    planType: subscription?.planSnapshot?.name || null,
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
    const [subscription, wallet] = await Promise.all([
      prisma.subscription.findFirst({
        where: { shopkeeperId },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.aiWallet.findUnique({
        where: { shopkeeperId },
      }),
    ]);
    res.status(200).json({ success: true, subscription: serializeSubscription(subscription, wallet) });
  } catch (err) {
    next(err);
  }
}

async function activateTrial(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId);
    const hasAny = await prisma.subscription.findFirst({ where: { shopkeeperId } });
    if (hasAny) return res.status(400).json({ success: false, message: 'Trial already used' });
    const trialPlan =
      (await prisma.subscriptionPlan.findFirst({ where: { isActive: true, monthlyPrice: 0 } })) ||
      (await prisma.subscriptionPlan.findFirst({
        where: { isActive: true },
        orderBy: [{ sortOrder: 'asc' }, { monthlyPrice: 'asc' }],
      }));
    if (!trialPlan) {
      return res.status(400).json({
        success: false,
        message: 'No active plan available for trial activation',
      });
    }
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 7);
    const planSnapshot = buildPlanSnapshot(trialPlan);
    const subscription = await subscriptionRepository.createSubscription({
      shopkeeperId,
      planId: trialPlan.id,
      planSnapshot,
      status: 'active',
      startDate,
      endDate,
      actualPrice: 0,
      autoRenew: false,
      paymentStatus: 'paid',
      notes: 'trial',
    });
    await upsertWalletForSubscription(subscription);
    await prisma.onboardingStatus.upsert({
      where: { userId: shopkeeperId },
      create: {
        userId: shopkeeperId,
        subscriptionActivated: true,
      },
      update: {
        subscriptionActivated: true,
      },
    });
    res.status(200).json({ success: true, message: 'Trial subscription activated', subscription: serializeSubscription(subscription) });
  } catch (err) {
    next(err);
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
