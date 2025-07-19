import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 位置データサービス
class LocationDataService {
  /// 位置候補リスト
  static const List<String> locationSuggestions = [
    '東京都渋谷区',
    '東京都新宿区',
    '東京都江東区',
    '東京都品川区',
    '東京都目黒区',
    '東京都中央区',
    '東京都豊島区',
    '東京都台東区',
    '東京都文京区',
    '東京都千代田区',
  ];

  /// 位置名と座標のマッピング
  static const Map<String, LatLng> locationMap = {
    '東京都渋谷区': LatLng(35.658517, 139.701334),
    '東京都新宿区': LatLng(35.693908, 139.703645),
    '東京都江東区': LatLng(35.669068, 139.778213),
    '東京都品川区': LatLng(35.607286, 139.730133),
    '東京都目黒区': LatLng(35.642908, 139.699525),
    '東京都中央区': LatLng(35.672048, 139.772359),
    '東京都豊島区': LatLng(35.723436, 139.715446),
    '東京都台東区': LatLng(35.712833, 139.780515),
    '東京都文京区': LatLng(35.720495, 139.751935),
    '東京都千代田区': LatLng(35.694003, 139.754202),
  };

  /// 位置名から座標を取得
  static LatLng? getLocationCoordinates(String location) {
    return locationMap[location];
  }
}
