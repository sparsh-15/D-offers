# Migration Guide: Phase 1 RBAC Implementation

## Overview
This guide helps you migrate from the old 3-role system (admin, shopkeeper, customer) to the new 6-role system with subscription and onboarding management.

## Database Migration

### Step 1: Update Existing Admin Users
All existing `admin` users should be migrated to `super_admin`:

```javascript
// Run in MongoDB shell or via migration script
db.users.updateMany(
  { role: 'admin' },
  { $set: { role: 'super_admin', isActive: true, permissions: [] } }
);
```

### Step 2: Create Onboarding Status for Existing Shopkeepers
All existing shopkeepers need onboarding status records:

```javascript
// Migration script
const User = require('./src/models/User');
const OnboardingStatus = require('./src/models/OnboardingStatus');
const ShopkeeperProfile = require('./src/models/ShopkeeperProfile');

async function migrateShopkeepers() {
  const shopkeepers = await User.find({ role: 'shopkeeper' });
  
  for (const shopkeeper of shopkeepers) {
    // Check if profile exists
    const profile = await ShopkeeperProfile.findOne({ userId: shopkeeper._id });
    
    // Create onboarding status
    await OnboardingStatus.findOneAndUpdate(
      { userId: shopkeeper._id },
      {
        userId: shopkeeper._id,
        businessProfileCompleted: !!profile && !!profile.shopName,
        termsAccepted: true, // Assume existing users accepted terms
        termsAcceptedAt: shopkeeper.createdAt,
        subscriptionActivated: true, // Will be set based on subscription
        onboardingCompleted: true,
        currentStep: 4,
      },
      { upsert: true }
    );
    
    console.log(`Migrated shopkeeper: ${shopkeeper.phone}`);
  }
}

migrateShopkeepers().then(() => console.log('Migration complete'));
```

### Step 3: Create Subscriptions for Existing Shopkeepers
Give existing shopkeepers active subscriptions:

```javascript
const Subscription = require('./src/models/Subscription');

async function createSubscriptions() {
  const shopkeepers = await User.find({ role: 'shopkeeper' });
  
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
    
    console.log(`Created subscription for: ${shopkeeper.phone}`);
  }
}

createSubscriptions().then(() => console.log('Subscriptions created'));
```

### Complete Migration Script

Save this as `server/scripts/migrate-phase1.js`:

```javascript
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
      endDate.setMonth(endDate.getMonth() + 3); // 3 months free
      
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
    
  } catch (error) {
    console.error('Migration error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

migrate();
```

## Running the Migration

1. **Backup your database first!**
   ```bash
   mongodump --uri="mongodb://localhost:27017/doffers" --out=./backup
   ```

2. **Run the migration script:**
   ```bash
   cd server
   node scripts/migrate-phase1.js
   ```

3. **Verify the migration:**
   ```bash
   # Check users
   db.users.find({ role: 'super_admin' }).count()
   
   # Check onboarding status
   db.onboardingstatuses.find().count()
   
   # Check subscriptions
   db.subscriptions.find({ status: 'active' }).count()
   ```

## Environment Variables

No new environment variables are required for Phase 1. The existing configuration works with the new system.

## API Changes

### Breaking Changes

1. **Role names changed:**
   - `admin` → `super_admin`
   - New roles: `subadmin`, `company_sales_agent`, `ssa`

2. **New endpoints:**
   - `GET /api/onboarding/status`
   - `POST /api/onboarding/accept-terms`
   - `POST /api/onboarding/complete-profile`
   - `POST /api/onboarding/complete`
   - `GET /api/subscription`
   - `GET /api/subscription/plans`
   - `POST /api/subscription/trial`
   - `POST /api/subscription/activate`
   - `POST /api/subscription/cancel`

3. **Shopkeeper routes now require:**
   - Onboarding completion
   - Active subscription

### Error Response Changes

New error codes added:
- `ONBOARDING_INCOMPLETE` - Redirect to onboarding
- `SUBSCRIPTION_INACTIVE` - Redirect to subscription page
- `NO_SUBSCRIPTION` - Redirect to subscription page

## Testing After Migration

### 1. Test Super Admin Access
```bash
# Login as super admin
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"ADMIN_PHONE","role":"super_admin"}'

# Verify OTP and get token
curl -X POST http://localhost:3000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"ADMIN_PHONE","otp":"123456","role":"super_admin"}'

# Test admin endpoints
curl -X GET http://localhost:3000/api/admin/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Test Existing Shopkeeper
```bash
# Login as shopkeeper
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"SHOPKEEPER_PHONE","role":"shopkeeper"}'

# Check onboarding status
curl -X GET http://localhost:3000/api/onboarding/status \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check subscription
curl -X GET http://localhost:3000/api/subscription \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test offer creation (should work if onboarding complete)
curl -X POST http://localhost:3000/api/shopkeeper/offers \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Offer","discountType":"percentage","discountValue":10}'
```

### 3. Test New Shopkeeper Signup
```bash
# Signup new shopkeeper
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone":"NEW_PHONE",
    "role":"shopkeeper",
    "name":"Test Shop",
    "pincode":"110001"
  }'

# After OTP verification, check onboarding
curl -X GET http://localhost:3000/api/onboarding/status \
  -H "Authorization: Bearer YOUR_TOKEN"
# Should return currentStep: 1 (business profile needed)
```

## Rollback Plan

If you need to rollback:

1. **Restore database from backup:**
   ```bash
   mongorestore --uri="mongodb://localhost:27017/doffers" ./backup/doffers
   ```

2. **Revert code changes:**
   ```bash
   git checkout main  # or your previous stable branch
   ```

3. **Restart server:**
   ```bash
   npm run dev
   ```

## Support

If you encounter issues during migration:

1. Check server logs for detailed error messages
2. Verify database connection
3. Ensure all new models are properly indexed
4. Check that existing data is in expected format

## Next Steps

After successful migration:

1. Update frontend to support new roles
2. Implement onboarding flow UI
3. Implement subscription management UI
4. Test all user flows end-to-end
5. Deploy to staging environment
6. Perform user acceptance testing
7. Deploy to production
