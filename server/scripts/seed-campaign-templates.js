require('dotenv').config();
const { prisma } = require('../src/db/prisma');

const templates = [
  {
    name: 'Clothing Flash Sale',
    category: 'clothing',
    bannerUrl: 'https://placehold.co/1200x628/111217/00FF84?text=Clothing+Flash+Sale',
    description: 'Bold fashion layout for discount-driven apparel campaigns.',
    sortOrder: 1,
  },
  {
    name: 'Restaurant Special',
    category: 'restaurant',
    bannerUrl: 'https://placehold.co/1200x628/181A22/E8A838?text=Restaurant+Special',
    description: 'Food-focused hero banner for lunch and dinner offers.',
    sortOrder: 2,
  },
  {
    name: 'Electronics Launch',
    category: 'electronics',
    bannerUrl: 'https://placehold.co/1200x628/0A1220/4FC3F7?text=Electronics+Launch',
    description: 'Clean retail template for gadgets and devices.',
    sortOrder: 3,
  },
  {
    name: 'Salon Makeover',
    category: 'salon',
    bannerUrl: 'https://placehold.co/1200x628/1A1020/FF8FC7?text=Salon+Makeover',
    description: 'Beauty and grooming campaign layout with premium feel.',
    sortOrder: 4,
  },
  {
    name: 'Grocery Saver',
    category: 'grocery',
    bannerUrl: 'https://placehold.co/1200x628/122011/7DFF8A?text=Grocery+Saver',
    description: 'Value-first campaign creative for daily essentials.',
    sortOrder: 5,
  },
  {
    name: 'Universal Promo',
    category: 'all',
    bannerUrl: 'https://placehold.co/1200x628/101010/FFFFFF?text=Campaign+Template',
    description: 'Fallback campaign template for any category.',
    sortOrder: 99,
  },
];

async function run() {
  for (const template of templates) {
    await prisma.campaignTemplate.upsert({
      where: {
        id: (
          await prisma.campaignTemplate.findFirst({
            where: { name: template.name, category: template.category },
            select: { id: true },
          })
        )?.id || '00000000-0000-0000-0000-000000000000',
      },
      update: {
        bannerUrl: template.bannerUrl,
        description: template.description,
        sortOrder: template.sortOrder,
        isActive: true,
      },
      create: {
        name: template.name,
        category: template.category,
        bannerUrl: template.bannerUrl,
        description: template.description,
        sortOrder: template.sortOrder,
        isActive: true,
      },
    }).catch(async () => {
      const existing = await prisma.campaignTemplate.findFirst({
        where: { name: template.name, category: template.category },
      });
      if (existing) {
        await prisma.campaignTemplate.update({
          where: { id: existing.id },
          data: {
            bannerUrl: template.bannerUrl,
            description: template.description,
            sortOrder: template.sortOrder,
            isActive: true,
          },
        });
        return;
      }
      throw new Error(`Failed to seed template ${template.name}`);
    });
    console.log(`Seeded campaign template: ${template.name}`);
  }
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (error) => {
    console.error('Error seeding campaign templates:', error.message);
    await prisma.$disconnect();
    process.exit(1);
  });