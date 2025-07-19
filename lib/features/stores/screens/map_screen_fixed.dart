import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/shop_with_price.dart';
import 'shop_detail_screen.dart';
import '../../../core/utils/custom_marker_generator.dart';
// mapコンポーネントのimport
import '../widgets/map/map_view.dart';
import '../widgets/map/map_control_buttons.dart';
import '../widgets/map/shop_card_page_view.dart';
import '../widgets/map/search_box.dart';
import '../widgets/map/location_search_bar.dart';
import '../widgets/map/empty_state_widget.dart';
import '../widgets/map/location_data_service.dart';
import '../widgets/map/map_data_service.dart';
import '../widgets/map/mock_data_service.dart';

class MapScreen extends StatefulWidget {
  final String? drinkId;

  const MapScreen({Key? key, this.drinkId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapDataService _mapDataService = MapDataService();
  final Completer<GoogleMapController> _mapController = Completer();

  final PageController _pageController = PageController(viewportFraction: 0.85); // 次のカードが少し見えるように調整
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  ShopWithPrice? _selectedShop;
  bool _isLoading = false; // ロード状態を管理
  bool _isInitialFocusComplete = false; // 初回フォーカス完了フラグ
  
  // Shop data
  List<ShopWithPrice> _shopsWithPrice = [];
  
  // Google Map markers
  Set<Marker> _markers = {};
  
  // Initial camera position centered on Tokyo Station
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 15,
  );



  @override
  void initState() {
    super.initState();
    // 初期化時に空のリストを作成
    _shopsWithPrice = [];
    
    // データを読み込む前に少し遅延させる（UIの初期化を待つため）
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadShopsData();
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  // 店舗データを読み込む
  Future<void> _loadShopsData() async {
    print('🗺️ MapScreen: _loadShopsData開始 - drinkId: ${widget.drinkId}');
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🗺️ MapScreen: MapDataServiceでデータ取得開始');
      final shops = await _mapDataService.loadShopsData(drinkId: widget.drinkId);
      print('🗺️ MapScreen: データ取得完了 - 店舗数: ${shops.length}');
      
      setState(() {
        _shopsWithPrice = shops;
        _isLoading = false;
      });
      print('🗺️ MapScreen: setState完了');
      
      // 初回フォーカス処理
      print('🗺️ MapScreen: 初回フォーカス処理開始');
      await _performInitialFocus();
      print('🗺️ MapScreen: 初回フォーカス処理完了');
      
      // マーカーを更新
      print('🗺️ MapScreen: マーカー更新開始');
      _updateMarkerPositions();
      print('🗺️ MapScreen: マーカー更新完了');
      
      print('🗺️ MapScreen: _loadShopsData完了');
      
    } catch (e) {
      print('❌ MapScreen: エラー発生 - $e');
      // エラー時はモックデータを生成
      _generateMockData();
    }
  }
  
  // 初回フォーカス処理
  Future<void> _performInitialFocus() async {
    if (_shopsWithPrice.isNotEmpty && !_isInitialFocusComplete) {
      await _mapDataService.performInitialFocus(
        shops: _shopsWithPrice,
        mapController: _mapController,
        pageController: _pageController,
        onShopSelected: (shop) {
          setState(() {
            _selectedShop = shop;
            _isInitialFocusComplete = true;
          });
        },
      );
    }
  }
  
  // モックデータを生成
  void _generateMockData() async {
    final mockShops = MockDataService.generateMockShops(drinkId: widget.drinkId);
    
    setState(() {
      _shopsWithPrice = mockShops;
      _isLoading = false;
    });
    
    // 初回フォーカス処理
    await _performInitialFocus();
    
    // マーカーを更新
    _updateMarkerPositions();
  }
  

  
  // 選択された店舗を更新
  void _updateSelectedShop(ShopWithPrice shop) {
    setState(() {
      _selectedShop = shop;
    });
  }
  
  // 地図を店舗の位置に移動
  void _animateToShop(ShopWithPrice shop) {
    _mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(shop.shop.lat, shop.shop.lng)),
      );
    });
  }
  
  // マーカーの位置を更新
  void _updateMarkerPositions() async {
    setState(() {
      _isLoading = true; // データ読み込み開始
    });
    _markers.clear();
    Set<Marker> markers = {};
    
    for (int i = 0; i < _shopsWithPrice.length; i++) {
      final shop = _shopsWithPrice[i].shop;
      final price = _shopsWithPrice[i].drinkShopLink.price;
      final isFirstShop = i == 0; // 先頭店舗かどうか
      final isSelected = _selectedShop?.shop.id == shop.id;
      
      // カスタムマーカーを生成
      final BitmapDescriptor markerIcon = await CustomMarkerGenerator.createPriceMarker(
        price: price,
        isSelected: isSelected || (isFirstShop && !_isInitialFocusComplete),
      );
      
      // マーカーを作成
      final marker = Marker(
        markerId: MarkerId(shop.id),
        position: LatLng(shop.lat, shop.lng),
        icon: markerIcon,
        onTap: () {
          // print('マーカーがタップされました: ${shop.id}');
          _updateSelectedShop(_shopsWithPrice[i]);
          
          // PageViewを該当のインデックスに移動
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      );
      
      markers.add(marker);
    }
    
    setState(() {
      _markers = markers;
      _isLoading = false; // データ読み込み完了
    });
    
    // 初回フォーカス完了後、先頭店舗のInfoWindowを表示
    if (_isInitialFocusComplete && _shopsWithPrice.isNotEmpty && _selectedShop != null) {
      // 先頭店舗のInfoWindowを自動表示
      if (_shopsWithPrice.isNotEmpty) {
        final firstShop = _shopsWithPrice.first;
        final markerId = firstShop.shop.id;
        final controller = await _mapController.future;
        controller.showMarkerInfoWindow(MarkerId(markerId));
      }
    }
  }
  
  // 店舗詳細画面に遷移
  void _navigateToShopDetail(ShopWithPrice shopWithPrice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailScreen(
          shop: shopWithPrice.shop,
          price: shopWithPrice.drinkShopLink.price.toInt(),
        ),
      ),
    );
  }

  

  
  // 検索モーダルの表示状態
  bool _isSearchModalVisible = false;
  
  // 検索ボックスのフォーカス管理
  final FocusNode _searchFocusNode = FocusNode();
  
  // モーダル内の検索ボックスのコントローラ
  final TextEditingController _searchController = TextEditingController();
  
  // 場所を検索して地図を移動
  void _searchLocation(String location) {
    // キーボードを閉じる
    FocusManager.instance.primaryFocus?.unfocus();
    
    // モーダルを閉じる
    setState(() {
      _searchController.clear();
      _isSearchModalVisible = false;
    });
    
    // 位置情報を取得
    final coordinates = LocationDataService.getLocationCoordinates(location);
    
    if (coordinates != null) {
      // 地図を選択された場所に移動
      _mapController.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: coordinates,
              zoom: 14.0,
            ),
          ),
        );
      });
    }
  }
  
  // モーダル検索ボックスを表示
  void _showSearchModal() {
    setState(() {
      _isSearchModalVisible = true;
    });
    
    // モーダル表示後に検索ボックスに自動フォーカス
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }
  
  // モーダル検索ボックスを閉じる
  void _hideSearchModal() {
    setState(() {
      _isSearchModalVisible = false;
      _searchController.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }
  

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Google Map（コンポーネント化）
          MapView(
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              _updateMarkerPositions();
            },
            onCameraIdle: () => _updateMarkerPositions(),
          ),
          
          // 検索ボックスを次に配置（地図の上に表示）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 検索ボックス（コンポーネント化）
                SearchBox(
                  onTap: _showSearchModal,
                ),
              ],
            ),
          ),
          
          // マップコントロール（コンポーネント化）
          Positioned(
            right: 16,
            bottom: 236, // 店舗カードの固定高さ + マージン
            child: MapControlButtons(
              onCurrentLocation: () async {
                final controller = await _mapController.future;
                controller.animateCamera(CameraUpdate.newCameraPosition(const CameraPosition(
                  target: LatLng(35.681236, 139.767125),
                  zoom: 15,
                )));
              },
              onZoomIn: () async {
                final controller = await _mapController.future;
                controller.animateCamera(CameraUpdate.zoomIn());
              },
              onZoomOut: () async {
                final controller = await _mapController.future;
                controller.animateCamera(CameraUpdate.zoomOut());
              },
              onSearch: _showSearchModal,
            ),
          ),
          
          // 店舗カードをページビューで表示（横スワイプのみ可能）
          if (_shopsWithPrice.isNotEmpty)
            Positioned(
              bottom: 30, // 下部に30pxのマージンを追加
              left: 0,
              right: 0,
              height: 300, // カードの高さを固定
              child: Stack(
                children: [
                  // 店舗カードページビュー（コンポーネント化）
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 150,
                    child: ShopCardPageView(
                      shops: _shopsWithPrice,
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (index >= 0 && index < _shopsWithPrice.length) {
                          _updateSelectedShop(_shopsWithPrice[index]);
                          _animateToShop(_shopsWithPrice[index]);
                        }
                      },
                      onShopTap: _navigateToShopDetail,
                    ),
                  ),
                ],
              ),
            ),
            
          // ローディング表示
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          // データが空の場合
          if (!_isLoading && _shopsWithPrice.isEmpty)
            EmptyStateWidget(
              onGenerateMockData: _generateMockData,
            ),
          
          // 全画面検索モーダル（コンポーネント化）
          if (_isSearchModalVisible)
            Positioned.fill(
              child: LocationSearchBar(
                locationSuggestions: LocationDataService.locationSuggestions,
                onLocationSearch: _searchLocation,
                onClose: _hideSearchModal,
              ),
            ),
        ],
      ),
    );
  }
}
