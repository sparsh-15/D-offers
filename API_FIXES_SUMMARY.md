# API Fixes Summary

## Issues Fixed

### 1. Duplicate UserRole Enum (Compilation Error)
**Problem:** UserRole was defined in both `role_enum.dart` and `user_model.dart`, causing type conflicts.

**Fix:**
- Removed duplicate UserRole enum from `user_model.dart`
- Added import for `role_enum.dart` in `user_model.dart`
- Added import for `role_enum.dart` in `auth_service.dart`

### 2. Shop Dashboard Const Expression Error
**Problem:** `_ShopProfileBody` was private and used with const incorrectly.

**Fix:**
- Made `ShopProfileBody` public (removed underscore)
- Updated `shop_dashboard.dart` to use the public class
- Removed duplicate imports and unused code

### 3. Backend OTP Flow - 404 Error on Login
**Problem:** The backend's `sendOtp` function was trying to handle both signup AND login, but when a user tried to login without existing in the database, it threw a 404 error.

**Fix in `server/src/services/otpService.js`:**
- Split the logic to detect if it's a signup (has name/pincode) or login (no signup data)
- For LOGIN: Check if user exists, if not return 404 with "Account not found. Please signup first."
- For SIGNUP: Validate name and pincode are provided, create new user
- Admin cannot signup via API (must be seeded)

### 4. Shopkeeper Approval Status Blocking Login
**Problem:** Shopkeepers with pending/rejected status couldn't verify OTP.

**Fix:**
- Removed the approval status check from `verifyOtp` function
- Now shopkeepers can login regardless of approval status
- Frontend shows appropriate message based on approval status

## API Flow

### Signup Flow (New User)
1. User fills registration form with: name, phone, pincode, address
2. Frontend calls `POST /api/auth/signup` with all data
3. Backend creates user and sends OTP
4. User enters OTP
5. Frontend calls `POST /api/auth/verify-otp`
6. Backend verifies OTP and returns token

### Login Flow (Existing User)
1. User enters phone number only
2. Frontend calls `POST /api/auth/send-otp` with phone and role
3. Backend checks if user exists:
   - If exists: sends OTP
   - If not exists: returns 404 "Account not found. Please signup first."
4. User enters OTP
5. Frontend calls `POST /api/auth/verify-otp`
6. Backend verifies OTP and returns token

## Testing

### Start the Server
```bash
cd server
npm install
npm start
```

### Test the APIs
```bash
node test-api.js
```

### Run Flutter App
```bash
cd client
flutter pub get
flutter run
```

## Environment Setup

Make sure `server/.env` exists with:
- MONGODB_URI: Your MongoDB connection string
- JWT_SECRET: Secret key for JWT tokens
- MASTER_OTP: 999999 (for testing)
- NODE_ENV: development

## Master OTP for Testing
Use OTP: `999999` for quick testing without SMS.

## Admin Account
Create admin account:
```bash
cd server
npm run seed:admin
```

Default admin phone: 9999999999
