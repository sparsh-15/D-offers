# D'Offers Flutter UI Documentation

## Overview
This document describes the professional UI implementation for the D'Offers mobile application with smooth animations, modern design, and comprehensive theming.

## Design System

### Color Palette
- **Primary**: Vibrant Orange (#FFA726) - Main brand color
- **Accent**: Cyan (#26C6DA) - Secondary actions
- **Background**: Dark Blue (#0A0E21) - Main background
- **Surface**: Dark Blue-Gray (#1D1E33) - Cards and elevated surfaces
- **Text**: White (#FFFFFF) for primary, Gray shades for secondary

### Typography
- **Font Family**: Poppins (via Google Fonts)
- **Sizes**: 
  - Display Large: 32px (Bold)
  - Display Medium: 28px (Bold)
  - Title Large: 18px (Semi-bold)
  - Body: 14-16px

### Components

#### Custom Widgets
1. **GradientCard** - Reusable card with gradient backgrounds
2. **CustomButton** - Styled button with loading states
3. **CustomTextField** - Themed input field with validation

## Screen Structure

### 1. Splash Screen
- Animated logo entrance
- App name with tagline
- Auto-navigation to role selection (3 seconds)
- Smooth fade animations

### 2. Role Selection Screen
- Three role cards with gradients:
  - Customer (Orange gradient)
  - Shopkeeper (Cyan gradient)
  - Admin (Purple gradient)
- Icon-based visual hierarchy
- Smooth card animations

### 3. Authentication Flow

#### Login Screen
- Role-specific branding
- Phone number input with validation
- Custom text field with icons
- Animated transitions
- Back navigation

#### OTP Screen
- 6-digit OTP input
- Individual digit boxes with focus management
- Resend timer (30 seconds)
- Auto-focus on next field
- Verify button with loading state

### 4. Customer Dashboard
Bottom navigation with 4 tabs:

**Home Tab**
- Search bar with filter
- Featured offers carousel
- Nearby shops list
- Gradient cards for offers
- Pull-to-refresh support

**Offers Tab**
- Saved offers display
- Empty state message

**Favorites Tab**
- Favorite shops list
- Empty state message

**Profile Tab**
- User avatar
- Profile information
- Settings options
- Logout functionality

### 5. Shopkeeper Dashboard
Bottom navigation with 4 tabs:

**Dashboard Tab**
- Statistics cards (4 metrics):
  - Active Offers
  - Total Leads
  - Views Today
  - Rating
- Quick action cards
- Gradient stat cards

**Offers Management Tab**
- List of active offers
- Add offer FAB (Floating Action Button)
- Edit/Delete options
- Offer status indicators

**Leads Tab**
- Customer leads list
- Empty state message

**Shop Profile Tab**
- Shop avatar
- Shop information
- Business category

### 6. Admin Dashboard
Bottom navigation with 4 tabs:

**Dashboard Tab**
- Platform statistics (4 metrics):
  - Total Users
  - Shopkeepers
  - Active Offers
  - Pending Approvals
- Quick action cards
- Analytics overview

**Users Management Tab**
- User list with actions
- Search and filter
- User details popup

**Approvals Tab**
- Pending shopkeeper requests
- Approve/Reject buttons
- Shop details display

**Admin Profile Tab**
- Admin avatar
- Admin information
- System settings

## Animations

### Used Animations (animate_do package)
- **FadeInDown**: Headers, titles
- **FadeInUp**: Cards, buttons, lists
- **FadeInLeft**: Section titles
- Staggered delays for list items

## Theme Configuration

### Dark Theme Features
- Material 3 design
- Custom color scheme
- Elevated surfaces
- Rounded corners (12-16px)
- Consistent shadows
- Icon theming

### Input Styling
- Filled backgrounds
- No borders (focus: primary color)
- Rounded corners
- Icon support
- Error states

### Button Styling
- Elevated: Primary color, white text
- Outlined: Primary border, transparent background
- Rounded corners (12px)
- Icon support
- Loading states

## Navigation

### Navigation Pattern
- **Push**: For forward navigation (login, OTP)
- **PushReplacement**: For authentication flow
- **PushAndRemoveUntil**: For dashboard navigation (clear stack)

### Bottom Navigation
- Fixed type (always show labels)
- Icon + label combination
- Active state highlighting
- Smooth transitions

## Dependencies

```yaml
dependencies:
  google_fonts: ^6.1.0        # Typography
  animate_do: ^3.1.2          # Animations
  flutter_svg: ^2.0.9         # SVG support
  http: ^1.1.0                # API calls
  provider: ^6.1.1            # State management
  shared_preferences: ^2.2.2  # Local storage
```

## Best Practices Implemented

1. **Responsive Design**: SafeArea, proper padding
2. **Accessibility**: Semantic labels, contrast ratios
3. **Performance**: Const constructors, efficient rebuilds
4. **Code Organization**: Feature-based structure
5. **Reusability**: Custom widgets, theme system
6. **User Experience**: Loading states, error handling, smooth animations

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      # Color definitions
│   │   └── app_strings.dart     # String constants
│   ├── theme/
│   │   └── app_theme.dart       # Theme configuration
│   └── utils/
│       └── validators.dart      # Input validation
├── models/
│   ├── role_enum.dart           # User roles
│   └── user_model.dart          # User data model
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── role_selection/
│   │   └── role_selection_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── otp_screen.dart
│   ├── customer/
│   │   └── customer_dashboard.dart
│   ├── shopkeeper/
│   │   └── shop_dashboard.dart
│   └── admin/
│       └── admin_dashboard.dart
├── widgets/
│   ├── gradient_card.dart       # Reusable gradient card
│   ├── custom_button.dart       # Styled button
│   └── custom_text_field.dart   # Themed input
├── services/
│   ├── api_config.dart          # API configuration
│   └── auth_service.dart        # Authentication
└── main.dart                    # App entry point
```

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build for production
flutter build apk --release
flutter build ios --release
```

## Future Enhancements

1. Add shimmer loading effects
2. Implement pull-to-refresh
3. Add image caching
4. Implement deep linking
5. Add push notifications UI
6. Create onboarding screens
7. Add dark/light theme toggle
8. Implement search functionality
9. Add filters and sorting
10. Create detailed offer screens

## Notes

- All screens use gradient backgrounds for visual appeal
- Consistent 16px padding throughout
- Card elevation: 4px
- Border radius: 12-16px
- Icon size: 24px (default), 20px (small)
- Animation duration: 1000ms (entrance), 300ms (interactions)
