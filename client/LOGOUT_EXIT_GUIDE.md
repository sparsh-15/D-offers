# Logout & Exit Confirmation Guide

## ✅ Features Implemented

Your app now has proper logout and exit confirmation dialogs:

### 1. Logout Confirmation
- Shows confirmation dialog before logging out
- Asks: "Are you sure you want to logout?"
- Options: "Logout" (red) or "Cancel"
- On logout: Returns to role selection screen
- Shows success message after logout

### 2. App Exit Confirmation
- Shows confirmation when pressing back button on dashboard
- Asks: "Are you sure you want to exit the app?"
- Options: "Exit" (red) or "Cancel"
- Prevents accidental app exits

### 3. Success/Error Messages
- Success snackbar on logout
- Error snackbars for failures
- Info snackbars for notifications

## 📱 Where to Find

### Logout Button
Available in all profile screens:
- **Customer Dashboard** → Profile tab → Logout (bottom of list)
- **Shopkeeper Dashboard** → Shop Profile tab → Logout (bottom of list)
- **Admin Dashboard** → Admin Profile tab → Logout (bottom of list)

### Exit Confirmation
- Press back button on any dashboard
- Confirmation dialog appears automatically
- Works on all three dashboards (Customer, Shopkeeper, Admin)

## 🎯 How It Works

### Logout Flow
1. User taps "Logout" button
2. Confirmation dialog appears
3. If user confirms:
   - Navigates to role selection screen
   - Clears navigation stack
   - Shows "Logged out successfully" message
4. If user cancels:
   - Dialog closes
   - User stays on current screen

### Exit Flow
1. User presses back button on dashboard
2. Confirmation dialog appears
3. If user confirms:
   - App exits
4. If user cancels:
   - Dialog closes
   - User stays in app

## 🎨 Dialog Design

### Confirmation Dialog
- **Title**: Bold, prominent
- **Message**: Clear description
- **Cancel Button**: Text button (gray)
- **Confirm Button**: Elevated button (red for destructive actions)
- **Rounded corners**: 16px radius
- **Theme-aware**: Adapts to light/dark theme

### Success Snackbar
- **Green background**
- **Check icon**
- **Floating style**
- **2 seconds duration**
- **Rounded corners**

### Error Snackbar
- **Red background**
- **Error icon**
- **Floating style**
- **3 seconds duration**
- **Rounded corners**

## 🔧 Technical Implementation

### Files Created
- `lib/core/utils/dialog_helper.dart` - Dialog utilities

### Files Modified
- `lib/screens/customer/customer_dashboard.dart`
- `lib/screens/shopkeeper/shop_dashboard.dart`
- `lib/screens/admin/admin_dashboard.dart`

### Key Components

#### DialogHelper Class
```dart
// Show logout confirmation
DialogHelper.showLogoutDialog(context)

// Show exit confirmation
DialogHelper.showExitDialog(context)

// Show success message
DialogHelper.showSuccessSnackBar(context, 'Message')

// Show error message
DialogHelper.showErrorSnackBar(context, 'Error')

// Show info message
DialogHelper.showInfoSnackBar(context, 'Info')
```

#### WillPopScope
Used to intercept back button press:
```dart
WillPopScope(
  onWillPop: () async {
    final shouldExit = await DialogHelper.showExitDialog(context);
    return shouldExit;
  },
  child: Scaffold(...),
)
```

## 💡 Usage Examples

### Custom Confirmation Dialog
```dart
final confirmed = await DialogHelper.showConfirmDialog(
  context: context,
  title: 'Delete Item',
  message: 'Are you sure you want to delete this item?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  isDestructive: true,
);

if (confirmed) {
  // Perform delete action
}
```

### Show Success Message
```dart
DialogHelper.showSuccessSnackBar(
  context,
  'Item saved successfully',
);
```

### Show Error Message
```dart
DialogHelper.showErrorSnackBar(
  context,
  'Failed to save item',
);
```

## 🎯 Features

✅ Logout confirmation dialog
✅ App exit confirmation dialog
✅ Success/error/info snackbars
✅ Theme-aware dialogs
✅ Proper navigation handling
✅ Clear navigation stack on logout
✅ Prevents accidental exits
✅ Professional UI/UX
✅ Works on all dashboards
✅ Smooth animations

## 🔒 Security

- Logout clears navigation stack
- Returns to role selection (not auto-login)
- User must re-authenticate after logout
- No session persistence after logout

## 📋 Dialog Types

### 1. Logout Dialog
- **Title**: "Logout"
- **Message**: "Are you sure you want to logout?"
- **Confirm**: "Logout" (red button)
- **Cancel**: "Cancel" (text button)

### 2. Exit Dialog
- **Title**: "Exit App"
- **Message**: "Are you sure you want to exit the app?"
- **Confirm**: "Exit" (red button)
- **Cancel**: "Cancel" (text button)

### 3. Custom Dialog
- Customizable title, message, buttons
- Optional destructive styling
- Returns boolean (true/false)

## 🎨 Customization

### Change Dialog Colors
Edit `lib/core/utils/dialog_helper.dart`:
```dart
backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
```

### Change Dialog Text
Edit the dialog calls in dashboard files:
```dart
DialogHelper.showLogoutDialog(context) // Change message here
```

### Change Snackbar Duration
Edit `lib/core/utils/dialog_helper.dart`:
```dart
duration: const Duration(seconds: 2), // Change duration
```

## 🚀 Testing

### Test Logout
1. Navigate to any profile screen
2. Tap "Logout" button
3. Confirmation dialog appears
4. Tap "Logout" to confirm
5. Should return to role selection
6. Success message appears

### Test Exit
1. Open any dashboard
2. Press back button (or swipe back)
3. Confirmation dialog appears
4. Tap "Exit" to confirm
5. App should exit
6. Or tap "Cancel" to stay

### Test Cancel
1. Trigger logout or exit
2. Tap "Cancel" in dialog
3. Dialog closes
4. User stays on current screen

## 🎉 Result

Your app now has professional logout and exit confirmations that prevent accidental actions and provide clear feedback to users!
