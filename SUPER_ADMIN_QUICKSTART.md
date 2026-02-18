# Super Admin Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Step 1: Create Super Admin User

Run the creation script:

```bash
cd server
node scripts/create-super-admin.js 9876543210 "Super Admin"
```

Replace `9876543210` with your phone number.

**Output:**
```
✅ Super Admin created successfully!
User Details:
  - ID: 507f1f77bcf86cd799439011
  - Name: Super Admin
  - Phone: 9876543210
  - Role: super_admin
  - Active: true
```

### Step 2: Install Frontend Dependencies

```bash
cd client
flutter pub get
```

### Step 3: Start the Server

```bash
cd server
npm run dev
```

### Step 4: Login as Super Admin

#### Option A: Using Mobile App

1. Open the app
2. Select "Super Admin" role
3. Enter phone: `9876543210`
4. Request OTP
5. Enter OTP: `999999` (master OTP for development)
6. You'll be redirected to Super Admin Dashboard

#### Option B: Using API (for testing)

```bash
# Send OTP
curl -X POST http://localhost:3000/api/auth/sendOtp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","role":"super_admin"}'

# Verify OTP
curl -X POST http://localhost:3000/api/auth/verifyOtp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","otp":"999999","role":"super_admin"}'

# Copy the token from response
```

### Step 5: Test Super Admin Access

```bash
cd server
node scripts/test-super-admin.js <your-token-here>
```

**Expected Output:**
```
🧪 Testing Super Admin Endpoints

✅ Dashboard Analytics - PASSED
✅ Get All Users - PASSED
✅ Get All Shops - PASSED
✅ Get Audit Logs - PASSED
✅ Filter Users by Role - PASSED
✅ Search Users - PASSED

📊 Test Results: 6 passed, 0 failed
```

## 📱 Using the Dashboard

### Main Dashboard
- View total users, shops, MRR, and recent activity
- See users breakdown by role
- View subscription statistics
- Quick access to management screens

### Users Management
- View all users with filters
- Activate/deactivate users
- Approve/reject pending shopkeepers
- Search by name or phone
- Filter by role, status, pincode

### Shops Management
- View all shops with subscription data
- Filter by subscription status
- Search by shop name
- View shop details and owner info

### Audit Logs
- View all admin actions
- Filter by action type
- See who did what and when
- Track system changes

## 🔐 Security Notes

1. **Backend Validation**: All routes validate role on server
2. **Audit Logging**: All actions are logged automatically
3. **Token Required**: All requests require valid JWT token
4. **Role Check**: Only users with role 'super_admin' can access

## 🐛 Troubleshooting

### "Access Denied" Error
- Verify user has role 'super_admin' in database
- Check token is valid and not expired
- Ensure you're using the correct token

### "Token Expired" Error
- Login again to get a new token
- Tokens expire after 7 days by default

### "User Not Found" Error
- Run the create-super-admin script again
- Check MongoDB connection

### Dashboard Shows No Data
- Create some test users and shops
- Check server logs for errors
- Verify database connection

## 📊 Sample Data

To test with sample data, you can create test users:

```javascript
// In MongoDB shell or Compass
db.users.insertMany([
  {
    name: "Test Shopkeeper",
    phone: "9999999991",
    role: "shopkeeper",
    isActive: true,
    approvalStatus: "pending",
    pincode: "110001",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Test Customer",
    phone: "9999999992",
    role: "customer",
    isActive: true,
    approvalStatus: "approved",
    pincode: "110001",
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);
```

## 🎯 Common Tasks

### Activate a User
1. Go to Users Management
2. Find the user
3. Toggle the switch to activate

### Approve a Shopkeeper
1. Go to Users Management
2. Filter by role: "Shopkeeper"
3. Filter by status: "Pending"
4. Click "Approve" button

### View System Activity
1. Go to Audit Logs
2. See all recent actions
3. Filter by action type if needed

### Check Revenue
1. Go to Dashboard
2. View MRR (Monthly Recurring Revenue)
3. See subscription breakdown

## 📚 API Reference

### Get Dashboard Analytics
```bash
GET /api/super-admin/analytics
Authorization: Bearer <token>
```

### Get All Users
```bash
GET /api/super-admin/users?role=shopkeeper&page=1&limit=20
Authorization: Bearer <token>
```

### Toggle User Status
```bash
PATCH /api/super-admin/users/:userId/status
Authorization: Bearer <token>
Content-Type: application/json

{"isActive": true}
```

### Approve User
```bash
PATCH /api/super-admin/users/:userId/approval
Authorization: Bearer <token>
Content-Type: application/json

{"approvalStatus": "approved"}
```

## 🔄 Next Steps

1. ✅ Create super admin user
2. ✅ Login and access dashboard
3. ✅ Test all features
4. 📝 Create more admin users if needed
5. 🎨 Customize dashboard as needed
6. 📊 Set up monitoring and alerts
7. 🚀 Deploy to production

## 💡 Tips

- Use filters to quickly find users
- Check audit logs regularly
- Monitor MRR trends
- Approve shopkeepers promptly
- Keep track of inactive users
- Review subscription statuses

## 🆘 Support

If you encounter issues:
1. Check server logs: `npm run dev`
2. Check database connection
3. Verify user role in database
4. Test with the test script
5. Review audit logs for errors

---

**Ready to go!** 🎉

Your Super Admin system is now set up and ready to use.
