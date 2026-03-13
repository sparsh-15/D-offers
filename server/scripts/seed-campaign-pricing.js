require('dotenv').config();
const { prisma } = require('../src/db/prisma');

const pricingRows = [
  { channel: 'app_inbox', pricePerMessage: 0.5 },
  { channel: 'whatsapp', pricePerMessage: 1.0 },
];

async function run() {
  for (const row of pricingRows) {
    await prisma.campaignPricing.upsert({
      where: { channel: row.channel },
      update: {
        pricePerMessage: row.pricePerMessage,
        isActive: true,
      },
      create: {
        channel: row.channel,
        pricePerMessage: row.pricePerMessage,
        isActive: true,
      },
    });
    console.log(`Seeded campaign pricing: ${row.channel} -> INR ${row.pricePerMessage}`);
  }
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (error) => {
    console.error('Error seeding campaign pricing:', error.message);
    await prisma.$disconnect();
    process.exit(1);
  });