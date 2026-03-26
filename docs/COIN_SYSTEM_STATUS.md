# Coin System Status

## What Is Done

### Backend
- Reward domain models added in Prisma for wallet, immutable ledger, reward events, lots/expiry, milestones, redemptions, config, and reconciliation runs.
- Reward routes added under `/rewards` and mounted in main route index.
- Role-based APIs implemented for:
  - Customer actions (`like`, `purchase-success`)
  - Shopkeeper actions (`sale-closed`, `install-verified`, milestones, redeem)
  - Wallet APIs (`me`, `ledger`, `expiry-summary`)
  - Admin APIs (`metrics`, `config`, `reversal`)
- Idempotency support added via request header (`Idempotency-Key`) and stable keys in client calls.
- Reward maintenance service added:
  - Expiry processing
  - Reconciliation processing
  - Scheduler integration in server startup/shutdown
- Migration for reward schema created and reward seed script added.

### Frontend
- Reward service client added in Flutter (`reward_service.dart`) with all major reward endpoints.
- Event capture layer added (`reward_event_capture.dart`) and one-line mixin helper (`reward_action_mixin.dart`).
- UI screens added:
  - Wallet screen
  - Shop rewards and milestones screen
  - Admin reward config screen
- Reward integration points added in customer and shopkeeper journeys (like/purchase/sale/install paths).

## Key Files

### Backend
- `server/prisma/schema.prisma`
- `server/prisma/migrations/20260325225930_coin_rewards_ledger_phase1/migration.sql`
- `server/src/services/rewardService.js`
- `server/src/services/rewardMaintenanceService.js`
- `server/src/controllers/rewardController.js`
- `server/src/routes/rewardRoutes.js`
- `server/src/routes/index.js`
- `server/index.js`
- `server/scripts/seed-reward-system.js`
- `server/scripts/run-reward-expiry.js`
- `server/scripts/run-reward-reconciliation.js`
- `server/package.json`

### Frontend
- `client/lib/services/reward_service.dart`
- `client/lib/services/reward_event_capture.dart`
- `client/lib/core/utils/reward_action_mixin.dart`
- `client/lib/screens/common/reward_wallet_screen.dart`
- `client/lib/screens/shopkeeper/shop_rewards_screen.dart`
- `client/lib/screens/admin/reward_config_screen.dart`

## How To Check

### 1) Backend Setup Check
1. Install dependencies:
   - `cd server`
   - `npm install`
2. Apply DB migration:
   - `npm run prisma:migrate`
3. Seed reward config and milestones:
   - `npm run seed:rewards`
4. Start server:
   - `npm run dev`

Expected:
- Server starts successfully.
- `/rewards` routes are reachable with auth.

### 2) API Functional Check
Use a valid JWT token per role and call these endpoints:

Customer:
- `POST /rewards/customer/like`
- `POST /rewards/customer/purchase-success`
- `GET /rewards/wallet/me`
- `GET /rewards/wallet/me/ledger`
- `GET /rewards/wallet/me/expiry-summary`

Shopkeeper:
- `POST /rewards/shopkeeper/sale-closed`
- `POST /rewards/shopkeeper/install-verified`
- `GET /rewards/shopkeeper/milestones/me`
- `POST /rewards/shopkeeper/milestones/:milestoneId/redeem`

Admin:
- `GET /rewards/admin/metrics`
- `GET /rewards/admin/config`
- `PUT /rewards/admin/config/:key`
- `POST /rewards/admin/reversal`

Expected:
- Credit actions increase wallet balance and append ledger rows.
- Duplicate idempotency calls return duplicate behavior (no double-credit).
- Reversal creates compensating debit entry.

### 3) Maintenance Jobs Check
From `server` folder:
- `npm run rewards:expire`
- `npm run rewards:reconcile`

Expected:
- Expiry job debits expired lots correctly.
- Reconciliation job reports checked wallets and heals mismatches if found.

### 4) Flutter Integration Check
1. `cd client`
2. `flutter pub get`
3. `flutter run`

Check role flows:
- Customer: like offer, unlock/purchase flow, wallet history view.
- Shopkeeper: sale/install trigger paths, milestones page, redeem action.
- Admin: reward config page loads and save works.

Expected:
- Coin balance and ledger update after reward events.
- Milestones show progress and redemption state.
- Admin config updates are reflected in subsequent reward behavior.

## Current Notes
- Recent RN-crash-specific bool parser patch was reverted; reward system implementation remains in place.
- A few non-blocking Flutter lint/deprecation warnings may still exist outside core reward flow.
