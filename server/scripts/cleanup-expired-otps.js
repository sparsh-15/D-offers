require('dotenv').config();
const { prisma } = require('../src/db/prisma');

async function cleanup() {
  const now = new Date();
  const result = await prisma.otp.deleteMany({
    where: { expiresAt: { lt: now } },
  });
  console.log(`[OTP_CLEANUP] expired records removed: ${result.count}`);
}

cleanup()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('[OTP_CLEANUP] failed:', err);
    await prisma.$disconnect();
    process.exit(1);
  });
