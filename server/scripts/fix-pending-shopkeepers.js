require('dotenv').config();
const { prisma } = require('../src/db/prisma');

async function run() {
  console.log('Starting pending shopkeepers cleanup...');

  const candidates = await prisma.user.findMany({
    where: {
      role: 'shopkeeper',
      approvalStatus: 'pending',
      isActive: true,
      OR: [
        {
          shopkeeperProfile: {
            shopName: { not: '' },
          },
        },
        {
          onboardingStatus: {
            businessProfileCompleted: true,
          },
        },
      ],
    },
    select: {
      id: true,
      phone: true,
      approvalStatus: true,
    },
  });

  if (!candidates.length) {
    console.log('No pending shopkeepers matched cleanup criteria.');
    return;
  }

  console.log(`Found ${candidates.length} pending shopkeepers to approve...`);

  const result = await prisma.user.updateMany({
    where: {
      id: { in: candidates.map((u) => u.id) },
    },
    data: {
      approvalStatus: 'approved',
    },
  });

  console.log(`Updated ${result.count} shopkeepers to approvalStatus = 'approved'.`);
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('Error during cleanup:', err);
    await prisma.$disconnect();
    process.exit(1);
  });

