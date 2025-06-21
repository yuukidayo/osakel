# OSAKEL - Drink Shop Map App

A Flutter application that connects to Firebase Firestore and displays store locations on a Google Map with custom price markers. Users can find shops that serve specific drinks, view pricing information, and get details about each location.

## Features

- Firebase Firestore integration for real-time data
- Google Maps integration with custom markers
- Price markers showing drink prices at each location
- Horizontal scrollable shop list with detailed cards
- Bottom sheet with shop details and action buttons
- Filtering shops by drink availability
- Drink categories and details screens
- Modern UI with custom animations

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
- Horizontal shop cards with 16:9 image aspect ratio
- Displays shop atmosphere tags and operating hours
- Shows "ノミタイ" (want to drink) counts for popularity metrics

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

## 📚 ドキュメント

### 開発者向けドキュメント
- [画面とファイルのマッピング](docs/screen_file_mapping_ja.md) - 各画面に対応するDartファイルの詳細マッピング
- [アーキテクチャガイド](docs/ARCHITECTURE.md) - 数値型処理とnull安全性のベストプラクティス
- [Firebaseスキーマ](docs/FIREBASE_SCHEMA.md) - Firestoreデータベース構造の詳細

### 主要な画面構成
- **認証**: ログイン、サインアップ、パスワードリセット
- **メイン**: カテゴリ一覧、サブカテゴリ、ドリンク詳細
- **マップ**: Google Maps統合、店舗位置表示、価格マーカー
- **店舗**: 店舗一覧、店舗詳細、ストア詳細
- **管理者**: ドリンク登録（管理者専用）

詳細な画面とファイルの対応関係については、[画面ファイルマッピング](docs/screen_file_mapping_ja.md)を参照してください。

## 🔧 開発環境

### 必要な設定
- Google Maps API キー
- Firebase プロジェクト設定
- Flutter SDK (最新安定版)
- Xcode 15.3+ (iOS開発の場合)

### ビルドコマンド
```bash
# 依存関係のインストール
flutter pub get

# iOS向けビルド
flutter build ios --no-codesign

# Android向けビルド
flutter build apk

# 開発用実行
flutter run --debug
```

## 🚨 既知の問題と対策

### null安全性
- `lib/utils/safe_data_utils.dart`を使用してFirestoreからの安全なデータ取得を実装
- 文字列フィールドには`SafeDataUtils.safeGetString()`を使用

### カルーセル
- `carousel_slider`パッケージ使用時は`import 'package:carousel_slider/carousel_slider.dart' as carousel;`でエイリアスを設定

### Firebase認証
- Firebase iOS SDK 11.13.0以上はXcode 15.3+が必要
- minSdkVersion 23以上が必要（Android）
