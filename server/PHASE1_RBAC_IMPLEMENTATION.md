# Phase 1: Role-Based Access Control (RBAC) Implementation

## Overview
This document outlines the complete RBAC system implementation for the D'Offers platform with 6 distinct roles and comprehensive access control.

## Roles

### 1. Super Admin (`super_admin`)
- **Full system access**
- Can manage all users, roles, and permissions
- Access to all dashboards and features
- Can create/modify subadmins
- System configuration access

### 2. Subadmin (`subadmin`)
- **Limited admin access**
- Can view stats and reports
- Can manage users (view only, no delete)
- Cannot modify system settings
- Cannot create other admins

### 3. Company Sales Agent (`company_sales_agent`)
- **Sales and revenue management**
- Track sales performance
- Manage contracts
- View revenue reports
- Target tracking

### 4. Sales Service Agent - SSA (`ssa`)
- **Shopkeeper relationship management**
- Manage assigned shopkeepers
- Track leads and conversions
- Commission tracking
- Performance metrics

### 5. Shopkeeper (`shopkeeper`)
- **Business owner access**
- Must complete onboarding (3 steps)
- Requires active subscription
- Create and manage offers
- View analytics
- Manage shop profile

### 6. Customer (`customer`)
- **End-user access**
- Browse offers
- Like/favorite offers
- View offer details
- No subscription required

## Authentication Flow

### JWT Token Structure
```javascript
{
  userId: "user_id",
  phone: "phone_number",
  role: "role_name"
}
```

### Token Validation
- All protected routes validate JWT token
- Token includes role information
- Middleware extracts user info from token
- Role-based access enforced at route level

## Shopkeeper Onboarding Flow

### Step 1: Business Profile Completion
- **Required Fields:**
  - Shop Name (mandatory)
  - Address
  - Pincode
  - City (auto-resolved)
  - Category
  - Description

- **API Endpoint:** `PUT /api/shopkeeper/profile`
- **Validation:** Shop name must be provided
- **Status Update:** `businessProfileCompleted = true`

### Step 2: Terms & Conditions Acceptance
- **Required Action:** Accept platform terms
- **API Endpoint:** `POST /api/onboarding/accept-terms`
- **Validation:** User must explicitly accept
- **Status Update:** `termsAccepted = true`, `termsAcceptedAt = timestamp`

### Step 3: Subscription Activation
- **Options:**
  - Activate 7-day free trial
  - Purchase paid subscription (Basic/Premium/Enterprise)

- **API Endpoints:**
  - `POST /api/subscription/trial` - Activate trial
  - `POST /api/subscription/activate` - Activate paid plan

- **Validation:** Payment verification for paid plans
- **Status Update:** `subscriptionActivated = true`, `onboardingCompleted = true`

### Onboarding Status Check
```javascript
GET /api/onboarding/status

Response:
{
  "success": true,
  "onboarding": {
    "currentStep": 1-4, // 4 means completed
    "businessProfileCompleted": boolean,
    "termsAccepted": boolean,
    "subscriptionActivated": boolean,
    "onboardingCompleted": boolean
  }
}
```

## Middleware Stack

### 1. Authentication Middleware (`authMiddleware`)
- **File:** `server/src/middleware/auth.js`
- **Purpose:** Validate JWT token
- **Extracts:** userId, phone, role
- **Errors:** 401 for invalid/expired tokens

### 2. Role Check Middleware (`requireRole`)
- **File:** `server/src/middleware/roleCheck.js`
- **Purpose:** Enforce role-based access
- **Functions:**
  - `requireRole(roles)` - Check specific role(s)
  - `requireAdmin()` - Allow super_admin or subadmin
  - `requireSuperAdmin()` - Super admin only

### 3. Onboarding Check Middleware (`requireOnboardingComplete`)
- **File:** `server/src/middleware/subscriptionCheck.js`
- **Purpose:** Ensure shopkeeper completed onboarding
- **Applies to:** Shopkeeper role only
- **Errors:** 403 with redirect to onboarding

### 4. Subscription Check Middleware (`requireActiveSubscription`)
- **File:** `server/src/middleware/subscriptionCheck.js`
- **Purpose:** Validate active subscription
- **Applies to:** Shopkeeper role only
- **Checks:**
  - Subscription exists
  - Status is 'active'
  - End date not expired
- **Errors:** 403 with redirect to subscription page

## Route Protection

### Public Routes
```javascript
POST /api/auth/send-otp
POST /api/auth/verify-otp
POST /api/auth/signup
GET  /api/offers (public offer listing)
```

### Customer Routes
```javascript
// Requires: auth + customer role
GET  /api/customer/offers
POST /api/customer/offers/:id/like
GET  /api/customer/offers/liked
```

### Shopkeeper Routes
```javascript
// Profile (no subscription required - for onboarding)
GET  /api/shopkeeper/profile
PUT  /api/shopkeeper/profile

// Offers (requires onboarding + subscription)
POST   /api/shopkeeper/offers
GET    /api/shopkeeper/offers
GET    /api/shopkeeper/offers/:id
PUT    /api/shopkeeper/offers/:id
DELETE /api/shopkeeper/offers/:id
```

### Onboarding Routes
```javascript
// Requires: auth + shopkeeper role
GET  /api/onboarding/status
POST /api/onboarding/accept-terms
POST /api/onboarding/complete-profile
POST /api/onboarding/complete
```

### Subscription Routes
```javascript
// Requires: auth + shopkeeper role
GET  /api/subscription
GET  /api/subscription/plans
POST /api/subscription/trial
POST /api/subscription/activate
POST /api/subscription/cancel
```

### Admin Routes
```javascript
// Requires: auth + (super_admin OR subadmin)
GET   /api/admin/stats
GET   /api/admin/users
GET   /api/admin/shopkeepers
PATCH /api/admin/shopkeepers/:id/approve
PATCH /api/admin/shopkeepers/:id/reject
```

### SSA Routes
```javascript
// Requires: auth + ssa role
GET /api/ssa/stats
GET /api/ssa/shopkeepers
```

### Company Sales Routes
```javascript
// Requires: auth + company_sales_agent role
GET /api/company-sales/stats
GET /api/company-sales/reports
```

### Subadmin Routes
```javascript
// Requires: auth + subadmin role
GET /api/subadmin/stats
GET /api/subadmin/users
```

## Subscription Plans

### Trial Plan
- **Duration:** 7 days
- **Price:** Free
- **Features:**
  - Create up to 5 offers
  - Basic analytics
  - 7 days access
- **Limitations:** One-time only per user

### Basic Plan
- **Duration:** 1 month
- **Price:** ₹499
- **Features:**
  - Unlimited offers
  - Basic analytics
  - Email support

### Premium Plan
- **Duration:** 1 month
- **Price:** ₹999
- **Features:**
  - Unlimited offers
  - Advanced analytics
  - Priority support
  - Featured listings

### Enterprise Plan
- **Duration:** 1 month
- **Price:** ₹2499
- **Features:**
  - Everything in Premium
  - Dedicated account manager
  - Custom integrations
  - API access

## Error Codes

### Authentication Errors
- `AUTH_REQUIRED` - No token provided
- `TOKEN_EXPIRED` - JWT token expired
- `INVALID_TOKEN` - JWT token invalid

### Authorization Errors
- `INSUFFICIENT_PERMISSIONS` - User role not allowed
- `ADMIN_ACCESS_REQUIRED` - Admin role required
- `SUPER_ADMIN_REQUIRED` - Super admin only

### Onboarding Errors
- `ONBOARDING_NOT_STARTED` - No onboarding record
- `ONBOARDING_INCOMPLETE` - Steps not completed
- `BUSINESS_PROFILE_REQUIRED` - Step 1 not done
- `TERMS_NOT_ACCEPTED` - Step 2 not done

### Subscription Errors
- `NO_SUBSCRIPTION` - No subscription found
- `SUBSCRIPTION_INACTIVE` - Subscription not active
- `SUBSCRIPTION_EXPIRED` - Subscription expired
- `TRIAL_ALREADY_USED` - Cannot activate trial again

## Database Models

### User Model
```javascript
{
  name: String,
  phone: String (unique),
  role: Enum (6 roles),
  pincode: String,
  city: String,
  state: String,
  address: String,
  approvalStatus: Enum (pending/approved/rejected),
  permissions: [String],
  isActive: Boolean,
  timestamps: true
}
```

### ShopkeeperProfile Model
```javascript
{
  userId: ObjectId (ref: User),
  shopName: String (required),
  address: String,
  pincode: String,
  city: String,
  category: String,
  description: String,
  timestamps: true
}
```

### Subscription Model
```javascript
{
  userId: ObjectId (ref: User, unique),
  planType: Enum (trial/basic/premium/enterprise),
  status: Enum (active/inactive/expired/cancelled),
  startDate: Date,
  endDate: Date,
  autoRenew: Boolean,
  paymentHistory: [{
    amount: Number,
    currency: String,
    paymentDate: Date,
    transactionId: String,
    status: Enum (success/failed/pending)
  }],
  timestamps: true
}
```

### OnboardingStatus Model
```javascript
{
  userId: ObjectId (ref: User, unique),
  businessProfileCompleted: Boolean,
  termsAccepted: Boolean,
  termsAcceptedAt: Date,
  subscriptionActivated: Boolean,
  onboardingCompleted: Boolean,
  currentStep: Number (1-4),
  timestamps: true
}
```

## Security Features

### 1. JWT Validation
- Token expiry enforced (7 days default)
- Signature verification
- Role information embedded in token

### 2. Role-Based Access Control
- Middleware enforces role at route level
- No frontend-only role checks
- Server-side validation on every request

### 3. Subscription Validation
- Checked on every protected shopkeeper route
- Automatic expiry detection
- Redirect to subscription page on failure

### 4. Onboarding Enforcement
- Sequential step validation
- Cannot skip steps
- Status persisted in database

### 5. Rate Limiting
- Applied to auth endpoints
- Different limits for admin vs regular users
- Prevents brute force attacks

## Frontend Integration Requirements

### 1. Role Enum Update
Update `client/lib/models/role_enum.dart`:
```dart
enum UserRole {
  super_admin,
  subadmin,
  company_sales_agent,
  ssa,
  shopkeeper,
  customer,
}
```

### 2. Onboarding Flow Screens
- Business Profile Screen
- Terms & Conditions Screen
- Subscription Selection Screen
- Onboarding Progress Indicator

### 3. Dashboard Routing
```dart
// After OTP verification
if (user.role == UserRole.shopkeeper) {
  // Check onboarding status
  final onboarding = await getOnboardingStatus();
  if (!onboarding.onboardingCompleted) {
    Navigator.pushReplacement(OnboardingScreen(step: onboarding.currentStep));
  } else {
    // Check subscription
    final subscription = await getSubscription();
    if (!subscription.isActive) {
      Navigator.pushReplacement(SubscriptionScreen());
    } else {
      Navigator.pushReplacement(ShopDashboard());
    }
  }
} else if (user.role == UserRole.customer) {
  Navigator.pushReplacement(CustomerDashboard());
} else if (user.role == UserRole.super_admin || user.role == UserRole.subadmin) {
  Navigator.pushReplacement(AdminDashboard());
} // ... other roles
```

### 4. Error Handling
```dart
// Handle subscription/onboarding errors
if (response.code == 'SUBSCRIPTION_INACTIVE') {
  Navigator.pushReplacement(SubscriptionScreen());
} else if (response.code == 'ONBOARDING_INCOMPLETE') {
  Navigator.pushReplacement(OnboardingScreen(step: response.currentStep));
}
```

## Testing Checklist

### Authentication
- [ ] JWT token generation and validation
- [ ] Token expiry handling
- [ ] Invalid token rejection
- [ ] Role information in token

### Role-Based Access
- [ ] Each role can only access allowed routes
- [ ] Cross-role access blocked
- [ ] Admin roles have elevated access
- [ ] Super admin has full access

### Shopkeeper Onboarding
- [ ] Cannot skip onboarding steps
- [ ] Business profile required before terms
- [ ] Terms required before subscription
- [ ] Subscription required before dashboard access

### Subscription Management
- [ ] Trial activation works
- [ ] Paid subscription activation works
- [ ] Expired subscription blocks access
- [ ] Inactive subscription redirects to subscription page

### Middleware
- [ ] Auth middleware validates tokens
- [ ] Role middleware enforces permissions
- [ ] Subscription middleware checks status
- [ ] Onboarding middleware validates completion

## Migration Notes

### Existing Users
- Existing `admin` role users should be migrated to `super_admin`
- Existing shopkeepers need onboarding status created
- Existing shopkeepers need subscription created (trial or active)

### Database Migration Script
```javascript
// Run this to migrate existing data
const User = require('./models/User');
const OnboardingStatus = require('./models/OnboardingStatus');
const Subscription = require('./models/Subscription');

async function migrate() {
  // Migrate admin to super_admin
  await User.updateMany(
    { role: 'admin' },
    { $set: { role: 'super_admin' } }
  );

  // Create onboarding status for existing shopkeepers
  const shopkeepers = await User.find({ role: 'shopkeeper' });
  for (const shopkeeper of shopkeepers) {
    await OnboardingStatus.findOneAndUpdate(
      { userId: shopkeeper._id },
      {
        userId: shopkeeper._id,
        businessProfileCompleted: true,
        termsAccepted: true,
        subscriptionActivated: true,
        onboardingCompleted: true,
        currentStep: 4,
      },
      { upsert: true }
    );

    // Create active subscription
    await Subscription.findOneAndUpdate(
      { userId: shopkeeper._id },
      {
        userId: shopkeeper._id,
        planType: 'basic',
        status: 'active',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
      { upsert: true }
    );
  }
}
```

## Next Steps (Phase 2)

1. **Payment Integration**
   - Razorpay/Stripe integration
   - Payment webhook handling
   - Auto-renewal logic

2. **Coupon System**
   - Coupon model and validation
   - Discount application
   - Usage tracking

3. **Advanced Analytics**
   - Offer performance metrics
   - User engagement tracking
   - Revenue reports

4. **Notification System**
   - Subscription expiry alerts
   - Offer approval notifications
   - Payment confirmations

5. **Advanced Permissions**
   - Granular permission system
   - Custom role creation
   - Permission inheritance
