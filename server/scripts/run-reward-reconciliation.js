require('dotenv').config();
const { prisma } = require('../src/db/prisma');
const { reconcileCoinWalletsBatch } = require('../src/services/rewardMaintenanceService');

async function run() {
  const batchSize = Number(process.env.REWARD_RECON_BATCH_SIZE || 500);
  const result = await reconcileCoinWalletsBatch(batchSize);
  console.log('Reward reconciliation run completed:', result);
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('Reward reconciliation run failed:', err.message);
    await prisma.$disconnect();
    process.exit(1);
  });
