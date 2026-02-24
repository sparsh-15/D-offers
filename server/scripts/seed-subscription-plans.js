require('dotenv').config();
const { prisma } = require('../src/db/prisma');

const initialPlans = [
  {
    name: 'basic',
    displayName: 'Basic Plan',
    description: 'Perfect for small shops getting started',
    monthlyPrice: 299,
    category: 'all',
    features: ['Up to 5 active offers', '3 photos per offer', 'Basic analytics', 'Email support'],
    maxOffers: 5,
    maxPhotosPerOffer: 3,
    analyticsEnabled: false,
    prioritySupport: false,
    isActive: true,
    sortOrder: 1,
  },
  {
    name: 'standard',
    displayName: 'Standard Plan',
    description: 'Great for growing businesses',
    monthlyPrice: 599,
    category: 'all',
    features: ['Up to 20 active offers', '5 photos per offer', 'Advanced analytics', 'Priority email support', 'Custom categories'],
    maxOffers: 20,
    maxPhotosPerOffer: 5,
    analyticsEnabled: true,
    prioritySupport: false,
    isActive: true,
    sortOrder: 2,
  },
  {
    name: 'premium',
    displayName: 'Premium Plan',
    description: 'For established businesses with high volume',
    monthlyPrice: 999,
    category: 'all',
    features: ['Unlimited active offers', '10 photos per offer', 'Advanced analytics with insights', '24/7 priority support', 'Custom categories', 'Featured placement', 'API access'],
    maxOffers: -1,
    maxPhotosPerOffer: 10,
    analyticsEnabled: true,
    prioritySupport: true,
    isActive: true,
    sortOrder: 3,
  },
];

async function run() {
  for (const plan of initialPlans) {
    const exists = await prisma.subscriptionPlan.findFirst({ where: { name: plan.name } });
    if (exists) {
      console.log(`Skipping existing plan: ${plan.displayName}`);
      continue;
    }
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

  const [totalPlans, activePlans] = await Promise.all([
    prisma.subscriptionPlan.count(),
    prisma.subscriptionPlan.count({ where: { isActive: true } }),
  ]);
  console.log(`Total plans: ${totalPlans}`);
  console.log(`Active plans: ${activePlans}`);
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('Error:', err.message);
    await prisma.$disconnect();
    process.exit(1);
  });
