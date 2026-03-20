require('dotenv').config();
const { prisma } = require('../src/db/prisma');

const PACKAGE_BENEFITS = {
  platinum: {
    freeSubscriptionDays: 30,
    freeBannersPerMonth: 1,
    freeWhatsappMessagesPerMonth: 200,
  },
  gold: {
    freeSubscriptionDays: 15,
    freeBannersPerMonth: 1,
    freeWhatsappMessagesPerMonth: 100,
  },
  silver: {
    freeSubscriptionDays: 7,
    freeBannersPerMonth: 1,
    freeWhatsappMessagesPerMonth: 50,
  },
};

const CATEGORY_PRICING_DRAFT = [
  { category: 'Jewellery Stores', avgTicketSize: 'Very High', platinumPrice: 4999, goldPrice: 2499, silverPrice: 999, suggestedInternalCategory: 'jewelry' },
  { category: 'Automobile Dealers', avgTicketSize: 'Very High', platinumPrice: 4999, goldPrice: 2499, silverPrice: 999, suggestedInternalCategory: 'automotive' },
  { category: 'Real Estate Brokers', avgTicketSize: 'Very High', platinumPrice: 4999, goldPrice: 2499, silverPrice: 999, suggestedInternalCategory: 'other' },
  { category: 'Furniture Stores', avgTicketSize: 'High', platinumPrice: 4999, goldPrice: 2499, silverPrice: 999, suggestedInternalCategory: 'retail' },
  { category: 'Electronics & Mobile Stores', avgTicketSize: 'High', platinumPrice: 4999, goldPrice: 2499, silverPrice: 999, suggestedInternalCategory: 'electronics' },
  { category: 'Home Decor Stores', avgTicketSize: 'High', platinumPrice: 4999, goldPrice: 2499, silverPrice: 999, suggestedInternalCategory: 'home_services' },
  { category: 'Fashion & Apparel Stores', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'clothing' },
  { category: 'Footwear Stores', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'retail' },
  { category: 'Restaurants & Cafes', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'restaurant' },
  { category: 'Beauty Salons', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'beauty_salon' },
  { category: 'Spa & Wellness Centers', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'beauty_salon' },
  { category: 'Gyms & Fitness Centers', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'gym_fitness' },
  { category: 'Clinics & Diagnostic Centers', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'healthcare' },
  { category: 'Hardware & Building Material Stores', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'home_services' },
  { category: 'Pet Shops', avgTicketSize: 'Medium', platinumPrice: 2499, goldPrice: 999, silverPrice: 499, suggestedInternalCategory: 'pet_care' },
  { category: 'Grocery / Kirana Stores', avgTicketSize: 'Low', platinumPrice: 999, goldPrice: 499, silverPrice: 199, suggestedInternalCategory: 'grocery' },
  { category: 'Medical Stores / Pharmacies', avgTicketSize: 'Low', platinumPrice: 999, goldPrice: 499, silverPrice: 199, suggestedInternalCategory: 'pharmacy' },
  { category: 'Stationery & Book Stores', avgTicketSize: 'Low', platinumPrice: 999, goldPrice: 499, silverPrice: 199, suggestedInternalCategory: 'books_stationery' },
  { category: 'Gift Shops', avgTicketSize: 'Low', platinumPrice: 999, goldPrice: 499, silverPrice: 199, suggestedInternalCategory: 'retail' },
  { category: 'Toy Stores', avgTicketSize: 'Low', platinumPrice: 999, goldPrice: 499, silverPrice: 199, suggestedInternalCategory: 'retail' },
];

const TRIAL_WHATSAPP_CAPS = {
  jewelry: 100,
  automotive: 100,
  electronics: 75,
  home_services: 75,
  retail: 60,
  restaurant: 60,
  beauty_salon: 60,
  gym_fitness: 60,
  healthcare: 60,
  clothing: 60,
  grocery: 50,
  pharmacy: 50,
  books_stationery: 50,
  pet_care: 50,
  other: 60,
};

async function upsertSetting(key, value) {
  await prisma.appSetting.upsert({
    where: { key },
    update: { value },
    create: { key, value },
  });
}

async function run() {
  const payload = {
    version: 'v1',
    generatedAt: new Date().toISOString(),
    note: 'Draft pricing dataset from client-provided sheet. Not applied to live SubscriptionPlan rows by default.',
    packageBenefits: PACKAGE_BENEFITS,
    rows: CATEGORY_PRICING_DRAFT,
  };

  await upsertSetting('category_pricing_draft_v1', JSON.stringify(payload));
  await upsertSetting('trial_whatsapp_caps_v1', JSON.stringify(TRIAL_WHATSAPP_CAPS));

  console.log(`Saved ${CATEGORY_PRICING_DRAFT.length} category pricing rows to app_settings.category_pricing_draft_v1`);
  console.log('Saved category-wise trial WhatsApp caps to app_settings.trial_whatsapp_caps_v1');
}

run()
  .then(async () => {
    await prisma.$disconnect();
    process.exit(0);
  })
  .catch(async (error) => {
    console.error('Failed to seed category pricing draft:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
