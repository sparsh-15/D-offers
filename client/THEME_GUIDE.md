# Light/Dark Theme Guide

## ✅ What's Been Added

Your app now has complete light and dark theme support with:
- **Automatic theme switching** with toggle button
- **Theme persistence** (remembers user preference)
- **Smooth transitions** between themes
- **Professional light theme** with proper colors
- **Theme toggle in all profile screens**

## 🎨 Theme Features

### Dark Theme
- Background: Dark Blue (#0A0E21)
- Surface: Dark Blue-Gray (#1D1E33)
- Text: White and gray shades
- Cards: Elevated with shadows

### Light Theme
- Background: Light Gray (#F5F7FA)
- Surface: White (#FFFFFF)
- Text: Dark gray and black shades
- Cards: White with subtle shadows

## 🔧 How It Works

### Theme Provider
- Manages theme state across the app
- Saves preference to local storage
- Provides toggle functionality

### Theme Toggle Widgets
1. **ThemeToggle** - Full card with switch (for settings)
2. **ThemeToggleButton** - Icon button (for app bars)

## 📱 Where to Find Theme Toggle

### Customer Dashboard
- Profile tab > Top right icon button
- Profile tab > Theme toggle card in list

### Shopkeeper Dashboard
- Shop Profile tab > Top right icon button
- Shop Profile tab > Theme toggle card in list

### Admin Dashboard
- Admin Profile tab > Top right icon button
- Admin Profile tab > Theme toggle card in list

## 🎯 Usage

### Toggle Theme Programmatically
```dart
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

// In your widget
final themeProvider = Provider.of<ThemeProvider>(context);
themeProvider.toggleTheme();
```

### Check Current Theme
```dart
final themeProvider = Provider.of<ThemeProvider>(context);
bool isDark = themeProvider.isDarkMode;
```

### Use Theme Colors in Widgets
```dart
// Get background gradient based on theme
final isDark = Theme.of(context).brightness == Brightness.dark;
final gradient = isDark 
    ? AppColors.backgroundGradient 
    : AppColors.lightBackgroundGradient;

// Or use the helper
import 'core/utils/theme_helper.dart';
final gradient = ThemeHelper.getBackgroundGradient(context);
```

## 🎨 Customizing Themes

### Change Light Theme Colors
Edit `lib/core/constants/app_colors.dart`:
```dart
// Light Theme Colors
static const Color lightBackground = Color(0xFFF5F7FA);  // Change this
static const Color lightSurface = Color(0xFFFFFFFF);     // Change this
```

### Change Dark Theme Colors
Edit `lib/core/constants/app_colors.dart`:
```dart
// Background Colors
static const Color background = Color(0xFF0A0E21);  // Change this
static const Color surface = Color(0xFF1D1E33);     // Change this
```

### Modify Theme Properties
Edit `lib/core/theme/app_theme.dart`:
- `darkTheme` getter for dark theme
- `lightTheme` getter for light theme

## 🚀 Testing

### Test Theme Switching
1. Run the app
2. Navigate to any profile screen
3. Tap the theme toggle icon (top right)
4. Or tap the theme toggle card in the list
5. Theme switches instantly

### Test Theme Persistence
1. Switch to light theme
2. Close the app completely
3. Reopen the app
4. Theme should still be light

## 📋 Files Modified/Created

### New Files
- `lib/providers/theme_provider.dart` - Theme state management
- `lib/widgets/theme_toggle.dart` - Theme toggle widgets
- `lib/core/utils/theme_helper.dart` - Theme helper functions

### Modified Files
- `lib/main.dart` - Added Provider and theme mode support
- `lib/core/theme/app_theme.dart` - Added lightTheme
- `lib/core/constants/app_colors.dart` - Added light theme colors
- `lib/screens/customer/customer_dashboard.dart` - Added theme support
- `lib/screens/shopkeeper/shop_dashboard.dart` - Added theme support
- `lib/screens/admin/admin_dashboard.dart` - Added theme support
- All auth screens - Added theme-aware gradients

## 🎯 Features

✅ Light and dark themes
✅ Theme toggle button in app bars
✅ Theme toggle card in settings
✅ Theme persistence (remembers choice)
✅ Smooth theme transitions
✅ All screens support both themes
✅ Proper colors for both themes
✅ Gradient backgrounds adapt to theme
✅ Text colors adapt to theme
✅ Card colors adapt to theme

## 💡 Tips

1. **Default Theme**: App starts in dark mode by default
2. **System Theme**: Currently uses manual toggle (can be extended to follow system)
3. **Animations**: Theme switches instantly without animation
4. **Persistence**: Uses SharedPreferences to save theme choice

## 🔄 Future Enhancements

Possible additions:
- Follow system theme option
- Animated theme transitions
- Multiple theme options (not just light/dark)
- Custom theme builder
- Theme preview before applying

## 🎉 Result

Your app now has professional light and dark themes that users can switch between with a single tap. The theme preference is saved and persists across app restarts!
