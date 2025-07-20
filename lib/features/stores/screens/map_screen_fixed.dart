import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/shop_with_price.dart';
import 'shop_detail_screen.dart';
import '../widgets/map/map_view.dart';
import '../widgets/map/map_control_buttons.dart';
import '../widgets/map/shop_card_page_view.dart';


import 'controllers/map_screen_controller.dart';
import 'models/map_screen_state.dart';

class MapScreen extends StatefulWidget {
  final String? drinkId;

  const MapScreen({Key? key, this.drinkId}) : super(key: key);

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



  @override
  void initState() {
    super.initState();
    print('🗺️ MapScreen: initState開始 - drinkId: ${widget.drinkId}');
    
    // Initialize controller and state
    _controller = MapScreenController();
    _mapState = MapScreenState();
    
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

  

  

  

  
  /// 「このエリアで再検索」ボタンのUI
  Widget _buildSearchAreaButton() {
    return AnimatedOpacity(
      opacity: _shouldShowSearchButton() ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _controller.isSearchingNearby ? null : _searchCurrentArea,
          icon: _controller.isSearchingNearby 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.search, size: 20),
          label: Text(
            _controller.isSearchingNearby ? '検索中...' : 'このエリアで再検索',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.blue.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
  
  /// 検索ボタンを表示すべきかどうかを判定
  bool _shouldShowSearchButton() {
    // 現在地が取得できていて、かつローディング中でない場合に表示
    return _controller.currentMapCenter != null && !_controller.isLoading;
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
        ? '${resultCount}件の店舗が見つかりました'
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
    // print('📍 地図中心位置更新: ${position.target.latitude}, ${position.target.longitude}');
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
          
          // 検索ボックスを次に配置（地図の上に表示）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                
                // 「このエリアで再検索」ボタン
                _buildSearchAreaButton(),
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
            ),
          ),
          
          // 店舗カードをページビューで表示（横スワイプのみ可能）
          if (_controller.shopsWithPrice.isNotEmpty)
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
                      shops: _controller.shopsWithPrice,
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (index >= 0 && index < _controller.shopsWithPrice.length) {
                          _updateSelectedShop(_controller.shopsWithPrice[index]);
                          _animateToShop(_controller.shopsWithPrice[index]);
                        }
                      },
                      onShopTap: _navigateToShopDetail,
                    ),
                  ),
                ],
              ),
            ),
            
          // ローディング表示
          if (_controller.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          // データが空の場合
          if (!_controller.isLoading && _controller.shopsWithPrice.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('データがありません'),
              ),
            ),
          

        ],
      ),
    );
  }
}
