/**
 * Script to seed initial subscription plans
 * Usage: node scripts/seed-subscription-plans.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const SubscriptionPlan = require('../src/models/SubscriptionPlan');
const config = require('../src/config');

const initialPlans = [
  {
    name: 'basic',
    displayName: 'Basic Plan',
    description: 'Perfect for small shops getting started',
    monthlyPrice: 299,
    categories: [], // Available for all categories
    features: [
      'Up to 5 active offers',
      '3 photos per offer',
      'Basic analytics',
      'Email support',
    ],
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
    categories: [], // Available for all categories
    features: [
      'Up to 20 active offers',
      '5 photos per offer',
      'Advanced analytics',
      'Priority email support',
      'Custom categories',
    ],
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
    categories: [], // Available for all categories
    features: [
      'Unlimited active offers',
      '10 photos per offer',
      'Advanced analytics with insights',
      '24/7 priority support',
      'Custom categories',
      'Featured placement',
      'API access',
    ],
    maxOffers: -1, // Unlimited
    maxPhotosPerOffer: 10,
    analyticsEnabled: true,
    prioritySupport: true,
    isActive: true,
    sortOrder: 3,
  },
  {
    name: 'restaurant_special',
    displayName: 'Restaurant Special',
    description: 'Tailored for restaurants and food businesses',
    monthlyPrice: 799,
    categories: ['restaurant', 'cafe', 'food', 'bakery'],
    features: [
      'Up to 30 active offers',
      '7 photos per offer',
      'Menu integration',
      'Advanced analytics',
      'Priority support',
      'Food category optimization',
    ],
    maxOffers: 30,
    maxPhotosPerOffer: 7,
    analyticsEnabled: true,
    prioritySupport: true,
    isActive: true,
    sortOrder: 4,
  },
  {
    name: 'retail_pro',
    displayName: 'Retail Pro',
    description: 'Designed for retail and fashion stores',
    monthlyPrice: 699,
    categories: ['retail', 'fashion', 'clothing', 'accessories', 'electronics'],
    features: [
      'Up to 25 active offers',
      '6 photos per offer',
      'Inventory hints',
      'Advanced analytics',
      'Priority support',
      'Seasonal campaign tools',
    ],
    maxOffers: 25,
    maxPhotosPerOffer: 6,
    analyticsEnabled: true,
    prioritySupport: true,
    isActive: true,
    sortOrder: 5,
  },
];

async function seedPlans() {
  try {
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(config.mongodbUri);
    console.log('✅ Connected to MongoDB');

    console.log('\n🌱 Seeding subscription plans...');

    for (const planData of initialPlans) {
      // Check if plan already exists
      const existing = await SubscriptionPlan.findOne({ name: planData.name });

      if (existing) {
        console.log(`⏭️  Plan "${planData.displayName}" already exists, skipping...`);
        continue;
      }

      // Create plan with initial price history
      const plan = await SubscriptionPlan.create({
        ...planData,
        priceHistory: [
          {
            price: planData.monthlyPrice,
            changedAt: new Date(),
            reason: 'Initial price',
          },
        ],
      });

      console.log(`✅ Created plan: ${plan.displayName} (₹${plan.monthlyPrice}/month)`);
    }

    console.log('\n📊 Summary:');
    const totalPlans = await SubscriptionPlan.countDocuments();
    const activePlans = await SubscriptionPlan.countDocuments({ isActive: true });
    console.log(`   Total plans: ${totalPlans}`);
    console.log(`   Active plans: ${activePlans}`);

    console.log('\n✨ Seeding completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('1. Review plans in database');
    console.log('2. Adjust pricing if needed via Super Admin dashboard');
    console.log('3. Create subscriptions for shopkeepers');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run the script
seedPlans();
