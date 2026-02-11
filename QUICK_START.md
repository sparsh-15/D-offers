# Quick Start Guide 🚀

Get your D-Offers app running in 5 minutes!

## Prerequisites
- Node.js installed
- Flutter installed
- MongoDB connection (already configured)

## Step 1: Start Backend (2 minutes)

```bash
# Navigate to server folder
cd server

# Install dependencies (first time only)
npm install

# Create admin account (first time only)
npm run seed:admin

# Start server
npm start
```

You should see:
```
MongoDB connected
Server running on port 3000
```

## Step 2: Start Flutter App (2 minutes)

```bash
# Open new terminal
cd client

# Get dependencies (first time only)
flutter pub get

# Run app
flutter run
```

## Step 3: Test the App (1 minute)

### Test Customer
1. Select "Customer"
2. Click "Register"
3. Phone: 8888888888
4. Name: Test Customer
5. Pincode: 110001
6. OTP: 999999
7. ✅ You're in!

### Test Admin
1. Select "Admin"
2. Click "Login"
3. Phone: 9999999999
4. OTP: 999999
5. ✅ You're in!

### Test Shopkeeper
1. Select "Shopkeeper"
2. Click "Register"
3. Phone: 7777777777
4. Fill details
5. OTP: 999999
6. See "Pending approval" message
7. Login as Admin
8. Go to "Approvals" tab
9. Approve the shopkeeper
10. Login as Shopkeeper again
11. ✅ You're in!

## Master OTP
Use **999999** for all OTP verifications during testing.

## API Testing (Optional)

```bash
# Test all APIs automatically
node test-all-apis.js
```

## Troubleshooting

### Server won't start
- Check if MongoDB URI is correct in server/.env
- Make sure port 3000 is not in use

### Flutter won't compile
- Run: `flutter clean && flutter pub get`
- Check if all dependencies are installed

### Can't login
- Make sure server is running
- For Android emulator, API uses 10.0.2.2:3000
- Use master OTP: 999999

### Admin not found
- Run: `npm run seed:admin` in server folder

## What's Next?

Check out these files for more details:
- `INTEGRATION_COMPLETE.md` - Full feature list
- `API_DOCUMENTATION.md` - API reference
- `TESTING_GUIDE.md` - Detailed testing scenarios

## Need Help?

1. Check server logs for errors
2. Check Flutter console for errors
3. Verify MongoDB connection
4. Make sure you're using master OTP: 999999

---

**You're all set! Happy coding! 🎉**
