# Current Location Feature Implementation

## Overview
Implemented a complete current location feature for the customer app that detects the user's actual GPS location and fetches offers based on their current pincode/area.

---

## Features Implemented

### 1. Location Service (`location_service.dart`)

#### Core Functionality
- ✅ Get current GPS position (latitude, longitude)
- ✅ Convert coordinates to address (reverse geocoding)
- ✅ Extract pincode, city, state from address
- ✅ Permission handling (request, check, open settings)
- ✅ Location service status checking
- ✅ Distance calculation between coordinates
- ✅ Error handling with user-friendly messages

#### Methods

```dart
// Get current position
Future<Position?> getCurrentPosition()

// Get address from coordinates
Future<Map<String, String>> getAddressFromCoordinates(lat, lng)

// Get location with full address
Future<Map<String, dynamic>> getCurrentLocationWithAddress()

// Calculate distance in kilometers
double calculateDistance(lat1, lng1, lat2, lng2)

// Open settings
Future<bool> openLocationSettings()
Future<bool> openAppSettings()
```

---

### 2. Customer Home Tab Updates

#### New Features
- **Current Location Button**: Prominent chip to enable/disable location
- **Location Detection**: Automatic GPS detection with loading state
- **Location Display**: Shows detected city and pincode
- **Dynamic Offers**: Fetches offers based on current location

#### UI Improvements
```dart
FilterChip(
  selected: _useCurrentLocation,
  onSelected: _toggleCurrentLocation,
  avatar: _isLoadingLocation
    ? CircularProgressIndicator()
    : Icon(_useCurrentLocation ? Iconsax.gps : Iconsax.location),
  label: Text(
    _isLoadingLocation
      ? 'Detecting...'
      : (_useCurrentLocation && _currentLocationText != null
          ? 'Current: $_currentLocationText'
          : 'Use Current Location'),
  ),
)
```

#### State Management
```dart
bool _useCurrentLocation = false;
bool _isLoadingLocation = false;
String? _currentLocationText;
String? _currentPincode;
String? _currentCity;
String? _currentState;
```

---

### 3. Customer Offers Tab Updates

#### New Features
- **Prominent Location Button**: Full-width button at top
- **Visual Feedback**: Shows current location when active
- **Auto-fill Filters**: Automatically fills city/pincode filters
- **Seamless Integration**: Works with existing filter system

#### UI Component
```dart
OutlinedButton.icon(
  onPressed: _isLoadingLocation ? null : _toggleCurrentLocation,
  icon: _isLoadingLocation
    ? CircularProgressIndicator()
    : Icon(_useCurrentLocation ? Iconsax.gps : Iconsax.location),
  label: Text(
    _isLoadingLocation
      ? 'Detecting Location...'
      : (_useCurrentLocation && _currentLocationText != null
          ? 'Current: $_currentLocationText'
          : 'Use Current Location'),
  ),
  style: OutlinedButton.styleFrom(
    backgroundColor: _useCurrentLocation
      ? AppColors.primary.withValues(alpha: 0.1)
      : null,
    side: BorderSide(
      color: _useCurrentLocation ? AppColors.primary : AppColors.grey400,
      width: _useCurrentLocation ? 2 : 1,
    ),
  ),
)
```

---

## User Flow

### Home Tab Flow
```
1. User opens Home tab
2. Sees "Use Current Location" chip
3. Taps chip
4. Permission dialog appears (if first time)
5. User grants permission
6. Shows "Detecting..." with loading spinner
7. Location detected: "Current: Mumbai, 400001"
8. Offers refresh automatically
9. Shows offers from current location
```

### Offers Tab Flow
```
1. User opens Offers tab
2. Sees prominent "Use Current Location" button
3. Taps button
4. Location detection starts
5. Button shows "Detecting Location..."
6. Location detected
7. City and Pincode filters auto-filled
8. Offers filtered by current location
9. Can toggle off to use profile location
```

---

## Permissions Configuration

### Android (`AndroidManifest.xml`)
```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`Info.plist`)
```xml
<!-- Location permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show offers near you</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to show offers near you</string>
```

---

## Error Handling

### Permission Denied
```dart
if (e.toString().contains('denied')) {
  errorMessage = 'Location permission denied. Please enable location access in settings.';
}
```

### Location Services Disabled
```dart
if (e.toString().contains('disabled')) {
  errorMessage = 'Location services are disabled. Please enable them.';
}
```

### Generic Errors
```dart
catch (e) {
  errorMessage = 'Failed to get current location';
  // Show user-friendly error message
}
```

---

## Location Detection Process

### Step-by-Step
1. **Check Location Services**
   ```dart
   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
   ```

2. **Check Permission**
   ```dart
   LocationPermission permission = await Geolocator.checkPermission();
   ```

3. **Request Permission (if needed)**
   ```dart
   if (permission == LocationPermission.denied) {
     permission = await Geolocator.requestPermission();
   }
   ```

4. **Get Current Position**
   ```dart
   Position position = await Geolocator.getCurrentPosition(
     desiredAccuracy: LocationAccuracy.high,
     timeLimit: const Duration(seconds: 10),
   );
   ```

5. **Reverse Geocoding**
   ```dart
   List<Placemark> placemarks = await placemarkFromCoordinates(
     position.latitude,
     position.longitude,
   );
   ```

6. **Extract Address Components**
   ```dart
   Placemark place = placemarks[0];
   String pincode = place.postalCode ?? '';
   String city = place.locality ?? '';
   String state = place.administrativeArea ?? '';
   ```

---

## UX Improvements

### 1. Visual Feedback
- **Loading State**: Shows spinner while detecting
- **Success State**: Shows detected location
- **Active State**: Highlighted button/chip when active
- **Icons**: GPS icon when active, location pin when inactive

### 2. User Communication
- **Success Message**: "Location detected: Mumbai, 400001"
- **Error Messages**: Clear, actionable error messages
- **Permission Prompts**: Explains why location is needed

### 3. Smooth Transitions
- **Animated Icons**: Smooth icon transitions
- **Loading Indicators**: Non-blocking loading states
- **Auto-refresh**: Offers update automatically

### 4. Accessibility
- **Clear Labels**: Descriptive button text
- **Status Indicators**: Visual feedback for all states
- **Error Recovery**: Easy to retry or disable

---

## Backend Integration

### API Endpoint
```
GET /customer/offers?pincode=400001&city=Mumbai&state=Maharashtra
```

### Request Flow
```dart
Future<List<OfferModel>> _fetchOffers() {
  if (_useCurrentLocation && _currentPincode != null) {
    return AuthService.instance.getCustomerOffers(
      pincode: _currentPincode,
      city: _currentCity,
      state: _currentState,
    );
  }
  // Fallback to profile location
}
```

---

## Testing Checklist

### Functional Testing
- [x] Location permission request works
- [x] Location detection works
- [x] Address extraction works
- [x] Offers filter by location
- [x] Toggle on/off works
- [x] Loading states display correctly
- [x] Error messages show properly
- [x] Auto-refresh after detection

### Permission Scenarios
- [x] First time (no permission)
- [x] Permission granted
- [x] Permission denied
- [x] Permission permanently denied
- [x] Location services disabled

### Edge Cases
- [x] No GPS signal
- [x] Timeout (10 seconds)
- [x] Invalid coordinates
- [x] No address found
- [x] Network error during geocoding

### UI/UX Testing
- [x] Button states (normal, loading, active)
- [x] Icon transitions
- [x] Text updates
- [x] Color changes
- [x] Animations smooth
- [x] Dark mode support

---

## Icons Used (Iconsax)

| State | Icon | Purpose |
|-------|------|---------|
| Inactive | `Iconsax.location` | Location pin (not using GPS) |
| Active | `Iconsax.gps` | GPS active (using current location) |
| Loading | `CircularProgressIndicator` | Detecting location |

---

## Performance Considerations

### 1. Timeout
```dart
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
  timeLimit: const Duration(seconds: 10), // 10 second timeout
);
```

### 2. Accuracy
```dart
desiredAccuracy: LocationAccuracy.high // Best accuracy for pincode detection
```

### 3. Caching
- Location is cached in state
- No repeated API calls
- Only refreshes when toggled

### 4. Battery Optimization
- Only requests location when user taps button
- No background location tracking
- Single request, not continuous

---

## Future Enhancements

### 1. Location History
- Save recent locations
- Quick switch between locations
- Location favorites

### 2. Radius Search
```dart
// Search within X km radius
Future<List<OfferModel>> getOffersNearby({
  required double latitude,
  required double longitude,
  double radiusKm = 5.0,
})
```

### 3. Map View
- Show offers on map
- Visual distance indicators
- Navigate to store

### 4. Smart Suggestions
- Suggest nearby popular areas
- Show offer density by location
- Trending locations

### 5. Background Location (Optional)
- Auto-detect when app opens
- Update offers automatically
- Geofencing for notifications

---

## Packages Used

### geolocator (^14.0.2)
- GPS position detection
- Permission handling
- Distance calculation
- Settings navigation

### geocoding (^4.0.0)
- Reverse geocoding
- Address extraction
- Placemark details

---

## Code Structure

```
client/lib/
├── services/
│   └── location_service.dart          # Location detection & geocoding
├── screens/
│   └── customer/
│       ├── customer_home_tab.dart     # Home with location chip
│       └── customer_offers_tab.dart   # Offers with location button
└── android/app/src/main/
    └── AndroidManifest.xml            # Android permissions
└── ios/Runner/
    └── Info.plist                     # iOS permissions
```

---

## Troubleshooting

### Location Not Detecting
1. Check location services enabled
2. Check app permissions granted
3. Check GPS signal available
4. Try outdoors for better signal

### Permission Issues
1. Go to app settings
2. Enable location permission
3. Restart app
4. Try again

### Inaccurate Location
1. Ensure GPS enabled (not just WiFi)
2. Wait for better signal
3. Try outdoors
4. Check device location settings

---

## Summary

✅ **Complete location feature implemented**
- GPS detection with reverse geocoding
- Pincode/city/state extraction
- Permission handling
- Error management
- Loading states
- Visual feedback

✅ **Seamless UX**
- One-tap location detection
- Clear status indicators
- Smooth animations
- User-friendly errors
- Easy toggle on/off

✅ **Production Ready**
- Proper permissions configured
- Error handling in place
- Timeout protection
- Battery optimized
- Works on Android & iOS

The current location feature is now fully functional and provides a smooth, intuitive experience for users to find offers near their actual location!
