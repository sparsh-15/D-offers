const { prisma } = require('../db/prisma');
const { resolvePgId } = require('../repositories/idResolver');
const { getAvailableCredits, deductAiCredit } = require('../services/aiWalletService');
const { generateBannerImageUrl } = require('../ai/bannerGenerator');

async function getAiWallet(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId) || req.user.userId;
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId, status: 'active' },
      orderBy: { createdAt: 'desc' },
    });
    if (!subscription) {
      return res.status(200).json({
        success: true,
        data: {
          hasSubscription: false,
          availableAiCredits: 0,
          usedThisCycle: 0,
          extraCreditsCurrentCycle: 0,
          monthlyLimit: 0,
          cycleEnd: null,
        },
      });
    }
    let wallet = await prisma.aiWallet.findUnique({
      where: { shopkeeperId },
    });
    if (!wallet || wallet.subscriptionId !== subscription.id) {
      return res.status(200).json({
        success: true,
        data: {
          hasSubscription: true,
          availableAiCredits: 0,
          usedThisCycle: 0,
          extraCreditsCurrentCycle: 0,
          monthlyLimit: subscription.planSnapshot?.monthlyAiLimit ?? 0,
          cycleEnd: subscription.endDate,
        },
      });
    }
    const available = getAvailableCredits(wallet);
    res.status(200).json({
      success: true,
      data: {
        hasSubscription: true,
        availableAiCredits: available,
        usedThisCycle: wallet.usedThisCycle,
        extraCreditsCurrentCycle: wallet.extraCreditsCurrentCycle,
        monthlyLimit: wallet.monthlyLimit,
        cycleStart: wallet.cycleStart,
        cycleEnd: wallet.cycleEnd,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getAiCreditPacks(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId) || req.user.userId;
    const [subscription, profile] = await Promise.all([
      prisma.subscription.findFirst({
        where: { shopkeeperId, status: 'active' },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.shopkeeperProfile.findUnique({
        where: { userId: shopkeeperId },
        select: { category: true },
      }),
    ]);
    const shopCategory = profile?.category?.trim() || null;
    const tier = subscription?.planSnapshot?.aiCreditTier || 'silver';
    const where = {
      isActive: true,
      OR: shopCategory
        ? [{ category: 'all' }, { category: shopCategory }]
        : [{ category: 'all' }],
    };
    const packs = await prisma.aiCreditPack.findMany({
      where,
      orderBy: [{ priceSilver: 'desc' }, { sortOrder: 'asc' }, { credits: 'asc' }],
    });
    const withPrice = packs.map((p) => {
      let price = Number(p.priceSilver);
      if (tier === 'gold') price = Number(p.priceGold);
      if (tier === 'platinum') price = Number(p.pricePlatinum);
      return {
        id: p.id,
        sku: p.sku,
        displayName: p.displayName,
        credits: p.credits,
        price,
        currency: 'INR',
      };
    });
    res.status(200).json({ success: true, data: withPrice });
  } catch (err) {
    next(err);
  }
}

async function purchaseAiCreditPack(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId) || req.user.userId;
    const { packSku, paymentMethod, transactionId } = req.body;
    if (!packSku) {
      return res.status(400).json({ success: false, message: 'packSku is required' });
    }
    const subscription = await prisma.subscription.findFirst({
      where: { shopkeeperId, status: 'active' },
      orderBy: { createdAt: 'desc' },
    });
    if (!subscription) {
      return res.status(403).json({ success: false, message: 'Active subscription required to purchase AI credit packs' });
    }
    const pack = await prisma.aiCreditPack.findFirst({
      where: { sku: String(packSku).trim().toLowerCase(), isActive: true },
    });
    if (!pack) {
      return res.status(404).json({ success: false, message: 'AI credit pack not found' });
    }
    const profile = await prisma.shopkeeperProfile.findUnique({
      where: { userId: shopkeeperId },
      select: { category: true },
    });
    const shopCategory = profile?.category?.trim() || null;
    const allowed = pack.category === 'all' || (shopCategory && pack.category === shopCategory);
    if (!allowed) {
      return res.status(403).json({ success: false, message: 'This pack is not available for your shop category' });
    }
    const tier = subscription.planSnapshot?.aiCreditTier || 'silver';
    let price = Number(pack.priceSilver);
    if (tier === 'gold') price = Number(pack.priceGold);
    if (tier === 'platinum') price = Number(pack.pricePlatinum);

    let wallet = await prisma.aiWallet.findUnique({
      where: { shopkeeperId },
    });
    if (!wallet) {
      wallet = await prisma.aiWallet.create({
        data: {
          shopkeeperId,
          subscriptionId: subscription.id,
          cycleStart: subscription.startDate,
          cycleEnd: subscription.endDate,
          monthlyLimit: subscription.planSnapshot?.monthlyAiLimit ?? 0,
          usedThisCycle: 0,
          extraCreditsCurrentCycle: 0,
        },
      });
    }
    if (wallet.subscriptionId !== subscription.id) {
      await prisma.aiWallet.update({
        where: { id: wallet.id },
        data: {
          subscriptionId: subscription.id,
          cycleStart: subscription.startDate,
          cycleEnd: subscription.endDate,
          monthlyLimit: subscription.planSnapshot?.monthlyAiLimit ?? 0,
          usedThisCycle: 0,
          extraCreditsCurrentCycle: 0,
        },
      });
    }

    await prisma.$transaction([
      prisma.aiCreditPurchase.create({
        data: {
          shopkeeperId,
          subscriptionId: subscription.id,
          packSku: pack.sku,
          credits: pack.credits,
          price,
          currency: 'INR',
          expiresAt: subscription.endDate,
        },
      }),
      prisma.aiWallet.update({
        where: { id: wallet.id },
        data: {
          extraCreditsCurrentCycle: (wallet.extraCreditsCurrentCycle || 0) + pack.credits,
        },
      }),
    ]);

    const updated = await prisma.aiWallet.findUnique({
      where: { shopkeeperId },
    });
    const available = getAvailableCredits(updated);
    res.status(200).json({
      success: true,
      message: 'AI credit pack purchased successfully',
      data: {
        availableAiCredits: available,
        usedThisCycle: updated.usedThisCycle,
        extraCreditsCurrentCycle: updated.extraCreditsCurrentCycle,
        cycleEnd: updated.cycleEnd,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function useAiBanner(req, res, next) {
  try {
    const shopkeeperId = await resolvePgId('users', req.user.userId) || req.user.userId;
    const result = await deductAiCredit(shopkeeperId);
    if (!result.ok) {
      return res.status(403).json({
        success: false,
        message: result.message,
        code: result.code || 'AI_CREDIT_DEDUCT_FAILED',
      });
    }
    res.status(200).json({ success: true, message: 'AI credit used successfully' });
  } catch (err) {
    next(err);
  }
}

async function generateBanner(req, res, next) {
  try {
    const shopkeeperId = (await resolvePgId('users', req.user.userId)) || req.user.userId;
    const { title, description, category, discountType, discountValue, shopName } = req.body || {};

    if (!title || typeof title !== 'string') {
      return res
        .status(400)
        .json({ success: false, message: 'title (string) is required' });
    }

    if (!discountType || !['percentage', 'fixed'].includes(String(discountType))) {
      return res.status(400).json({
        success: false,
        message: "discountType must be 'percentage' or 'fixed'",
      });
    }

    if (discountValue === undefined || discountValue === null || Number.isNaN(Number(discountValue))) {
      return res
        .status(400)
        .json({ success: false, message: 'discountValue (number) is required' });
    }

    const creditResult = await deductAiCredit(shopkeeperId);
    if (!creditResult.ok) {
      return res.status(403).json({
        success: false,
        message: creditResult.message || 'No AI credits available for banner generation',
        code: creditResult.code || 'AI_NO_CREDITS',
      });
    }

    const banner = await generateBannerImageUrl({
      title: String(title).trim().slice(0, 120),
      description: typeof description === 'string' ? description.trim().slice(0, 300) : '',
      category: typeof category === 'string' ? category.trim().slice(0, 80) : '',
      discountType: String(discountType),
      discountValue: Number(discountValue),
      shopName: typeof shopName === 'string' ? shopName.trim().slice(0, 120) : '',
    });

    res.status(200).json({
      success: true,
      data: {
        imageUrl: banner.imageUrl,
        altText: banner.altText,
        promptUsed: banner.promptUsed,
      },
    });
  } catch (err) {
    console.error('[AI_BANNER] Error generating banner:', err);
    next(err);
  }
}

module.exports = {
  getAiWallet,
  getAiCreditPacks,
  purchaseAiCreditPack,
  useAiBanner,
  generateBanner,
};
