# Mongo Schema History (Archived)

This file preserves the legacy MongoDB schema for reference after PostgreSQL migration.

## Collections

### `users`
- Fields: `name`, `email`, `phone`, `password`, `role`, `pincode`, `city`, `state`, `region`, `territory`, `address`, `approvalStatus`, `permissions`, `isActive`, timestamps
- Indexes:
  - `phone` unique
  - `email` sparse
  - `(role, approvalStatus)`

### `shopkeeperprofiles`
- Fields: `userId`, `shopName`, `address`, `pincode`, `city`, `category`, `description`, `onboardedBy`, timestamps
- Indexes:
  - `userId` unique
  - `category`

### `offers`
- Fields: `shopkeeperId`, `title`, `description`, `photos[]`, `termsAndConditions`, `category`, `discountType`, `discountValue`, `validFrom`, `validTo`, `status`, `likesCount`, `likedBy[]`, timestamps
- Indexes:
  - `shopkeeperId`
  - `status`
  - `validTo`

### `subscriptionplans`
- Fields: `name`, `displayName`, `description`, `monthlyPrice`, `durationDays`, `category`, `features[]`, `maxOffers`, `maxPhotosPerOffer`, `analyticsEnabled`, `prioritySupport`, `isActive`, `sortOrder`, `priceHistory[]`, timestamps
- Indexes:
  - `name` unique
  - `isActive`
  - `category`

### `subscriptions`
- Fields: `shopkeeperId`, `planId`, `planSnapshot`, `status`, `startDate`, `endDate`, `actualPrice`, `autoRenew`, `paymentStatus`, `paymentMethod`, `transactionId`, `couponCode`, `discountAmount`, `renewalCount`, `lastRenewalDate`, `cancelledAt`, `cancelledBy`, `cancellationReason`, `notes`, timestamps
- Indexes:
  - `shopkeeperId`
  - `status`
  - `endDate`
  - `planId`

### `coupons`
- Fields: `code`, `discountType`, `discountValue`, `agentId`, `description`, `expiryDate`, `maxUses`, `currentUses`, `isActive`, timestamps
- Indexes:
  - `code` unique
  - `agentId`
  - `isActive`

### `onboardingstatuses`
- Fields: `userId`, `businessProfileCompleted`, `termsAccepted`, `termsAcceptedAt`, `subscriptionActivated`, `onboardingCompleted`, `currentStep`, timestamps
- Indexes:
  - `userId` unique

### `otps`
- Fields: `phone`, `otp`, `expiresAt`, timestamps
- Indexes:
  - `phone`
  - TTL on `expiresAt`

### `auditlogs`
- Fields: `adminId`, `adminRole`, `action`, `targetUserId`, `targetUserRole`, `details`, `ipAddress`, timestamps
- Indexes:
  - `(adminId, createdAt desc)`
  - `targetUserId`
  - `action`

## Legacy Notes
- Legacy ObjectId-based relations were mapped into PostgreSQL UUID FKs.
- `Offer.likedBy[]` was normalized into relational `offer_likes`.
- OTP TTL is now replaced by scheduled cleanup in PostgreSQL.
