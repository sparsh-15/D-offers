# Pincode Auto-Fill Feature ✨

## Overview
The app now automatically fills city and state fields when a user enters a 6-digit pincode during registration or profile editing.

## How It Works

### Backend
- **API Endpoint:** `GET /api/meta/pincode/:pincode`
- **Service:** Uses India Post API (https://api.postalpincode.in)
- **Response:**
```json
{
  "success": true,
  "pincode": "110001",
  "city": "New Delhi",
  "state": "Delhi"
}
```

### Frontend
- Listens to pincode field changes
- When 6 digits are entered, automatically calls the API
- Fills city and state fields with the response
- Shows loading indicator while fetching
- Allows manual editing if API fails

## Where It's Implemented

### 1. Customer/Shopkeeper Registration
**File:** `client/lib/screens/auth/Register_screen.dart`

**Features:**
- Auto-fills city and state when pincode is entered
- Shows "Looking up pincode..." indicator
- City and state fields are editable
- Validates that city and state are not empty

**UI Flow:**
1. User enters 6-digit pincode
2. App shows loading indicator
3. City and state fields auto-fill
4. User can edit if needed
5. Proceeds with registration

### 2. Shopkeeper Profile Edit
**File:** `client/lib/screens/shopkeeper/shop_profile_body.dart`

**Features:**
- Same auto-fill functionality in edit dialog
- Updates city when pincode changes
- Preserves existing data if API fails

## API Integration

### Frontend Service
**File:** `client/lib/services/auth_service.dart`

```dart
Future<Map<String, String>> lookupPincode(String pincode) async {
  final uri = Uri.parse('${ApiConfig.metaUrl}/pincode/$pincode');
  final resp = await _client.get(uri);
  final data = _handleResponse(resp) as Map<String, dynamic>;
  return {
    'pincode': data['pincode']?.toString() ?? pincode,
    'city': data['city']?.toString() ?? '',
    'state': data['state']?.toString() ?? '',
  };
}
```

### Backend Service
**File:** `server/src/services/pincodeService.js`

```javascript
async function resolveCityStateFromPincode(pincode) {
  const normalized = normalizePincode(pincode);
  if (!PINCODE_REGEX.test(normalized)) {
    throw new Error('Invalid pincode');
  }
  const result = await lookupIndiaPost(normalized);
  if (!result) {
    throw new Error('Unable to resolve city/state from pincode');
  }
  return { pincode: normalized, city: result.city, state: result.state };
}
```

## User Experience

### Before
```
User enters:
- Pincode: 110001
- City: [manually types "New Delhi"]
- State: [manually types "Delhi"]
```

### After
```
User enters:
- Pincode: 110001
  ↓ (auto-fills)
- City: New Delhi ✨
- State: Delhi ✨
```

## Error Handling

### If API Fails
- City and state fields remain empty/editable
- No error message shown (silent failure)
- User can manually enter city and state
- Validation ensures fields are not empty

### If Invalid Pincode
- API returns 400 error
- Fields remain empty
- User can manually enter data

### If Network Issue
- Request times out after 5 seconds
- Fields remain empty
- User can manually enter data

## Testing

### Test Valid Pincode
```bash
curl http://localhost:3000/api/meta/pincode/110001
```

**Expected Response:**
```json
{
  "success": true,
  "pincode": "110001",
  "city": "New Delhi",
  "state": "Delhi"
}
```

### Test Invalid Pincode
```bash
curl http://localhost:3000/api/meta/pincode/000000
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Unable to resolve city/state from pincode"
}
```

## Sample Pincodes for Testing

| Pincode | City | State |
|---------|------|-------|
| 110001 | New Delhi | Delhi |
| 400001 | Mumbai | Maharashtra |
| 560001 | Bangalore | Karnataka |
| 600001 | Chennai | Tamil Nadu |
| 700001 | Kolkata | West Bengal |
| 500001 | Hyderabad | Telangana |
| 380001 | Ahmedabad | Gujarat |
| 411001 | Pune | Maharashtra |
| 302001 | Jaipur | Rajasthan |
| 226001 | Lucknow | Uttar Pradesh |

## Benefits

1. **Better UX** - Users don't need to type city and state
2. **Accuracy** - Reduces typos and inconsistencies
3. **Speed** - Faster registration process
4. **Data Quality** - Ensures correct city/state mapping

## Technical Details

### Widget Updates
**File:** `client/lib/widgets/custom_text_field.dart`

Added `enabled` parameter to support disabling fields during loading:
```dart
final bool enabled;

TextFormField(
  enabled: enabled,
  // ... other properties
)
```

### State Management
- Uses `TextEditingController` for each field
- Adds listener to pincode controller
- Triggers lookup when 6 digits entered
- Updates city/state controllers with response

### Loading State
- `_isLoadingPincode` boolean flag
- Shows CircularProgressIndicator
- Disables city/state fields during loading
- Re-enables after response

## Future Enhancements

### Possible Improvements
- [ ] Cache pincode lookups locally
- [ ] Add debouncing to reduce API calls
- [ ] Show suggestions dropdown
- [ ] Support international pincodes
- [ ] Add offline fallback data
- [ ] Show district/block information
- [ ] Add pincode validation before API call

## Dependencies

### External API
- **Provider:** India Post
- **URL:** https://api.postalpincode.in
- **Rate Limit:** None specified
- **Timeout:** 5 seconds
- **Cost:** Free

### No Additional Packages Required
- Uses built-in `http` package
- No third-party dependencies

## Status: ✅ IMPLEMENTED

The pincode auto-fill feature is fully implemented and working in:
- Customer registration
- Shopkeeper registration  
- Shopkeeper profile editing

Users can now enjoy a faster and more accurate registration experience!
