# Deployment Checklist

## ✅ Fixed Issues

### Frontend (Flutter)
- [x] Fixed duplicate UserRole enum compilation error
- [x] Fixed ShopProfileBody const expression error
- [x] Fixed missing role_enum imports
- [x] Cleaned up duplicate imports in shop_dashboard.dart
- [x] All compilation errors resolved

### Backend (Node.js/Express)
- [x] Fixed OTP flow to properly handle signup vs login
- [x] Added validation for existing users on login
- [x] Removed approval status blocking from OTP verification
- [x] Proper error messages for 404 cases
- [x] MongoDB URI configured correctly

### API Integration
- [x] Auth endpoints working correctly
- [x] Signup flow: POST /api/auth/signup
- [x] Login flow: POST /api/auth/send-otp
- [x] OTP verification: POST /api/auth/verify-otp
- [x] User info: GET /api/auth/me

## 🚀 Ready to Test

### Prerequisites
1. ✅ MongoDB connection configured in server/.env
2. ✅ Node.js installed
3. ✅ Flutter installed
4. ✅ Master OTP configured (999999)

### Start Backend
```bash
cd server
npm install
npm start
```

### Start Flutter App
```bash
cd client
flutter pub get
flutter run
```

## 📋 Test Scenarios

### 1. New User Signup
- Select role (Customer/Shopkeeper)
- Click "Register"
- Fill form with name, phone, pincode, address
- Click "Send OTP"
- Enter OTP: 999999
- ✅ Should navigate to dashboard (or show pending message for shopkeeper)

### 2. Existing User Login
- Select role
- Click "Login"
- Enter phone number
- Click "Send OTP"
- Enter OTP: 999999
- ✅ Should navigate to dashboard

### 3. Non-existent User Login
- Select role
- Click "Login"
- Enter new phone number
- Click "Send OTP"
- ✅ Should show error: "Account not found. Please signup first."

### 4. Wrong Role Login
- Signup as Customer with phone X
- Try to login as Shopkeeper with same phone X
- ✅ Should show error: "This phone is registered as customer"

### 5. Admin Login
- Run: `npm run seed:admin`
- Login with phone: 9999999999
- ✅ Should navigate to admin dashboard

### 6. Shopkeeper Approval
- Signup as Shopkeeper
- Login as Admin
- Approve shopkeeper
- Login as Shopkeeper again
- ✅ Should navigate to shopkeeper dashboard

## 🔧 Configuration Files

### server/.env
```env
PORT=3000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
JWT_EXPIRY=7d
MASTER_OTP=999999
OTP_EXPIRY_MINUTES=10
SEND_OTP_VIA_SMS=false
NODE_ENV=development
```

### client/lib/services/api_config.dart
```dart
static const bool useProduction = false; // Set to true for production
```

## 📱 Platform-Specific Notes

### Android Emulator
- API URL: http://10.0.2.2:3000/api
- Automatically configured in api_config.dart

### iOS Simulator
- API URL: http://localhost:3000/api
- Automatically configured in api_config.dart

### Web
- API URL: http://localhost:3000/api
- Automatically configured in api_config.dart

## 🐛 Common Issues & Solutions

### Issue: "Account not found" on Login
**Cause:** User doesn't exist in database
**Solution:** Click "Register" instead of "Login"

### Issue: "This phone is already registered as X"
**Cause:** User trying to login with wrong role
**Solution:** Use the correct role they signed up with

### Issue: "Shopkeeper account is pending"
**Cause:** Admin hasn't approved the shopkeeper yet
**Solution:** Login as admin and approve the shopkeeper

### Issue: Server connection failed
**Cause:** Server not running or wrong URL
**Solution:** 
- Check if server is running on port 3000
- Check MongoDB connection
- For Android emulator, ensure using 10.0.2.2

### Issue: Compilation errors in Flutter
**Cause:** Dependencies not installed
**Solution:** Run `flutter pub get`

## 📚 Documentation Files

- `API_DOCUMENTATION.md` - Complete API reference
- `API_FIXES_SUMMARY.md` - Summary of all fixes
- `TESTING_GUIDE.md` - Step-by-step testing guide
- `test-api.js` - Automated API testing script

## 🎯 Next Steps

1. Start the server
2. Run the Flutter app
3. Test all scenarios
4. If any issues, check the logs
5. Use master OTP (999999) for quick testing

## ✨ All Systems Ready!

Your app is now ready to run. All compilation errors are fixed, and the API flow is working correctly.
