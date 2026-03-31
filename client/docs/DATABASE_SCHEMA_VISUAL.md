# MyOffers Database Schema - Visual Reference

## Quick Reference Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MyOffers DATABASE SCHEMA                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│      USER        │         │ SHOPKEEPER       │         │   ONBOARDING     │
│                  │────1:1──│   PROFILE        │         │     STATUS       │
│ • _id (PK)       │         │                  │         │                  │
│ • phone (UK)     │         │ • _id (PK)       │         │ • _id (PK)       │
│ • email (UK)     │         │ • userId (FK)    │         │ • userId (FK)    │
│ • name           │         │ • shopName       │         │ • currentStep    │
│ • role           │         │ • category       │         │ • completed      │
│ • approvalStatus │         │ • onboardedBy    │         └──────────────────┘
│ • isActive       │         │   (FK → User)    │                 ▲
│ • region         │         └──────────────────┘                 │
│ • territory      │                 ▲                            1:1
└──────────────────┘                 │                             │
        │                            │                             │
        │ 1:N                        │ N:1                         │
        ▼                            │                             │
┌──────────────────┐                 │                             │
│   SUBSCRIPTION   │                 │                             │
│                  │                 │                             │
│ • _id (PK)       │                 │                             │
│ • shopkeeperId   │─────────────────┘                             │
│   (FK → User)    │                                               │
│ • planId         │──────┐                                        │
│   (FK → Plan)    │      │                                        │
│ • status         │      │ N:1                                    │
│ • couponCode     │      │                                        │
│ • discountAmount │      ▼                                        │
│ • startDate      │  ┌──────────────────┐                        │
│ • endDate        │  │ SUBSCRIPTION     │                        │
│ • cancelledBy    │  │     PLAN         │                        │
│   (FK → User)    │  │                  │                        │
└──────────────────┘  │ • _id (PK)       │                        │
        │             │ • name (UK)      │                        │
        │             │ • monthlyPrice   │                        │
        │ N:1         │ • category       │                        │
        │             │ • features[]     │                        │
        ▼             │ • maxOffers      │                        │
┌──────────────────┐  │ • isActive       │                        │
│     COUPON       │  │ • priceHistory[] │                        │
│                  │  └──────────────────┘                        │
│ • _id (PK)       │                                               │
│ • code (UK)      │                                               │
│ • discountType   │                                               │
│ • discountValue  │                                               │
│ • agentId        │───────────────────────────────────────────────┘
│   (FK → User)    │
│ • maxUses        │
│ • currentUses    │
│ • expiryDate     │
│ • isActive       │
└──────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│      OFFER       │         │    AUDIT LOG     │         │       OTP        │
│                  │         │                  │         │                  │
│ • _id (PK)       │         │ • _id (PK)       │         │ • _id (PK)       │
│ • shopkeeperId   │─────┐   │ • adminId (FK)   │─────┐   │ • phone          │
│   (FK → User)    │     │   │ • targetUserId   │     │   │ • otp            │
│ • title          │     │   │   (FK → User)    │     │   │ • expiresAt      │
│ • description    │     │   │ • action         │     │   │   (TTL Index)    │
│ • photos[]       │     │   │ • adminRole      │     │   └──────────────────┘
│ • category       │     │   │ • details        │     │
│ • discountType   │     │   │ • ipAddress      │     │
│ • discountValue  │     │   └──────────────────┘     │
│ • validFrom      │     │                            │
│ • validTo        │     │                            │
│ • status         │     │                            │
│ • likesCount     │     │                            │
│ • likedBy[]      │─────┴────────────────────────────┘
│   (FK → User)    │              N:1
└──────────────────┘
```

## Entity Cardinality Summary

| Relationship | Type | Description |
|-------------|------|-------------|
| User → ShopkeeperProfile | 1:1 | Each shopkeeper has one profile |
| User → OnboardingStatus | 1:1 | Each user has one onboarding status |
| User → Subscription | 1:N | Shopkeeper can have multiple subscriptions |
| User → Offer | 1:N | Shopkeeper creates multiple offers |
| User → Coupon | 1:N | Agent creates multiple coupons |
| User → AuditLog (admin) | 1:N | Admin performs multiple actions |
| User → AuditLog (target) | 1:N | User can be target of multiple actions |
| User ↔ Offer (likes) | M:N | Users can like multiple offers |
| User → ShopkeeperProfile (onboards) | 1:N | Agent onboards multiple shopkeepers |
| SubscriptionPlan → Subscription | 1:N | Plan used in multiple subscriptions |
| Subscription → Coupon | N:1 | Multiple subscriptions can use same coupon |

## Role-Based Entity Access

### Super Admin / Subadmin
```
┌─────────────┐
│   ADMIN     │
└─────────────┘
      │
      ├─── Can manage: User (all roles)
      ├─── Can manage: SubscriptionPlan
      ├─── Can manage: Subscription
      ├─── Can view: Offer
      ├─── Can view: Coupon
      ├─── Can view: ShopkeeperProfile
      ├─── Can view: OnboardingStatus
      └─── Creates: AuditLog
```

### Company Sales Agent / SSA
```
┌─────────────┐
│   AGENT     │
└─────────────┘
      │
      ├─── Can create: User (shopkeeper)
      ├─── Can create: ShopkeeperProfile (onboarding)
      ├─── Can create: Coupon
      ├─── Can view: Own onboarded shopkeepers
      └─── Tracked in: ShopkeeperProfile.onboardedBy
```

### Shopkeeper
```
┌─────────────┐
│ SHOPKEEPER  │
└─────────────┘
      │
      ├─── Has: ShopkeeperProfile (1:1)
      ├─── Has: OnboardingStatus (1:1)
      ├─── Has: Subscription (1:N)
      ├─── Creates: Offer (1:N)
      └─── Can like: Offer (M:N)
```

### Customer
```
┌─────────────┐
│  CUSTOMER   │
└─────────────┘
      │
      ├─── Can view: Offer
      └─── Can like: Offer (M:N)
```

## Data Flow Diagrams

### Shopkeeper Onboarding Flow
```
┌─────────┐     ┌──────────┐     ┌─────────────┐     ┌──────────────┐
│  Agent  │────▶│   User   │────▶│  Shopkeeper │────▶│  Onboarding  │
│ Creates │     │ (pending)│     │   Profile   │     │    Status    │
└─────────┘     └──────────┘     └─────────────┘     └──────────────┘
                     │                                        │
                     │ Admin Approves                        │
                     ▼                                        ▼
                ┌──────────┐                          ┌──────────────┐
                │   User   │                          │ Subscription │
                │(approved)│◀─────────────────────────│   Created    │
                └──────────┘                          └──────────────┘
```

### Subscription Creation Flow
```
┌────────────┐     ┌──────────────┐     ┌──────────────┐
│ Shopkeeper │────▶│ Subscription │────▶│   Payment    │
│  Selects   │     │   (pending)  │     │   Process    │
│    Plan    │     └──────────────┘     └──────────────┘
└────────────┘            │                     │
                          │                     │ Success
                          ▼                     ▼
                    ┌──────────────┐     ┌──────────────┐
                    │    Coupon    │     │ Subscription │
                    │  (optional)  │────▶│   (active)   │
                    └──────────────┘     └──────────────┘
```

### Offer Creation & Interaction Flow
```
┌────────────┐     ┌──────────┐     ┌──────────┐
│ Shopkeeper │────▶│  Offer   │◀────│ Customer │
│  Creates   │     │ (active) │     │  Views   │
└────────────┘     └──────────┘     └──────────┘
                         │                 │
                         │                 │ Likes
                         ▼                 ▼
                   ┌──────────┐     ┌──────────┐
                   │  Offer   │     │  Offer   │
                   │ likedBy[]│◀────│likesCount│
                   └──────────┘     └──────────┘
```

## Index Strategy

### High-Priority Indexes (Frequent Queries)
```
User:
  ├─ phone (unique) ────────────── Login, User lookup
  ├─ email (sparse, unique) ────── Email-based operations
  └─ role + approvalStatus ──────── Admin dashboards

Subscription:
  ├─ shopkeeperId ──────────────── User's subscriptions
  ├─ status ────────────────────── Active subscriptions query
  ├─ endDate ───────────────────── Expiry checks
  └─ planId ────────────────────── Plan-based queries

Offer:
  ├─ shopkeeperId ──────────────── Shopkeeper's offers
  ├─ status ────────────────────── Active offers
  └─ validTo ───────────────────── Expiry checks

Coupon:
  ├─ code (unique) ─────────────── Coupon validation
  ├─ agentId ───────────────────── Agent's coupons
  └─ isActive ──────────────────── Active coupons
```

### Medium-Priority Indexes
```
ShopkeeperProfile:
  ├─ userId (unique) ───────────── Profile lookup
  └─ category ──────────────────── Category-based queries

SubscriptionPlan:
  ├─ name (unique) ─────────────── Plan lookup
  ├─ isActive ──────────────────── Active plans
  └─ category ──────────────────── Category-specific plans

AuditLog:
  ├─ adminId + createdAt ───────── Admin activity log
  ├─ targetUserId ──────────────── User activity log
  └─ action ────────────────────── Action-based queries
```

### TTL Indexes (Auto-Cleanup)
```
Otp:
  └─ expiresAt (TTL) ───────────── Auto-delete expired OTPs
```

## Data Validation Rules

### User
- `phone`: Required, unique, 10 digits
- `role`: Must be one of defined ROLES
- `approvalStatus`: Auto-set based on role
- `email`: Optional but unique when present

### Subscription
- `actualPrice`: Must be ≥ 0
- `discountAmount`: Must be ≥ 0 and ≤ actualPrice
- `endDate`: Must be > startDate
- `status`: Validated enum values

### Coupon
- `code`: Uppercase, unique
- `discountValue`: Must be > 0
- `discountType`: 'percentage' (0-100) or 'fixed'
- `currentUses`: Must be ≤ maxUses (if maxUses is set)

### Offer
- `validTo`: Must be > validFrom
- `discountValue`: Required if discountType is set
- `photos`: Max array length based on subscription plan

## Security Considerations

### Sensitive Fields
```
User.password:
  ├─ Hashed using bcrypt
  ├─ select: false (excluded from queries)
  └─ Never returned in API responses

User.email:
  ├─ Sparse index (optional field)
  └─ Validated format

Otp.otp:
  ├─ Temporary storage only
  ├─ Auto-deleted via TTL
  └─ Never logged
```

### Access Control
```
Role Hierarchy:
  super_admin > subadmin > company_sales_agent = ssa > shopkeeper > customer

Field-Level Access:
  ├─ User.password: Never readable
  ├─ User.permissions: Admin-only
  ├─ AuditLog: Admin-only
  └─ Subscription.paymentMethod: Owner + Admin only
```

## Performance Optimization

### Denormalized Fields
```
Subscription.planSnapshot:
  Purpose: Historical accuracy
  Benefit: No need to join with SubscriptionPlan for historical data

Offer.likesCount:
  Purpose: Cached count
  Benefit: Avoid counting likedBy array on every query

Subscription.couponCode:
  Purpose: Direct reference
  Benefit: Faster coupon tracking without join
```

### Virtual Fields
```
Subscription.daysUntilExpiry:
  Computed: (endDate - now) / (1000 * 60 * 60 * 24)
  Not stored: Calculated on-demand
```

### Aggregation Pipelines
```
Common Aggregations:
  ├─ Active subscriptions by plan
  ├─ Offers by category
  ├─ Agent performance (onboarding count)
  ├─ Coupon usage statistics
  └─ Revenue by time period
```
