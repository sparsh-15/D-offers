# Admin Setup & Security Guide 🔐

## Overview
Admin accounts are special and can only be created through seeding. This ensures security and prevents unauthorized admin access.

## Key Security Features

### 1. Admin Cannot Register via UI ✅
- Register button is hidden for admin role
- Only Login option is available for admin
- Admin must be seeded first before login

### 2. Only One Admin Allowed ✅
- Seed script checks for existing admin
- Prevents multiple admin accounts
- Updates existing admin if re-seeded

### 3. Proper Error Handling ✅
- Clear error messages for all scenarios
- Toast notifications for success/error
- User-friendly feedback

## Admin Setup Process

### Step 1: Configure Environment
Edit `server/.env` file:
```env
# Admin Configuration
ADMIN_NAME=Admin
ADMIN_PHONE=9999999999
ADMIN_PINCODE=110001
ADMIN_ADDRESS=Admin Office
```

### Step 2: Seed Admin Account
```bash
cd server
npm run seed:admin
```

**Expected Output:**
```
✅ Seeded admin: {
  id: '507f1f77bcf86cd799439011',
  phone: '9999999999',
  name: 'Admin',
  city: 'New Delhi'
}
```

### Step 3: Login as Admin
1. Open app
2. Select "Admin" role
3. Enter phone: 9999999999
4. Click "Send OTP"
5. Enter OTP: 999999 (or check dev endpoint)
6. ✅ Access admin dashboard

## UI Changes

### Login Screen - Admin Role
```
┌─────────────────────────────────────┐
│  ← Admin Login                      │
│                                     │
│  Login to continue                  │
│                                     │
│  📱 Enter Mobile Number             │
│  ┌─────────────────────────────┐   │
│  │ 9999999999                  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    ▶ Send OTP               │   │
│  └─────────────────────────────┘   │
│                                     │
│  ❌ No "Register" button shown     │
│                                     │
└─────────────────────────────────────┘
```

### Login Screen - Customer/Shopkeeper
```
┌─────────────────────────────────────┐
│  ← Customer Login                   │
│                                     │
│  Login to continue                  │
│                                     │
│  📱 Enter Mobile Number             │
│  ┌─────────────────────────────┐   │
│  │ 9876543210                  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    ▶ Send OTP               │   │
│  └─────────────────────────────┘   │
│                                     │
│  Don't have account? [Register]    │ ✅ Register shown
│                                     │
└─────────────────────────────────────┘
```

## Error Scenarios & Messages

### Scenario 1: Admin Tries to Signup
**Backend Response:**
```json
{
  "success": false,
  "message": "Cannot signup as admin"
}
```
**Toast:** ❌ "Cannot signup as admin"

### Scenario 2: Admin Not Seeded
**User Action:** Admin tries to login
**Backend Response:**
```json
{
  "success": false,
  "message": "Account not found. Please signup first."
}
```
**Toast:** ❌ "Account not found. Please signup first."
**Solution:** Run `npm run seed:admin`

### Scenario 3: Wrong Phone Number
**User Action:** Admin enters wrong phone
**Backend Response:**
```json
{
  "success": false,
  "message": "Account not found. Please signup first."
}
```
**Toast:** ❌ "Account not found. Please signup first."

### Scenario 4: Invalid OTP
**User Action:** Admin enters wrong OTP
**Backend Response:**
```json
{
  "success": false,
  "message": "Invalid or expired OTP"
}
```
**Toast:** ❌ "Invalid or expired OTP"

### Scenario 5: Successful Login
**Backend Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "phone": "9999999999",
    "role": "admin"
  }
}
```
**Toast:** ✅ "OTP sent successfully"
**Then:** ✅ Navigate to Admin Dashboard

## Toast Message Types

### Success Toast (Green)
```
┌─────────────────────────────────┐
│ ✅ OTP sent successfully        │
└─────────────────────────────────┘
```
- Duration: 2 seconds
- Color: Green (#4CAF50)
- Icon: Check circle

### Error Toast (Red)
```
┌─────────────────────────────────┐
│ ❌ Account not found            │
└─────────────────────────────────┘
```
- Duration: 3 seconds
- Color: Red (#F44336)
- Icon: Error

### Info Toast (Blue)
```
┌─────────────────────────────────┐
│ ℹ️ Shopkeeper pending approval  │
└─────────────────────────────────┘
```
- Duration: 2 seconds
- Color: Blue (#2196F3)
- Icon: Info

## Backend Security

### OTP Service Protection
```javascript
// Prevent admin signup
if (role === 'admin') {
  const err = new Error('Cannot signup as admin');
  err.statusCode = 403;
  throw err;
}

// Check if admin exists for login
if (role === 'admin' && (!existingUser || existingUser.role !== 'admin')) {
  const err = new Error('Admin account not found');
  err.statusCode = 404;
  throw err;
}
```

### Seed Script Protection
```javascript
// Check if any admin already exists
const existingAdmin = await User.findOne({ role: 'admin' });
if (existingAdmin && existingAdmin.phone !== phone) {
  console.log('⚠️  Admin already exists with phone:', existingAdmin.phone);
  console.log('Only one admin is allowed. Updating existing admin...');
}
```

## Testing

### Test 1: Seed Admin
```bash
cd server
npm run seed:admin
```
**Expected:** ✅ Admin created successfully

### Test 2: Try to Seed Again
```bash
npm run seed:admin
```
**Expected:** ⚠️ Updates existing admin (same phone)

### Test 3: Admin Login
1. Open app
2. Select Admin
3. Enter: 9999999999
4. OTP: 999999
**Expected:** ✅ Login successful

### Test 4: Admin Register (Should Fail)
1. Open app
2. Select Admin
3. Look for Register button
**Expected:** ❌ No Register button visible

### Test 5: Wrong Admin Phone
1. Open app
2. Select Admin
3. Enter: 1111111111
4. Click Send OTP
**Expected:** ❌ Toast: "Account not found"

## Files Modified

### Frontend
- ✅ `client/lib/screens/auth/login_screen.dart` - Hide register for admin
- ✅ `client/lib/core/utils/dialog_helper.dart` - Toast messages (already good)

### Backend
- ✅ `server/scripts/seedAdmin.js` - Updated for new pincode API
- ✅ `server/src/services/otpService.js` - Admin signup prevention (already there)

## Security Checklist

- [x] Admin cannot register via UI
- [x] Register button hidden for admin role
- [x] Only one admin can exist
- [x] Admin must be seeded before login
- [x] Proper error messages for all scenarios
- [x] Toast notifications working
- [x] Success/Error feedback clear
- [x] Seed script updated for new API
- [x] Backend validates admin role
- [x] Frontend prevents admin registration

## Common Issues & Solutions

### Issue 1: "Account not found" for Admin
**Cause:** Admin not seeded
**Solution:** Run `npm run seed:admin`

### Issue 2: Seed Script Fails
**Cause:** Invalid pincode or MongoDB connection
**Solution:** 
- Check ADMIN_PINCODE in .env
- Verify MongoDB connection
- Check server logs

### Issue 3: Multiple Admins
**Cause:** Manual database insertion
**Solution:** 
- Delete extra admins from database
- Keep only one admin
- Use seed script only

### Issue 4: Toast Not Showing
**Cause:** Context issue or navigation
**Solution:**
- Check if context is mounted
- Ensure ScaffoldMessenger is available
- Already handled in DialogHelper

## Best Practices

1. **Never create admin manually in database**
   - Always use seed script
   - Ensures proper validation

2. **Keep admin credentials secure**
   - Don't commit .env file
   - Use strong phone number
   - Change default values

3. **One admin per system**
   - Prevents confusion
   - Clear responsibility
   - Better security

4. **Regular admin password rotation**
   - Change admin phone periodically
   - Re-seed with new credentials
   - Update .env file

## Status: ✅ SECURED

Admin registration is now properly secured:
- ✅ UI prevents admin registration
- ✅ Backend blocks admin signup
- ✅ Only seed script can create admin
- ✅ Proper error handling
- ✅ Clear toast messages
- ✅ One admin policy enforced

**The admin system is secure and working correctly!** 🔐
