/**
 * Optional seed for D'Offers monetization: Silver/Gold/Platinum plans (category 'all')
 * and AI credit packs. Admin UI remains the source of truth; this provides initial data.
 * Run: node scripts/seed-monetization.js (from server directory, with .env loaded).
 */
require('dotenv').config();
const { prisma } = require('../src/db/prisma');

const PLANS = [
  {
    name: 'silver_all',
    displayName: 'Silver',
    description: 'For small shops getting started. Limited AI banners.',
    category: 'all',
    monthlyPrice: 299,
    durationDays: 30,
    maxOffers: 10,
    maxPhotosPerOffer: 5,
    monthlyAiLimit: 2,
    rankingTier: 'normal',
    homepageRotation: false,
    aiOptimizationSuggestions: false,
    aiCreditTier: 'silver',
    tier: 'silver',
    analyticsEnabled: false,
    prioritySupport: false,
    features: ['10 offers', '2 AI banners/month', 'Standard ranking', '5 photos per offer'],
    sortOrder: 1,
    isActive: true,
  },
  {
    name: 'gold_all',
    displayName: 'Gold',
    description: 'For growing businesses. More AI and priority ranking.',
    category: 'all',
    monthlyPrice: 599,
    durationDays: 30,
    maxOffers: -1,
    maxPhotosPerOffer: 5,
    monthlyAiLimit: 15,
    rankingTier: 'priority',
    homepageRotation: false,
    aiOptimizationSuggestions: false,
    aiCreditTier: 'gold',
    tier: 'gold',
    analyticsEnabled: true,
    prioritySupport: false,
    features: ['Unlimited offers', '15 AI banners/month', 'Priority ranking', '3 boost credits', 'Discounted AI packs'],
    sortOrder: 2,
    isActive: true,
  },
  {
    name: 'platinum_all',
    displayName: 'Platinum',
    description: 'For established businesses. Unlimited AI, top ranking, homepage rotation.',
    category: 'all',
    monthlyPrice: 999,
    durationDays: 30,
    maxOffers: -1,
    maxPhotosPerOffer: 10,
    monthlyAiLimit: -1,
    rankingTier: 'top3',
    homepageRotation: true,
    aiOptimizationSuggestions: true,
    aiCreditTier: 'platinum',
    tier: 'platinum',
    analyticsEnabled: true,
    prioritySupport: true,
    features: ['Unlimited offers', 'Unlimited AI banners', 'Top 3 ranking', 'Unlimited boosts', 'Homepage rotation', 'AI optimization suggestions', 'Best pack prices'],
    sortOrder: 3,
    isActive: true,
  },
];

const AI_PACKS = [
  { sku: 'starter', displayName: 'Starter', credits: 5, priceSilver: 49, priceGold: 44, pricePlatinum: 39, sortOrder: 1 },
  { sku: 'growth', displayName: 'Growth', credits: 10, priceSilver: 89, priceGold: 79, pricePlatinum: 69, sortOrder: 2 },
  { sku: 'business', displayName: 'Business', credits: 15, priceSilver: 129, priceGold: 114, pricePlatinum: 99, sortOrder: 3 },
  { sku: 'pro', displayName: 'Pro', credits: 30, priceSilver: 249, priceGold: 219, pricePlatinum: 189, sortOrder: 4 },
];

async function seedPlans() {
  for (const plan of PLANS) {
    const existing = await prisma.subscriptionPlan.findUnique({ where: { name: plan.name } });
    if (existing) {
      await prisma.subscriptionPlan.update({
        where: { id: existing.id },
        data: {
          displayName: plan.displayName,
          description: plan.description,
          category: plan.category,
          monthlyPrice: plan.monthlyPrice,
          durationDays: plan.durationDays,
          maxOffers: plan.maxOffers,
          maxPhotosPerOffer: plan.maxPhotosPerOffer,
          monthlyAiLimit: plan.monthlyAiLimit,
          rankingTier: plan.rankingTier,
          homepageRotation: plan.homepageRotation,
          aiOptimizationSuggestions: plan.aiOptimizationSuggestions,
          aiCreditTier: plan.aiCreditTier,
          tier: plan.tier,
          analyticsEnabled: plan.analyticsEnabled,
          prioritySupport: plan.prioritySupport,
          features: plan.features,
          sortOrder: plan.sortOrder,
          isActive: plan.isActive,
        },
      });
      console.log(`Updated plan: ${plan.displayName}`);
    } else {
      const created = await prisma.subscriptionPlan.create({ data: plan });
      await prisma.subscriptionPlanPriceHistory.create({
        data: {
          planId: created.id,
          price: created.monthlyPrice,
          reason: 'Initial price',
        },
      });
      console.log(`Created plan: ${created.displayName} (${created.monthlyPrice})`);
    }
  }
}

async function seedAiPacks() {
  for (const pack of AI_PACKS) {
    const existing = await prisma.aiCreditPack.findUnique({ where: { sku: pack.sku } });
    if (existing) {
      await prisma.aiCreditPack.update({
        where: { id: existing.id },
        data: {
          displayName: pack.displayName,
          credits: pack.credits,
          priceSilver: pack.priceSilver,
          priceGold: pack.priceGold,
          pricePlatinum: pack.pricePlatinum,
          sortOrder: pack.sortOrder,
          isActive: true,
        },
      });
      console.log(`Updated AI pack: ${pack.displayName}`);
    } else {
      await prisma.aiCreditPack.create({
        data: {
          sku: pack.sku,
          displayName: pack.displayName,
          credits: pack.credits,
          priceSilver: pack.priceSilver,
          priceGold: pack.priceGold,
          pricePlatinum: pack.pricePlatinum,
          sortOrder: pack.sortOrder,
          isActive: true,
        },
      });
      console.log(`Created AI pack: ${pack.displayName} (${pack.credits} credits)`);
    }
  }
}

async function run() {
  console.log('Seeding monetization: Silver/Gold/Platinum plans + AI credit packs...');
  await seedPlans();
  await seedAiPacks();
  const [planCount, packCount] = await Promise.all([
    prisma.subscriptionPlan.count({ where: { category: 'all', isActive: true } }),
    prisma.aiCreditPack.count({ where: { isActive: true } }),
  ]);
  console.log(`Done. Active plans (all): ${planCount}, active AI packs: ${packCount}`);
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('Error:', err);
    await prisma.$disconnect();
    process.exit(1);
  });
