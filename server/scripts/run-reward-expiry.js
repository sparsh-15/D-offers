require('dotenv').config();
const { prisma } = require('../src/db/prisma');
const { expireCoinLotsBatch } = require('../src/services/rewardMaintenanceService');

async function run() {
  const batchSize = Number(process.env.REWARD_EXPIRY_BATCH_SIZE || 500);
  const result = await expireCoinLotsBatch(batchSize);
  console.log('Reward expiry run completed:', result);
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('Reward expiry run failed:', err.message);
    await prisma.$disconnect();
    process.exit(1);
  });
