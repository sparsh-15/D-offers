require('dotenv').config();
const { prisma } = require('../src/db/prisma');

const MILESTONES = [
  { thresholdCoins: 10000, rewardAmountPaise: 100000, sortOrder: 1 },
  { thresholdCoins: 50000, rewardAmountPaise: 510000, sortOrder: 2 },
  { thresholdCoins: 100000, rewardAmountPaise: 1100000, sortOrder: 3 },
  { thresholdCoins: 500000, rewardAmountPaise: 5100000, sortOrder: 4 },
  { thresholdCoins: 1000000, rewardAmountPaise: 12100000, sortOrder: 5 },
];

const REWARD_RULES = {
  expiryDays: 90,
  amounts: {
    like_offer: 50,
    purchase_success: 50,
    sale_closed: 50,
    install_verified: 100,
  },
  limits: {
    likesPerDay: 20,
    customerDailyCoins: 300,
    shopkeeperDailyCoins: 1000,
  },
};

async function seedMilestones() {
  for (const milestone of MILESTONES) {
    await prisma.coinMilestoneDefinition.upsert({
      where: { thresholdCoins: milestone.thresholdCoins },
      update: {
        rewardAmountPaise: milestone.rewardAmountPaise,
        sortOrder: milestone.sortOrder,
        isActive: true,
      },
      create: {
        thresholdCoins: milestone.thresholdCoins,
        rewardAmountPaise: milestone.rewardAmountPaise,
        sortOrder: milestone.sortOrder,
        isActive: true,
      },
    });
  }
}

async function seedRewardRules() {
  await prisma.rewardConfig.upsert({
    where: { key: 'reward_rules' },
    update: {
      configValue: REWARD_RULES,
      version: { increment: 1 },
    },
    create: {
      key: 'reward_rules',
      configValue: REWARD_RULES,
      version: 1,
    },
  });
}

async function run() {
  console.log('Seeding reward milestones and config...');
  await seedMilestones();
  await seedRewardRules();

  const [milestones, config] = await Promise.all([
    prisma.coinMilestoneDefinition.count({ where: { isActive: true } }),
    prisma.rewardConfig.findUnique({ where: { key: 'reward_rules' } }),
  ]);

  console.log(`Active milestones: ${milestones}`);
  console.log(`Reward config version: ${config ? config.version : 'n/a'}`);
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
