# Testing Guide - D-Offers App

## Prerequisites
1. MongoDB connection (already configured in .env)
2. Node.js installed
3. Flutter installed

## Step 1: Start the Backend Server

```bash
cd server
npm install
npm start
```

You should see:
```
MongoDB connected
Server running on port 3000
```

## Step 2: Create Admin Account (Optional)

```bash
cd server
npm run seed:admin
```

This creates an admin with phone: 9999999999

## Step 3: Test Backend APIs (Optional)

```bash
node test-api.js
```

This will test:
- Signup endpoint
- Send OTP endpoint
- Verify OTP endpoint
- Get last OTP (dev endpoint)

## Step 4: Run Flutter App

```bash
cd client
flutter pub get
flutter run
```

## Testing Scenarios

### Scenario 1: New Customer Signup
1. Open app → Select "Customer"
2. Click "Register" (not Login)
3. Fill in:
   - Name: Test Customer
   - Phone: 9876543210
   - Pincode: 110001
   - Address: Test Address
4. Click "Send OTP"
5. Enter OTP: 999999 (master OTP)
6. Should navigate to Customer Dashboard

### Scenario 2: Existing Customer Login
1. Open app → Select "Customer"
2. Click "Login"
3. Enter Phone: 9876543210
4. Click "Send OTP"
5. Enter OTP: 999999
6. Should navigate to Customer Dashboard

### Scenario 3: New Customer Login (Should Fail)
1. Open app → Select "Customer"
2. Click "Login"
3. Enter Phone: 1111111111 (new number)
4. Click "Send OTP"
5. Should show error: "Account not found. Please signup first."

### Scenario 4: Shopkeeper Signup (Pending Approval)
1. Open app → Select "Shopkeeper"
2. Click "Register"
3. Fill in details
4. Click "Send OTP"
5. Enter OTP: 999999
6. Should show message: "Your shopkeeper account is pending. Please wait for admin approval."

### Scenario 5: Admin Login
1. First, seed admin: `npm run seed:admin`
2. Open app → Select "Admin"
3. Click "Login"
4. Enter Phone: 9999999999
5. Click "Send OTP"
6. Enter OTP: 999999
7. Should navigate to Admin Dashboard

### Scenario 6: Admin Approves Shopkeeper
1. Login as Admin
2. Go to "Pending Shopkeepers" tab
3. Click "Approve" on a shopkeeper
4. Shopkeeper can now login successfully

## Common Issues

### Issue: "Account not found" on Login
**Solution:** User needs to signup first. Click "Register" instead of "Login".

### Issue: "This phone is already registered as X"
**Solution:** User is trying to login with wrong role. Use the correct role they signed up with.

### Issue: "Shopkeeper account is pending"
**Solution:** Admin needs to approve the shopkeeper account first.

### Issue: Server not connecting
**Solution:** 
- Check if MongoDB URI is correct in server/.env
- Make sure server is running on port 3000
- For Android emulator, API uses 10.0.2.2:3000

## API Endpoints Reference

### Auth Endpoints
- POST /api/auth/signup - Register new user
- POST /api/auth/send-otp - Send OTP for login
- POST /api/auth/verify-otp - Verify OTP and get token
- GET /api/auth/me - Get current user info
- GET /api/auth/dev/last-otp?phone=XXX - Get last OTP (dev only)

### Customer Endpoints
- GET /api/customer/offers?pincode=XXX - Get offers by pincode

### Shopkeeper Endpoints
- GET /api/shopkeeper/profile - Get shop profile
- PUT /api/shopkeeper/profile - Update shop profile
- GET /api/shopkeeper/offers - Get my offers
- POST /api/shopkeeper/offers - Create offer
- PUT /api/shopkeeper/offers/:id - Update offer
- DELETE /api/shopkeeper/offers/:id - Delete offer

### Admin Endpoints
- GET /api/admin/shopkeepers?status=pending - Get shopkeepers
- PATCH /api/admin/shopkeepers/:id/approve - Approve shopkeeper
- PATCH /api/admin/shopkeepers/:id/reject - Reject shopkeeper

## Master OTP
For testing, use OTP: **999999**

This bypasses SMS and works for any phone number.
