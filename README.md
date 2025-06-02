# Drink Shop Map App

A Flutter application that connects to Firebase Firestore and displays store locations on a Google Map with custom price markers. When a marker is tapped, a bottom sheet appears showing the shop name and drink price.

## Features

- Firebase Firestore integration
- Google Maps integration
- Custom price markers showing drink prices at each location
- Bottom sheet with shop and price details
- Filtering shops by drink availability

## Firestore Structure

The app uses the following Firestore collections:

1. **shops**
   - Each document includes:
     - `name`: Shop name
     - `location`: Map with `lat` and `lng` coordinates
     - `address`: Shop address
     - `imageUrl`: Optional URL to shop image

2. **drink_shop_links**
   - Each document includes:
     - `drinkId`: Reference to a specific drink (e.g., "drink_asahi_superdry")
     - `shopId`: Reference to a shop document ID
     - `price`: Price of the drink at this shop
     - `isAvailable`: Boolean indicating if the drink is available
     - `note`: Optional note about the drink at this shop

## Setup

### Prerequisites

- Flutter SDK (latest version)
- Android Studio or Xcode
- Google Maps API Key
- Firebase Project

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your project
3. Download the configuration files:
   - For Android: `google-services.json` (place in `android/app/`)
   - For iOS: `GoogleService-Info.plist` (place in `ios/Runner/`)
4. Create the Firestore collections as described above
5. Update the Firebase project ID in `lib/main.dart`

### Google Maps API Key Setup

1. Get a Google Maps API key from the [Google Cloud Console](https://console.cloud.google.com/)
2. For Android: Add your API key in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
     android:name="com.google.android.geo.API_KEY"
     android:value="YOUR_API_KEY"/>
   ```
3. For iOS: Add your API key in `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

### Running the App

```bash
flutter pub get
flutter run
```

## Implementation Details

- Uses `firebase_core` and `cloud_firestore` for Firebase integration
- Uses `google_maps_flutter` for map functionality
- Implements custom price markers using Canvas and PictureRecorder
- Uses `intl` package for price formatting
- Implements a bottom sheet for shop and price details

## Sample Data

To test the app, add the following sample data to your Firestore database:

```
// Collection: shops
Document ID: shop1
{
  name: "Tokyo Beer Hall",
  location: { lat: 35.681236, lng: 139.767125 },
  address: "1-1 Marunouchi, Chiyoda-ku, Tokyo"
}

Document ID: shop2
{
  name: "Shibuya Drinks",
  location: { lat: 35.658034, lng: 139.701636 },
  address: "2-1 Dogenzaka, Shibuya-ku, Tokyo"
}

// Collection: drink_shop_links
Document ID: link1
{
  drinkId: "drink_asahi_superdry",
  shopId: "shop1",
  price: 500,
  isAvailable: true
}

Document ID: link2
{
  drinkId: "drink_asahi_superdry",
  shopId: "shop2",
  price: 550,
  isAvailable: true
}
```
