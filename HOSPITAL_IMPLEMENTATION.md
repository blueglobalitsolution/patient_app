# Hospital Screen Implementation - OpenStreetMap + flutter_map

## Completed Implementation

### ✅ Files Created/Modified:

1. **pubspec.yaml** - Added dependencies:
   - `geolocator: ^12.0.0`
   - `flutter_map: ^6.1.0`
   - `latlong2: ^0.9.0`

2. **android/app/src/main/AndroidManifest.xml** - Added location permissions:
   - `ACCESS_FINE_LOCATION`
   - `ACCESS_COARSE_LOCATION`

3. **lib/services/location_service.dart** - Location service for:
   - Getting user's current GPS location
   - Calculating distances between points

4. **lib/services/hospital_service.dart** - Hospital API service:
   - Calls backend to get nearby hospitals

5. **lib/models/hospital_models.dart** - Hospital data model

6. **lib/screens/dashboard/hospital_screen.dart** - Updated hospital screen with:
   - Interactive OpenStreetMap
   - Current location marker
   - Hospital markers
   - Search functionality
   - Hospital list with distances

---

## Backend API Required

You need to create this endpoint in your backend:

### Endpoint: `GET /hospitals/nearby/`

**Query Parameters:**
- `lat` (required): User's latitude
- `lng` (required): User's longitude
- `radius` (optional): Search radius in km (default: 5.0)

**Response Format:**
```json
[
  {
    "id": 1,
    "name": "City Care Hospital",
    "address": "123 Main Street, City",
    "specialty": "Multi-speciality",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "distance": 2500.0,
    "phone": "+1234567890"
  },
  {
    "id": 2,
    "name": "Dr. Sam Liu",
    "address": "456 Oak Avenue",
    "specialty": "Dermatologist",
    "latitude": 40.7129,
    "longitude": -74.0061,
    "distance": 1800.0,
    "phone": "+0987654321"
  }
]
```

### Backend Implementation Notes:
- Calculate distance using Haversine formula or GeoDjango
- Return hospitals sorted by distance (nearest first)
- Distance should be in meters
- Include hospitals within the specified radius

---

## iOS Configuration (When Needed)

When you add iOS support, add to **ios/Runner/Info.plist**:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby hospitals</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby hospitals</string>
```

---

## Features Implemented:

1. ✅ Get user's current location
2. ✅ Display OpenStreetMap with user location
3. ✅ Fetch nearby hospitals from backend
4. ✅ Display hospital markers on map
5. ✅ Search hospitals by name, address, or specialty
6. ✅ Display hospitals in list with distance
7. ✅ Tap hospital to focus on map
8. ✅ Error handling and loading states
9. ✅ Location permission handling

---

## Cost: $0 (All Free!)

- OpenStreetMap tiles: Free
- Geolocator: Free
- flutter_map: Free
- No API keys needed!

---

## Testing Instructions:

1. Run `flutter pub get` (already done)
2. Ensure location permissions are enabled on Android device
3. Implement backend API endpoint `/hospitals/nearby/`
4. Test the app on a real device (simulators may have limited location support)

---

## Next Steps:

1. Implement the backend API endpoint
2. Test on real Android device
3. Add iOS configuration when needed
4. Optionally: Add hospital details screen
5. Optionally: Add directions/navigation feature
