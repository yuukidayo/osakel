import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../store/models/shop_with_price.dart';
import '../core/services/geo_search_service.dart';
import '../core/services/location_service.dart';
import 'map_data_service.dart';
import 'mock_data_service.dart';
import '../../widgets/map/simple_marker_generator.dart';

/// MapScreen のビジネスロジックを管理するコントローラー
class MapScreenController extends ChangeNotifier {
  // サービス
  final GeoSearchService _geoSearchService = GeoSearchService();
  final LocationService _locationService = LocationService();
  final MapDataService _mapDataService = MapDataService();

  // 状態管理
  bool _isLoading = false;
  bool _isSearchingNearby = false;
  bool _isInitialFocusComplete = false;
  bool _isLocationReady = false;
  List<ShopWithPrice> _shopsWithPrice = [];
  Set<Marker> _markers = {};
  ShopWithPrice? _selectedShop;
  Position? _currentPosition;
  LatLng? _currentMapCenter;
  String? _lastSearchDrinkId;
  PageController? _pageController;

  // コールバック
  VoidCallback? onStateChanged;
  Function(String)? onError;
  Function(String)? onSuccess;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSearchingNearby => _isSearchingNearby;
  bool get isInitialFocusComplete => _isInitialFocusComplete;
  bool get isLocationReady => _isLocationReady;
  List<ShopWithPrice> get shopsWithPrice => _shopsWithPrice;
  Set<Marker> get markers => _markers;
  ShopWithPrice? get selectedShop => _selectedShop;
  LatLng? get currentMapCenter => _currentMapCenter;
  
  /// 初期カメラ位置を取得
  CameraPosition? get initialCameraPosition {
    if (_currentMapCenter != null) {
      return CameraPosition(
        target: _currentMapCenter!,
        zoom: 15.0,
      );
    }
    return null;
  }

  /// 初期化
  Future<void> initialize(String? drinkId) async {
    debugPrint('🎮 MapScreenController: 初期化開始');
    _lastSearchDrinkId = drinkId;
    
    // 現在地を取得して地図中心を設定
    await _initializeLocationBasedSearch();
  }

  /// 現在地ベースの初期化
  Future<void> _initializeLocationBasedSearch() async {
    _setLoading(true);
    
    try {
      debugPrint('📍 現在地取得開始');
      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition != null) {
        _currentMapCenter = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        _isLocationReady = true;
        debugPrint('✅ 現在地取得成功: $_currentMapCenter');
        
        // UI更新を通知（マップ表示開始）
        _notifyStateChanged();
        
        // 現在地周辺5km以内の店舗を自動検索
        await _performInitialLocationSearch();
      } else {
        debugPrint('⚠️ 現在地取得失敗、デフォルト位置を使用');
        _isLocationReady = true; // フォールバック時もマップ表示
        await _fallbackToDefaultLocation();
      }
    } catch (e) {
      debugPrint('❌ 位置情報取得エラー: $e');
      _isLocationReady = true; // エラー時もマップ表示
      await _fallbackToDefaultLocation();
    } finally {
      _setLoading(false);
    }
  }

  /// 初回現在地ベースの検索とマップフォーカス
  Future<void> _performInitialLocationSearch() async {
    if (_currentMapCenter == null) {
      debugPrint('⚠️ 現在地が設定されていません');
      return;
    }

    try {
      debugPrint('🎯 初回現在地検索開始: $_currentMapCenter');
      
      // 有効なdrinkIdを取得
      String searchDrinkId = _lastSearchDrinkId ?? await _getFirstAvailableDrinkId();
      debugPrint('🎯 使用するdrinkId: $searchDrinkId');
      
      // 現在地周辺5km圏内の店舗を検索
      final nearbyShops = await _geoSearchService.searchNearbyShops(
        latitude: _currentMapCenter!.latitude,
        longitude: _currentMapCenter!.longitude,
        drinkId: searchDrinkId,
        radiusKm: 5.0,
      );
      
      _shopsWithPrice = nearbyShops;
      _lastSearchDrinkId = searchDrinkId;
      
      if (nearbyShops.isNotEmpty) {
        _selectedShop = nearbyShops.first;
        debugPrint('🎯 初回検索完了: ${nearbyShops.length}件の店舗が見つかりました');
        onSuccess?.call('${nearbyShops.length}件の店舗が見つかりました');
      } else {
        debugPrint('🎯 初回検索完了: 店舗が見つかりませんでした');
        onSuccess?.call('現在地周辺に店舗が見つかりませんでした');
      }
      
      await _updateMarkerPositions();
      _notifyStateChanged();
      
    } catch (e) {
      debugPrint('❌ 初回現在地検索エラー: $e');
      onError?.call('店舗の検索に失敗しました');
    }
  }

  /// フォールバック処理
  Future<void> _fallbackToDefaultLocation() async {
    try {
      // 東京駅をデフォルト位置に設定
      _currentMapCenter = const LatLng(35.6812, 139.7671);
      debugPrint('📍 デフォルト位置設定: $_currentMapCenter');
      
      await _loadShopsDataSafely();
    } catch (e) {
      debugPrint('❌ フォールバック処理エラー: $e');
      // モックデータでフォールバック
      _shopsWithPrice = MockDataService.generateMockShops(drinkId: _lastSearchDrinkId ?? 'default_drink_id');
      await _updateMarkerPositions();
      _notifyStateChanged();
    }
  }

  /// 安全な店舗データ読み込み
  Future<void> _loadShopsDataSafely() async {
    try {
      final shops = await _mapDataService.loadShopsData(drinkId: _lastSearchDrinkId ?? 'default_drink_id');
      _shopsWithPrice = shops;
      _selectedShop = shops.isNotEmpty ? shops.first : null;
      
      debugPrint('✅ 店舗データ読み込み完了: ${shops.length}件');
      
      await _updateMarkerPositions();
      _notifyStateChanged();
    } catch (e) {
      debugPrint('❌ 店舗データ読み込みエラー: $e');
      // エラー時はモックデータでフォールバック
      _shopsWithPrice = MockDataService.generateMockShops(drinkId: _lastSearchDrinkId ?? 'default_drink_id');
      await _updateMarkerPositions();
      _notifyStateChanged();
    }
  }

  /// 現在のエリアで再検索
  Future<void> searchCurrentArea() async {
    if (_currentMapCenter == null || _isSearchingNearby) return;
    
    _setSearchingNearby(true);
    
    try {
      debugPrint('🔍 現在のエリアで再検索開始: $_currentMapCenter');
      
      // 有効なdrinkIdを取得
      String searchDrinkId = _lastSearchDrinkId ?? await _getFirstAvailableDrinkId();
      debugPrint('🔍 使用するdrinkId: $searchDrinkId');
      
      final nearbyShops = await _geoSearchService.searchNearbyShops(
        latitude: _currentMapCenter!.latitude,
        longitude: _currentMapCenter!.longitude,
        drinkId: searchDrinkId,
        radiusKm: 5.0,
      );
      
      _shopsWithPrice = nearbyShops;
      _selectedShop = nearbyShops.isNotEmpty ? nearbyShops.first : null;
      _lastSearchDrinkId = searchDrinkId;
      
      await _updateMarkerPositions();
      onSuccess?.call('${nearbyShops.length}件の店舗が見つかりました');
      _notifyStateChanged();
      
      debugPrint('✅ 再検索完了: ${nearbyShops.length}件の店舗が見つかりました');
    } catch (e) {
      debugPrint('❌ エリア再検索エラー: $e');
      onError?.call('検索に失敗しました。もう一度お試しください。');
    } finally {
      _setSearchingNearby(false);
    }
  }

  /// マーカー位置更新
  Future<void> _updateMarkerPositions() async {
    _markers.clear();
    
    if (_shopsWithPrice.isEmpty) return;
    
    for (int i = 0; i < _shopsWithPrice.length; i++) {
      final shopWithPrice = _shopsWithPrice[i];
      final isSelected = _selectedShop?.shop.id == shopWithPrice.shop.id;
      
      try {
        // カスタムマーカーを生成
        final markerIcon = await SimpleMarkerGenerator.createPriceMarker(
          price: shopWithPrice.drinkShopLink.price,
          isSelected: isSelected,
        );
        
        final marker = Marker(
          markerId: MarkerId(shopWithPrice.shop.id),
          position: LatLng(shopWithPrice.shop.lat, shopWithPrice.shop.lng),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: shopWithPrice.shop.name,
            snippet: '¥${shopWithPrice.drinkShopLink.price.toStringAsFixed(0)}',
          ),
          onTap: () => updateSelectedShop(shopWithPrice),
        );
        
        _markers.add(marker);
      } catch (e) {
        debugPrint('⚠️ マーカー生成エラー (${shopWithPrice.shop.name}): $e');
        
        // フォールバック: デフォルトマーカーを使用
        final fallbackMarker = Marker(
          markerId: MarkerId(shopWithPrice.shop.id),
          position: LatLng(shopWithPrice.shop.lat, shopWithPrice.shop.lng),
          infoWindow: InfoWindow(
            title: shopWithPrice.shop.name,
            snippet: '¥${shopWithPrice.drinkShopLink.price.toStringAsFixed(0)}',
          ),
          onTap: () => updateSelectedShop(shopWithPrice),
        );
        _markers.add(fallbackMarker);
      }
    }
    
    _notifyStateChanged();
  }

  /// PageControllerを設定
  void setPageController(PageController pageController) {
    _pageController = pageController;
  }

  /// 選択店舗更新（マーカータップ時にカードも連動）
  void updateSelectedShop(ShopWithPrice shop) {
    _selectedShop = shop;
    
    // PageControllerが設定されている場合、該当ページにスクロール
    if (_pageController != null && _shopsWithPrice.isNotEmpty) {
      final index = _shopsWithPrice.indexWhere((s) => s.shop.id == shop.shop.id);
      if (index != -1 && index != _pageController!.page?.round()) {
        _pageController!.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    _notifyStateChanged();
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
    try {
      _shopsWithPrice = MockDataService.generateMockShops(drinkId: drinkId ?? 'default_drink_id');
      _selectedShop = _shopsWithPrice.isNotEmpty ? _shopsWithPrice.first : null;
      
      await _updateMarkerPositions();
      onSuccess?.call('${_shopsWithPrice.length}件の店舗データを生成しました');
      _notifyStateChanged();
    } catch (e) {
      debugPrint('❌ モックデータ生成エラー: $e');
      onError?.call('データの生成に失敗しました');
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

  /// 利用可能な最初のdrinkIdを取得
  Future<String> _getFirstAvailableDrinkId() async {
    try {
      // Firestoreからdrinksコレクションの最初のドキュメントIDを取得
      final snapshot = await FirebaseFirestore.instance
          .collection('drinks')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final drinkId = snapshot.docs.first.id;
        debugPrint('🔍 取得したdrinkId: $drinkId');
        return drinkId;
      }
    } catch (e) {
      debugPrint('❌ drinkId取得エラー: $e');
    }
    
    // フォールバック: 大阪関目周辺の店舗データに対応するID
    return 'oZTuXXMx1WaErBoCzYa1_duplicated';
  }

  /// 現在地ベースの初期検索
  Future<void> initializeLocationBasedSearch(String drinkId) async {
    debugPrint('🎮 MapScreenController: 現在地ベース検索開始 - drinkId: $drinkId');
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
    if (_currentMapCenter != null && !_isInitialFocusComplete) {
      debugPrint('🎮 MapScreenController: 初回フォーカス処理開始');
      
      try {
        _isInitialFocusComplete = true;
        
        // 地図のフォーカスを現在地に移動
        final controller = await mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentMapCenter!,
            15.0,
          ),
        );
        
        _notifyStateChanged();
        debugPrint('🎮 MapScreenController: 初回フォーカス処理完了');
      } catch (e) {
        debugPrint('⚠️ MapScreenController: 初回フォーカスエラー: $e');
      }
    }
  }

  /// リソース解放
  @override
  void dispose() {
    super.dispose();
  }
}
