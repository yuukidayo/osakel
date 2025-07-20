import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// 位置情報取得サービス
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  DateTime? _lastUpdateTime;
  
  // 位置情報の有効期限（5分）
  static const Duration LOCATION_CACHE_DURATION = Duration(minutes: 5);
  
  /// 現在地を取得（キャッシュ機能付き）
  Future<Position> getCurrentLocation({bool forceRefresh = false}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      print('📍 LocationService: 現在地取得開始');
      
      // キャッシュされた位置情報をチェック
      if (!forceRefresh && _isLocationCacheValid()) {
        print('📍 キャッシュされた位置情報を使用 (${stopwatch.elapsedMilliseconds}ms)');
        return _lastKnownPosition!;
      }
      
      // 位置情報権限をチェック
      await _checkLocationPermission();
      
      // 位置情報サービスが有効かチェック
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw LocationServiceDisabledException('位置情報サービスが無効です');
      }
      
      // 現在地を取得
      print('🌐 GPS/ネットワークから位置情報取得中...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // タイムアウト設定
      );
      
      // キャッシュに保存
      _lastKnownPosition = position;
      _lastUpdateTime = DateTime.now();
      
      print('✅ 現在地取得完了: (${position.latitude}, ${position.longitude}) (${stopwatch.elapsedMilliseconds}ms)');
      return position;
      
    } catch (e) {
      print('❌ 現在地取得エラー: $e');
      
      // フォールバック: 最後に取得した位置情報を返す
      if (_lastKnownPosition != null) {
        print('🔄 最後に取得した位置情報を使用');
        return _lastKnownPosition!;
      }
      
      // デフォルト位置（東京駅）を返す
      print('🏢 デフォルト位置（東京駅）を使用');
      return Position(
        latitude: 35.6812,
        longitude: 139.7671,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  }
  
  /// 位置情報権限をチェック・要求
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      print('📍 位置情報権限を要求中...');
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        throw PermissionDeniedException('位置情報の権限が拒否されました');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedForeverException('位置情報の権限が永続的に拒否されています。設定から許可してください。');
    }
    
    print('✅ 位置情報権限: OK');
  }
  
  /// キャッシュされた位置情報が有効かチェック
  bool _isLocationCacheValid() {
    if (_lastKnownPosition == null || _lastUpdateTime == null) {
      return false;
    }
    
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
    return timeSinceLastUpdate <= LOCATION_CACHE_DURATION;
  }
  
  /// 位置情報の精度を取得
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) return '非常に高精度';
    if (accuracy <= 10) return '高精度';
    if (accuracy <= 50) return '中精度';
    if (accuracy <= 100) return '低精度';
    return '非常に低精度';
  }
  
  /// 2点間の距離を計算
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // kmに変換
  }
  
  /// 位置情報の更新を監視（リアルタイム更新用）
  StreamSubscription<Position>? _positionStreamSubscription;
  
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // 100m移動したら更新
      ),
    );
  }
  
  /// 位置情報監視を開始
  void startLocationTracking(Function(Position) onLocationUpdate) {
    _positionStreamSubscription = getPositionStream().listen(
      (position) {
        _lastKnownPosition = position;
        _lastUpdateTime = DateTime.now();
        onLocationUpdate(position);
      },
      onError: (error) {
        print('❌ 位置情報監視エラー: $error');
      },
    );
    
    print('📍 位置情報監視開始');
  }
  
  /// 位置情報監視を停止
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    print('📍 位置情報監視停止');
  }
  
  /// サービスクリーンアップ
  void dispose() {
    stopLocationTracking();
    _lastKnownPosition = null;
    _lastUpdateTime = null;
  }
}

/// 位置情報関連の例外クラス
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);
  
  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  
  @override
  String toString() => 'PermissionDeniedException: $message';
}

class PermissionDeniedForeverException implements Exception {
  final String message;
  PermissionDeniedForeverException(this.message);
  
  @override
  String toString() => 'PermissionDeniedForeverException: $message';
}
