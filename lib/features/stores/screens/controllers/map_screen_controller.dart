import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../models/shop_with_price.dart';
import '../../../../core/services/geo_search_service.dart';
import '../../../../core/services/location_service.dart';
import '../../widgets/map/map_data_service.dart';
import '../../widgets/map/mock_data_service.dart';
import '../../../../core/utils/custom_marker_generator.dart';

/// MapScreen のビジネスロジックを管理するコントローラー
class MapScreenController extends ChangeNotifier {
  // サービス
  final GeoSearchService _geoSearchService = GeoSearchService();
  final LocationService _locationService = LocationService();
  final MapDataService _mapDataService = MapDataService();

  // コールバック
  VoidCallback? onStateChanged;
  Function(String)? onError;
  Function(String)? onSuccess;

  // 状態
  bool _isLoading = false;
  bool _isSearchingNearby = false;
  bool _isInitialFocusComplete = false;
  List<ShopWithPrice> _shopsWithPrice = [];
  Set<Marker> _markers = {};
  ShopWithPrice? _selectedShop;
  Position? _currentPosition;
  LatLng? _currentMapCenter;
  String? _lastSearchDrinkId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSearchingNearby => _isSearchingNearby;
  bool get isInitialFocusComplete => _isInitialFocusComplete;
  List<ShopWithPrice> get shopsWithPrice => _shopsWithPrice;
  Set<Marker> get markers => _markers;
  ShopWithPrice? get selectedShop => _selectedShop;
  LatLng? get currentMapCenter => _currentMapCenter;

  /// 初期化
  Future<void> initialize(String? drinkId) async {
    print('🎮 MapScreenController: 初期化開始');
    _lastSearchDrinkId = drinkId;
    
    // 現在地を取得して地図中心を設定
    await _initializeLocationBasedSearch();
  }

  /// 現在地ベースの初期化
  Future<void> _initializeLocationBasedSearch() async {
    _setLoading(true);
    
    try {
      print('📍 現在地取得開始');
      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition != null) {
        _currentMapCenter = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        print('✅ 現在地取得成功: $_currentMapCenter');
        
        // 現在地から3km以内の店舗を検索
        await _searchNearbyShops();
      } else {
        print('⚠️ 現在地取得失敗、デフォルト位置を使用');
        await _fallbackToDefaultLocation();
      }
    } catch (e) {
      print('❌ 位置情報取得エラー: $e');
      await _fallbackToDefaultLocation();
    } finally {
      _setLoading(false);
    }
  }

  /// デフォルト位置（東京駅）へのフォールバック
  Future<void> _fallbackToDefaultLocation() async {
    print('🏢 デフォルト位置（東京駅）でフォールバック');
    _currentMapCenter = const LatLng(35.681236, 139.767125); // 東京駅
    await _loadShopsDataSafely();
  }

  /// 安全な店舗データ読み込み
  Future<void> _loadShopsDataSafely() async {
    try {
      print('📊 店舗データ読み込み開始');
      if (_lastSearchDrinkId != null && _lastSearchDrinkId!.isNotEmpty) {
        print('🎮 MapScreenController: MapDataServiceからドリンク関連店舗を取得');
        
        try {
          final shops = await _mapDataService.loadShopsData(drinkId: _lastSearchDrinkId!);
          print('🎮 MapScreenController: 取得した店舗数: ${shops.length}');
          _shopsWithPrice = shops;
        } catch (e) {
          print('⚠️ MapScreenController: MapDataServiceデータ取得エラー: $e');
        }
      } else {
        final shops = await _mapDataService.loadShopsData(drinkId: _lastSearchDrinkId ?? 'default_drink_id');
        
        _shopsWithPrice = shops;
        print('✅ 店舗データ読み込み完了: ${shops.length}件');
      }
      
      await _updateMarkerPositions();
      _notifyStateChanged();
    } catch (e) {
      print('❌ 店舗データ読み込みエラー: $e');
      // エラー時はモックデータでフォールバック
      _shopsWithPrice = MockDataService.generateMockShops(drinkId: _lastSearchDrinkId ?? 'default_drink_id');
    }
  }

  /// 近隣店舗検索
  Future<void> _searchNearbyShops() async {
    if (_currentMapCenter == null) return;
    
    try {
      final searchDrinkId = _lastSearchDrinkId ?? 'default_drink_id';
      
      final nearbyShops = await _geoSearchService.searchNearbyShops(
        latitude: _currentMapCenter!.latitude,
        longitude: _currentMapCenter!.longitude,
        drinkId: searchDrinkId,
        radiusKm: 3.0,
      );
      
      _shopsWithPrice = nearbyShops;
      _selectedShop = nearbyShops.isNotEmpty ? nearbyShops.first : null;
      
      print('✅ 近隣店舗検索完了: ${nearbyShops.length}件');
      
      await _updateMarkerPositions();
      _notifyStateChanged();
    } catch (e) {
      print('❌ 近隣店舗検索エラー: $e');
      // フォールバックとして既存のデータ読み込み方法を使用
      await _loadShopsDataSafely();
    }
  }

  /// 現在のエリアで再検索
  Future<void> searchCurrentArea() async {
    if (_currentMapCenter == null || _isSearchingNearby) return;
    
    _setSearchingNearby(true);
    
    try {
      print('🔍 現在のエリアで再検索開始: $_currentMapCenter');
      
      final searchDrinkId = _lastSearchDrinkId ?? 'default_drink_id';
      
      final nearbyShops = await _geoSearchService.searchNearbyShops(
        latitude: _currentMapCenter!.latitude,
        longitude: _currentMapCenter!.longitude,
        drinkId: searchDrinkId,
        radiusKm: 3.0,
      );
      
      _shopsWithPrice = nearbyShops;
      _selectedShop = nearbyShops.isNotEmpty ? nearbyShops.first : null;
      
      print('✅ 再検索完了: ${nearbyShops.length}件の店舗が見つかりました');
      
      await _updateMarkerPositions();
      onSuccess?.call('${nearbyShops.length}件の店舗が見つかりました');
      _notifyStateChanged();
      
    } catch (e) {
      print('❌ エリア再検索エラー: $e');
      onError?.call('検索に失敗しました。もう一度お試しください。');
    } finally {
      _setSearchingNearby(false);
    }
  }

  /// マーカー位置更新
  Future<void> _updateMarkerPositions() async {
    if (_shopsWithPrice.isEmpty) {
      _markers = {};
      _notifyStateChanged();
      return;
    }

    try {
      final newMarkers = <Marker>{};
      
      for (int i = 0; i < _shopsWithPrice.length; i++) {
        final shop = _shopsWithPrice[i];
        final isSelected = _selectedShop?.shop.id == shop.shop.id;
        
        // カスタムマーカー生成（エラーハンドリング付き）
        BitmapDescriptor markerIcon;
        try {
          markerIcon = await CustomMarkerGenerator.createPriceMarker(
            price: shop.drinkShopLink.price,
            isSelected: isSelected,
          );
        } catch (e) {
          print('⚠️ カスタムマーカー生成エラー: $e');
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
          );
        }

        final marker = Marker(
          markerId: MarkerId(shop.shop.id),
          position: LatLng(shop.shop.lat, shop.shop.lng),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: shop.shop.name,
            snippet: '¥${shop.drinkShopLink.price.toStringAsFixed(0)}',
          ),
        );
        
        newMarkers.add(marker);
      }
      
      _markers = newMarkers;
      print('📍 マーカー更新完了: ${_markers.length}個');
      _notifyStateChanged();
      
    } catch (e) {
      print('❌ マーカー更新エラー: $e');
    }
  }

  /// 選択店舗更新
  void updateSelectedShop(ShopWithPrice shop) {
    _selectedShop = shop;
    _updateMarkerPositions(); // マーカーの選択状態を更新
  }

  /// カメラ移動時の処理
  void onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;
  }

  /// 検索ボタン表示判定
  bool shouldShowSearchButton() {
    return _currentMapCenter != null && !_isLoading;
  }

  /// モックデータ生成
  Future<void> generateMockData(String? drinkId) async {
    _setLoading(true);
    
    try {
      final mockShops = MockDataService.generateMockShops(drinkId: drinkId ?? 'default_drink_id');
      _shopsWithPrice = mockShops;
      _selectedShop = mockShops.isNotEmpty ? mockShops.first : null;
      
      await _updateMarkerPositions();
      onSuccess?.call('モックデータを生成しました');
      _notifyStateChanged();
    } catch (e) {
      print('❌ モックデータ生成エラー: $e');
      onError?.call('モックデータの生成に失敗しました');
    } finally {
      _setLoading(false);
    }
  }

  /// 状態変更通知
  void _notifyStateChanged() {
    notifyListeners();
    onStateChanged?.call();
  }

  /// ローディング状態設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyStateChanged();
  }

  /// 検索中状態設定
  void _setSearchingNearby(bool searching) {
    _isSearchingNearby = searching;
    _notifyStateChanged();
  }

  /// 現在地ベースの初期検索
  Future<void> initializeLocationBasedSearch(String drinkId) async {
    print('🎮 MapScreenController: 現在地ベース検索開始 - drinkId: $drinkId');
    _lastSearchDrinkId = drinkId;
    await _initializeLocationBasedSearch();
  }

  /// マーカー位置更新（public）
  Future<void> updateMarkerPositions() async {
    await _updateMarkerPositions();
  }

  /// 初回フォーカス処理
  Future<void> performInitialFocus({
    required Completer<GoogleMapController> mapController,
    required PageController pageController,
  }) async {
    if (_shopsWithPrice.isNotEmpty && !_isInitialFocusComplete) {
      print('🎮 MapScreenController: 初回フォーカス処理開始');
      
      try {
        final firstShop = _shopsWithPrice.first;
        _selectedShop = firstShop;
        _isInitialFocusComplete = true;
        
        // 地図のフォーカスを先頭店舗に移動
        final controller = await mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(firstShop.shop.lat, firstShop.shop.lng),
            15.0,
          ),
        );
        
        _notifyStateChanged();
        print('🎮 MapScreenController: 初回フォーカス処理完了');
      } catch (e) {
        print('⚠️ MapScreenController: 初回フォーカスエラー: $e');
      }
    }
  }

  /// リソース解放
  @override
  void dispose() {
    print('🎮 MapScreenController: リソース解放');
    super.dispose();
  }
}
