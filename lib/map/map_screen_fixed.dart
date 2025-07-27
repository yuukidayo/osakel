import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../store/models/shop_with_price.dart';
import '../store/screens/shop_detail_screen.dart';
import 'map_view.dart';
import 'shop_card_page_view.dart';
import 'positioned_shop_cards.dart';
import 'search_area_button.dart';
import 'filter_bar.dart';


import 'map_screen_controller.dart';
import 'map_screen_state.dart';

class MapScreen extends StatefulWidget {
  final String? drinkId;

  const MapScreen({super.key, this.drinkId});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controllers and State
  late final MapScreenController _controller;
  late final MapScreenState _mapState;
  final Completer<GoogleMapController> _mapController = Completer();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // フィルター状態管理
  String? _selectedFilter;
  List<String> _activeFilters = [];
  String? _currentFacilityName;



  @override
  void initState() {
    super.initState();
    debugPrint('🗺️ MapScreen: initState開始 - drinkId: ${widget.drinkId}');
    
    // Initialize controller and state
    _controller = MapScreenController();
    _mapState = MapScreenState();
    
    // PageControllerをMapScreenControllerに設定（マーカータップ時のカード連動のため）
    _controller.setPageController(_pageController);
    
    // Listen to controller state changes
    _controller.addListener(_onControllerStateChanged);
    
    // Initialize location-based search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.initializeLocationBasedSearch(widget.drinkId ?? '');
      }
    });
  }

  
  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    _mapState.dispose();
    super.dispose();
  }

  // Controller state change listener
  void _onControllerStateChanged() {
    if (mounted) {
      setState(() {
        // UI will rebuild with new controller state
      });
    }
  }

  // 初回フォーカス処理

  
  // 初回フォーカス処理（安全版）

  

  

  

  
  // 選択された店舗を更新
  void _updateSelectedShop(ShopWithPrice shop) {
    _controller.updateSelectedShop(shop);
  }
  
  // 地図を店舗の位置に移動
  void _animateToShop(ShopWithPrice shop) {
    _mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(shop.shop.lat, shop.shop.lng)),
      );
    });
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

  

  

  

  
  
  /// 現在のエリアで再検索を実行
  Future<void> _searchCurrentArea() async {
    if (_controller.currentMapCenter == null || _controller.isSearchingNearby) return;
    
    // コントローラーに検索を依頼
    await _controller.searchCurrentArea();
    
    // 成功メッセージを表示
    _showSearchResultSnackBar(_controller.shopsWithPrice.length);
  }
  
  /// 検索結果のスナックバー表示
  void _showSearchResultSnackBar(int resultCount) {
    if (!mounted) return;
    
    final message = resultCount > 0 
        ? '$resultCount件の店舗が見つかりました'
        : 'このエリアには店舗が見つかりませんでした';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              resultCount > 0 ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: resultCount > 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// 地図のカメラ移動時に現在の中心位置を更新
  void _onCameraMove(CameraPosition position) {
    // 頻繁に呼ばれるので、デバウンス処理は不要
    // 現在の地図中心位置を更新
    _controller.onCameraMove(position);
    
    // デバッグログ（本番では削除推奨）
    // debugPrint('📍 地図中心位置更新: ${position.target.latitude}, ${position.target.longitude}');
  }

  /// フィルター選択時の処理
  void _onFilterSelected(String filter) {
    setState(() {
      // 新しいピル型フィルターの処理
      if (filter == '営業中') {
        if (_activeFilters.contains('営業中')) {
          _activeFilters.remove('営業中');
        } else {
          _activeFilters.add('営業中');
        }
      } else if (filter == '日帰り入浴可') {
        if (_activeFilters.contains('日帰り入浴可')) {
          _activeFilters.remove('日帰り入浴可');
        } else {
          _activeFilters.add('日帰り入浴可');
        }
      } else if (filter == 'facility') {
        // 施設名タップ時の処理（今後実装）
        _showFilterBottomSheet('施設情報');
      } else {
        // 従来のフィルター（エリア、カテゴリ、特徴）
        _selectedFilter = _selectedFilter == filter ? null : filter;
        _handleFilterAction(filter);
      }
      
      // サンプル施設名を設定（実際の実装では選択された店舗から取得）
      if (_controller.shopsWithPrice.isNotEmpty) {
        _currentFacilityName = _controller.shopsWithPrice.first.shop.name;
      }
    });
  }
  
  /// フィルターアクションの処理
  void _handleFilterAction(String filter) {
    switch (filter) {
      case 'area':
        // エリア検索の処理（今後実装）
        _showFilterBottomSheet('エリア');
        break;
      case 'category':
        // カテゴリ検索の処理（今後実装）
        _showFilterBottomSheet('カテゴリ');
        break;
      case 'feature':
        // 特徴検索の処理（今後実装）
        _showFilterBottomSheet('特徴');
        break;
    }
  }
  
  /// フィルターボトムシート表示
  void _showFilterBottomSheet(String filterType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ハンドルバー
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // タイトル
            Text(
              filterType,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // 実装中メッセージ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '実装中',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('閉じる'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Google Map（コンポーネント化）
          MapView(
            markers: _controller.markers,
            initialCameraPosition: _controller.initialCameraPosition,
            isLoading: !_controller.isLocationReady,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              _controller.updateMarkerPositions();
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: () => _controller.updateMarkerPositions(),
          ),
          
          // フィルターバーを最上部に配置
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: FilterBar(
              selectedFilter: _selectedFilter,
              onFilterSelected: _onFilterSelected,
              activeFilterCount: _activeFilters.length,
              facilityName: _currentFacilityName,
              activeFilters: _activeFilters,
            ),
          ),
          
          // 「このエリアで再検索」ボタンをフィルターバーの下に配置
          Positioned(
            top: MediaQuery.of(context).padding.top + 72, // フィルターバー分下げる
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SizedBox(height: 12), // フィルターバーとの間隔12px
                SearchAreaButton(
                  isVisible: _controller.currentMapCenter != null && !_controller.isLoading,
                  isSearching: _controller.isSearchingNearby,
                  onPressed: _searchCurrentArea,
                ),
              ],
            ),
          ),
          
          // 店舗カードをページビューで表示（コンポーネント化）
          PositionedShopCards(
            shops: _controller.shopsWithPrice,
            pageController: _pageController,
            onPageChanged: (index) {
              if (index >= 0 && index < _controller.shopsWithPrice.length) {
                _updateSelectedShop(_controller.shopsWithPrice[index]);
                _animateToShop(_controller.shopsWithPrice[index]);
              }
            },
            onShopTap: _navigateToShopDetail,
          ),
            
          // ローディング表示
          if (_controller.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            

          

        ],
      ),
    );
  }
}
