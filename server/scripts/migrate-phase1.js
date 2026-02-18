const mongoose = require('mongoose');
const config = require('../src/config');
const User = require('../src/models/User');
const OnboardingStatus = require('../src/models/OnboardingStatus');
const Subscription = require('../src/models/Subscription');
const ShopkeeperProfile = require('../src/models/ShopkeeperProfile');

async function migrate() {
  try {
    await mongoose.connect(config.mongodbUri);
    console.log('Connected to MongoDB');

    // Step 1: Migrate admin to super_admin
    console.log('\n=== Step 1: Migrating admin users ===');
    const adminResult = await User.updateMany(
      { role: 'admin' },
      { 
        $set: { 
          role: 'super_admin',
          isActive: true,
          permissions: []
        } 
      }
    );
    console.log(`Migrated ${adminResult.modifiedCount} admin users to super_admin`);

    // Step 2: Create onboarding status for shopkeepers
    console.log('\n=== Step 2: Creating onboarding status ===');
    const shopkeepers = await User.find({ role: 'shopkeeper' });
    console.log(`Found ${shopkeepers.length} shopkeepers`);

    for (const shopkeeper of shopkeepers) {
      const profile = await ShopkeeperProfile.findOne({ userId: shopkeeper._id });
      
      await OnboardingStatus.findOneAndUpdate(
        { userId: shopkeeper._id },
        {
          userId: shopkeeper._id,
          businessProfileCompleted: !!profile && !!profile.shopName,
          termsAccepted: true,
          termsAcceptedAt: shopkeeper.createdAt,
          subscriptionActivated: true,
          onboardingCompleted: true,
          currentStep: 4,
        },
        { upsert: true }
      );
      
      console.log(`  ✓ Onboarding status created for ${shopkeeper.phone}`);
    }

    // Step 3: Create subscriptions
    console.log('\n=== Step 3: Creating subscriptions ===');
    for (const shopkeeper of shopkeepers) {
      const startDate = new Date();
      const endDate = new Date();
      endDate.setMonth(endDate.getMonth() + 3); // 3 months free for existing users
      
      await Subscription.findOneAndUpdate(
        { userId: shopkeeper._id },
        {
          userId: shopkeeper._id,
          planType: 'basic',
          status: 'active',
          startDate: startDate,
          endDate: endDate,
          autoRenew: false,
          paymentHistory: [{
            amount: 0,
            currency: 'INR',
            paymentDate: startDate,
            transactionId: `MIGRATION_${shopkeeper._id}`,
            status: 'success',
          }],
        },
        { upsert: true }
      );
      
      console.log(`  ✓ Subscription created for ${shopkeeper.phone}`);
    }

    console.log('\n=== Migration Complete ===');
    console.log(`Total shopkeepers migrated: ${shopkeepers.length}`);
    console.log('\nSummary:');
    console.log(`- Admin users migrated: ${adminResult.modifiedCount}`);
    console.log(`- Shopkeeper onboarding status created: ${shopkeepers.length}`);
    console.log(`- Shopkeeper subscriptions created: ${shopkeepers.length}`);
    
  } catch (error) {
    console.error('Migration error:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

// Run migration
migrate();
