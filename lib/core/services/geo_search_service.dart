import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/shop.dart';
import '../../models/drink_shop_link.dart';
import '../../models/shop_with_price.dart';

/// 地理検索とキャッシュを管理するサービス
class GeoSearchService {
  static final GeoSearchService _instance = GeoSearchService._internal();
  factory GeoSearchService() => _instance;
  GeoSearchService._internal();

  // Firestore インスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 3層キャッシュシステム
  final Map<String, CachedSearchResult> _memoryCache = {};
  SharedPreferences? _prefs;
  
  // キャッシュ設定
  static const Duration MEMORY_CACHE_TTL = Duration(minutes: 15);
  static const Duration DISK_CACHE_TTL = Duration(hours: 6);
  static const int MAX_MEMORY_CACHE_SIZE = 50;
  static const double DEFAULT_SEARCH_RADIUS_KM = 3.0;

  /// サービス初期化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('🔍 GeoSearchService: 初期化完了');
  }

  /// 現在地周辺の店舗を検索（メインメソッド）
  Future<List<ShopWithPrice>> searchNearbyShops({
    required double latitude,
    required double longitude,
    required String drinkId,
    double radiusKm = DEFAULT_SEARCH_RADIUS_KM,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      print('🔍 GeoSearchService: 検索開始 - 位置: ($latitude, $longitude), 半径: ${radiusKm}km');
      
      final cacheKey = _generateCacheKey(latitude, longitude, drinkId, radiusKm);
      
      // Level 1: メモリキャッシュチェック
      final memoryResult = _checkMemoryCache(cacheKey);
      if (memoryResult != null) {
        print('💾 メモリキャッシュヒット (${stopwatch.elapsedMilliseconds}ms)');
        return memoryResult;
      }
      
      // Level 2: ディスクキャッシュチェック
      final diskResult = await _checkDiskCache(cacheKey);
      if (diskResult != null) {
        print('💽 ディスクキャッシュヒット (${stopwatch.elapsedMilliseconds}ms)');
        _saveToMemoryCache(cacheKey, diskResult);
        return diskResult;
      }
      
      // Level 3: Firestore検索
      print('🌐 Firestore検索実行');
      final result = await _searchFirestore(latitude, longitude, drinkId, radiusKm);
      
      // キャッシュに保存
      _saveToMemoryCache(cacheKey, result);
      await _saveToDiskCache(cacheKey, result);
      
      print('✅ 検索完了: ${result.length}件 (${stopwatch.elapsedMilliseconds}ms)');
      return result;
      
    } catch (e) {
      print('❌ 検索エラー: $e');
      
      // フォールバック: 古いキャッシュを返す
      final staleResult = await _getStaleCache(latitude, longitude, drinkId, radiusKm);
      if (staleResult != null) {
        print('🔄 古いキャッシュを使用: ${staleResult.length}件');
        return staleResult;
      }
      
      throw Exception('店舗検索に失敗しました: $e');
    }
  }

  /// Firestoreから店舗を検索
  Future<List<ShopWithPrice>> _searchFirestore(
    double latitude,
    double longitude,
    String drinkId,
    double radiusKm,
  ) async {
    try {
      // 1. 地理的境界を計算
      final bounds = _calculateBounds(latitude, longitude, radiusKm);
      
      // 2. DrinkShopLinkから該当するドリンクの店舗IDを取得
      final drinkShopQuery = await _firestore
          .collection('drink_shop_links')
          .where('drinkId', isEqualTo: drinkId)
          .limit(100) // コスト削減のため制限
          .get();
      
      if (drinkShopQuery.docs.isEmpty) {
        print('⚠️ 該当するドリンクの店舗が見つかりません');
        return [];
      }
      
      final shopIds = drinkShopQuery.docs
          .map((doc) => doc.data()['shopId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
      final drinkShopLinks = drinkShopQuery.docs
          .map((doc) => DrinkShopLink.fromFirestore(doc))
          .toList();
      
      // 3. 店舗情報を地理的範囲で絞り込み
      final shopsQuery = await _firestore
          .collection('shops')
          .where(FieldPath.documentId, whereIn: shopIds.take(10).toList()) // Firestore制限対応
          .where('lat', isGreaterThan: bounds.southWest.latitude)
          .where('lat', isLessThan: bounds.northEast.latitude)
          .get();
      
      // 4. 精密な距離計算とフィルタリング
      final result = <ShopWithPrice>[];
      
      for (final shopDoc in shopsQuery.docs) {
        final shop = Shop.fromFirestore(shopDoc);
        final distance = _calculateDistance(latitude, longitude, shop.lat, shop.lng);
        
        if (distance <= radiusKm) {
          // 対応するDrinkShopLinkを見つける
          final drinkShopLink = drinkShopLinks.firstWhere(
            (link) => link.shopId == shop.id,
            orElse: () => throw Exception('DrinkShopLink not found'),
          );
          
          result.add(ShopWithPrice(
            shop: shop,
            drinkShopLink: drinkShopLink,
            distance: distance,
          ));
        }
      }
      
      // 距離でソート
      result.sort((a, b) => a.distance.compareTo(b.distance));
      
      return result;
      
    } catch (e) {
      print('❌ Firestore検索エラー: $e');
      rethrow;
    }
  }

  /// 地理的境界を計算
  GeoBounds _calculateBounds(double lat, double lng, double radiusKm) {
    const double kmPerDegree = 111.0;
    final double latDelta = radiusKm / kmPerDegree;
    final double lngDelta = radiusKm / (kmPerDegree * cos(lat * pi / 180));
    
    return GeoBounds(
      southWest: GeoPoint(lat - latDelta, lng - lngDelta),
      northEast: GeoPoint(lat + latDelta, lng + lngDelta),
    );
  }

  /// 2点間の距離を計算（ハヴァサイン公式）
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371.0; // 地球の半径（km）
    
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLng = (lng2 - lng1) * pi / 180;
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// キャッシュキー生成
  String _generateCacheKey(double lat, double lng, String drinkId, double radius) {
    // 座標を100m単位で丸めてキャッシュ効率を向上
    final roundedLat = (lat * 1000).round() / 1000;
    final roundedLng = (lng * 1000).round() / 1000;
    return 'geo_${roundedLat}_${roundedLng}_${drinkId}_$radius';
  }

  /// メモリキャッシュチェック
  List<ShopWithPrice>? _checkMemoryCache(String key) {
    final cached = _memoryCache[key];
    if (cached != null && !cached.isExpired(MEMORY_CACHE_TTL)) {
      return cached.shops;
    }
    return null;
  }

  /// メモリキャッシュに保存
  void _saveToMemoryCache(String key, List<ShopWithPrice> shops) {
    // キャッシュサイズ制限
    if (_memoryCache.length >= MAX_MEMORY_CACHE_SIZE) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    
    _memoryCache[key] = CachedSearchResult(shops, DateTime.now());
  }

  /// ディスクキャッシュチェック
  Future<List<ShopWithPrice>?> _checkDiskCache(String key) async {
    try {
      final cachedJson = _prefs?.getString('cache_$key');
      if (cachedJson != null) {
        final cachedData = json.decode(cachedJson);
        final cachedAt = DateTime.parse(cachedData['cachedAt']);
        
        if (DateTime.now().difference(cachedAt) <= DISK_CACHE_TTL) {
          final shopsJson = cachedData['shops'] as List;
          return shopsJson.map((json) => ShopWithPrice.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('⚠️ ディスクキャッシュ読み込みエラー: $e');
    }
    return null;
  }

  /// ディスクキャッシュに保存
  Future<void> _saveToDiskCache(String key, List<ShopWithPrice> shops) async {
    try {
      final cacheData = {
        'shops': shops.map((shop) => shop.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      };
      
      await _prefs?.setString('cache_$key', json.encode(cacheData));
    } catch (e) {
      print('⚠️ ディスクキャッシュ保存エラー: $e');
    }
  }

  /// 古いキャッシュを取得（フォールバック用）
  Future<List<ShopWithPrice>?> _getStaleCache(
    double lat, double lng, String drinkId, double radius
  ) async {
    final key = _generateCacheKey(lat, lng, drinkId, radius);
    
    // メモリから古いキャッシュを取得
    final memoryResult = _memoryCache[key];
    if (memoryResult != null) {
      return memoryResult.shops;
    }
    
    // ディスクから古いキャッシュを取得
    try {
      final cachedJson = _prefs?.getString('cache_$key');
      if (cachedJson != null) {
        final cachedData = json.decode(cachedJson);
        final shopsJson = cachedData['shops'] as List;
        return shopsJson.map((json) => ShopWithPrice.fromJson(json)).toList();
      }
    } catch (e) {
      print('⚠️ 古いキャッシュ取得エラー: $e');
    }
    
    return null;
  }

  /// キャッシュクリア
  Future<void> clearCache() async {
    _memoryCache.clear();
    final keys = _prefs?.getKeys().where((key) => key.startsWith('cache_')).toList() ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    print('🗑️ キャッシュクリア完了');
  }
}

/// キャッシュされた検索結果
class CachedSearchResult {
  final List<ShopWithPrice> shops;
  final DateTime cachedAt;
  
  CachedSearchResult(this.shops, this.cachedAt);
  
  bool isExpired(Duration ttl) {
    return DateTime.now().difference(cachedAt) > ttl;
  }
}

/// 地理的境界
class GeoBounds {
  final GeoPoint southWest;
  final GeoPoint northEast;
  
  GeoBounds({required this.southWest, required this.northEast});
}

// ShopWithPriceクラスは既存のモデルを使用
