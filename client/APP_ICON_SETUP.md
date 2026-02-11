# App Icon & Name Setup Guide

## ✅ Completed Setup

Your app has been configured with:
- **App Name**: D'Offer
- **App Icon**: assets/Dofferlogo.png

## What Was Done

### 1. App Icons Generated
The `flutter_launcher_icons` package has generated icons for all platforms:
- ✅ Android (all densities)
- ✅ iOS (all sizes)
- ✅ Web (192x192, 512x512, maskable)
- ✅ Windows
- ✅ macOS
- ✅ Linux

### 2. App Name Updated
The app name "D'Offer" has been set across all platforms:

#### Android
- File: `android/app/src/main/AndroidManifest.xml`
- Changed: `android:label="D'Offer"`

#### iOS
- File: `ios/Runner/Info.plist`
- Changed: `CFBundleDisplayName` and `CFBundleName` to "D'Offer"

#### Web
- File: `web/index.html`
- Changed: `<title>D'Offer</title>`
- File: `web/manifest.json`
- Changed: `name` and `short_name` to "D'Offer"
- Updated theme colors to match app design

#### Windows
- File: `windows/runner/Runner.rc`
- Changed: Product name and descriptions to "D'Offer"

#### macOS
- File: `macos/Runner/Configs/AppInfo.xcconfig`
- Changed: `PRODUCT_NAME = D'Offer`

#### Linux
- File: `linux/CMakeLists.txt`
- Changed: Binary name and application ID

### 3. App Constants Updated
- File: `lib/core/constants/app_strings.dart`
- Changed: `appName = "D'Offer"`

## How to Test

### Android
```bash
cd client
flutter run
```
Check the app name in:
- App drawer
- Recent apps
- Settings > Apps

### iOS
```bash
cd client
flutter run -d ios
```
Check the app name in:
- Home screen
- App switcher
- Settings

### Web
```bash
cd client
flutter run -d chrome
```
Check:
- Browser tab title
- PWA install name

## Regenerating Icons

If you need to change the icon in the future:

1. Replace `assets/Dofferlogo.png` with your new logo
2. Run:
```bash
cd client
flutter pub run flutter_launcher_icons
```

## Icon Configuration

The icon configuration in `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/Dofferlogo.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/Dofferlogo.png"
  windows:
    generate: true
    image_path: "assets/Dofferlogo.png"
  macos:
    generate: true
    image_path: "assets/Dofferlogo.png"
  linux:
    generate: true
    image_path: "assets/Dofferlogo.png"
```

## Notes

- The icon has been generated for all platforms
- App name is now "D'Offer" everywhere
- Theme colors updated to match your app design (Orange #FFA726)
- No need to manually edit icon files

## Troubleshooting

### Icon not showing on Android
1. Uninstall the app completely
2. Run `flutter clean`
3. Run `flutter pub get`
4. Rebuild and install

### Icon not showing on iOS
1. Delete the app from device
2. Run `flutter clean`
3. Run `pod install` in ios folder
4. Rebuild and install

### Web icon not showing
1. Clear browser cache
2. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
3. Rebuild web app

## Build Commands

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

The app icon and name will be correctly displayed in all builds!
