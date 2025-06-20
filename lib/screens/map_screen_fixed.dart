import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osakel/models/shop.dart';
import 'package:osakel/models/shop_with_price.dart';
import 'package:osakel/models/drink_shop_link.dart';
import 'package:osakel/screens/shop_detail_screen.dart';
import 'package:osakel/services/firestore_service.dart';
import 'package:osakel/utils/custom_marker_generator.dart';
import 'package:osakel/widgets/shop_card_widget.dart';

class MapScreen extends StatefulWidget {
  final String? drinkId;

  const MapScreen({Key? key, this.drinkId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Completer<GoogleMapController> _mapController = Completer();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 0.93);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  ShopWithPrice? _selectedShop;
  bool _isLoading = true;
  
  // Shop data
  List<ShopWithPrice> _shopsWithPrice = [];
  
  // Google Map markers
  Set<Marker> _markers = {};
  
  // Initial camera position centered on Tokyo Station
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 15,
  );

  // スクロール関連の状態変数
  bool _isScrolling = false;
  bool _isUserScrolling = false;
  bool _isSnapping = false;
  bool _isProgrammaticScrolling = false;
  DateTime _lastScrollTime = DateTime.now();
  double _lastScrollPosition = 0.0;
  int _scrollRetryCount = 0;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    // 初期化時に空のリストを作成
    _shopsWithPrice = [];
    // print('MapScreen initialized with drinkId: ${widget.drinkId}');
    
    // データを読み込む前に少し遅延させる（UIの初期化を待つため）
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadShopsData();
    });
  }

  // 店舗データを読み込む
  Future<void> _loadShopsData() async {
    // print('店舗データの読み込み開始');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Firestoreからデータを取得
      List<ShopWithPrice> shops = [];
      
      if (widget.drinkId != null) {
        // ドリンクIDから関連する店舗を取得
        final drinkShopLinks = await _firestoreService.getDrinkShopLinks(widget.drinkId!);
        
        for (var link in drinkShopLinks) {
          final shop = await _firestoreService.getShop(link.shopId);
          if (shop != null) {
            shops.add(ShopWithPrice(shop: shop, drinkShopLink: link));
          }
        }
      }
      
      // データが取得できなかった場合はモックデータを生成
      if (shops.isEmpty) {
        // print('店舗データが取得できなかったため、モックデータを生成します');
        _generateMockData();
        return;
      }
      
      setState(() {
        _shopsWithPrice = shops;
        _isLoading = false;
      });
      
      // マーカーを更新
      _updateMarkerPositions();
      
    } catch (e) {
      // print('データ取得エラー: $e');
      // エラー時はモックデータを生成
      _generateMockData();
    }
  }
  
  // モックデータを生成
  void _generateMockData() {
    // print('モックデータを生成します');
    List<ShopWithPrice> mockShops = [];
    
    for (int i = 1; i <= 10; i++) {
      final shop = Shop(
        id: 'shop_$i',
        name: 'Shop $i',
        address: 'Tokyo, Japan',
        lat: 35.681236 + (i * 0.001),
        lng: 139.767125 + (i * 0.001),
        imageUrl: '',
      );
      
      final drinkShopLink = DrinkShopLink(
        id: 'link_$i',
        drinkId: widget.drinkId ?? 'drink_1',
        shopId: shop.id,
        price: 500 + (i * 50),
        isAvailable: true,
      );
      
      mockShops.add(ShopWithPrice(shop: shop, drinkShopLink: drinkShopLink));
    }
    
    setState(() {
      _shopsWithPrice = mockShops;
      _isLoading = false;
    });
    
    // マーカーを更新
    _updateMarkerPositions();
  }
  
  void _onScrollChanged() {
    if (_isProgrammaticScrolling || _isSnapping) {
      return;
    }
    _isUserScrolling = true;
    _lastScrollTime = DateTime.now();
    _lastScrollPosition = _scrollController.offset;
    _isScrolling = true;
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isScrolling && _isUserScrolling && DateTime.now().difference(_lastScrollTime).inMilliseconds >= 250) {
        _isScrolling = false;
        _isUserScrolling = false;
        _snapToNearestCard();
      }
    });
  }

  void _onScrollEnd() {
    if (_isProgrammaticScrolling || _isSnapping) return;
    
    if (_scrollController.hasClients && _shopsWithPrice.isNotEmpty) {
      final double itemWidth = 146.0;
      final int currentIndex = (_scrollController.offset / itemWidth).round();
      
      if (currentIndex >= 0 && currentIndex < _shopsWithPrice.length) {
        final ShopWithPrice shop = _shopsWithPrice[currentIndex];
        if (_selectedShop?.shop.id != shop.shop.id) {
          setState(() {
            _selectedShop = shop;
          });
          
          _mapController.future.then((controller) {
            controller.animateCamera(
              CameraUpdate.newLatLng(LatLng(shop.shop.lat, shop.shop.lng)),
            );
          });
        }
      }
    }
  }

  void _scrollToShopCard(ShopWithPrice shop) {
    if (!_scrollController.hasClients) {
      // print('スクロールコントローラーが準備できていないため、リトライをスケジュール');
      _scrollRetryCount++;
      if (_scrollRetryCount < 5) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToShopCard(shop);
        });
      }
      return;
    }
    
    _scrollRetryCount = 0;
    
    final int index = _shopsWithPrice.indexWhere((s) => s.shop.id == shop.shop.id);
    if (index == -1) {
      // print('指定されたショップが見つかりません: ${shop.shop.id}');
      return;
    }
    
    // print('ショップカードへスクロール: インデックス=$index, ショップID=${shop.shop.id}');
    
    final double cardWidth = 146.0; // カード幅（itemExtent値と同じにする）
    final double targetPosition = index * cardWidth;
    
    _isProgrammaticScrolling = true;
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      _isProgrammaticScrolling = false;
      // print('ショップカードへのスクロール完了: インデックス=$index');
    });
  }
  
  // 最も近いカードにスナップする
  void _snapToNearestCard() {
    if (!_scrollController.hasClients || _shopsWithPrice.isEmpty) return;
    
    _isSnapping = true;
    final double cardWidth = 146.0;
    final double currentPosition = _scrollController.offset;
    final int nearestIndex = (currentPosition / cardWidth).round();
    final int clampedIndex = nearestIndex.clamp(0, _shopsWithPrice.length - 1);
    final double targetPosition = clampedIndex * cardWidth;
    
    _isProgrammaticScrolling = true;
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      _isProgrammaticScrolling = false;
      _isSnapping = false;
      
      if (clampedIndex >= 0 && clampedIndex < _shopsWithPrice.length) {
        _updateSelectedShop(_shopsWithPrice[clampedIndex]);
        _animateToShop(_shopsWithPrice[clampedIndex]);
      }
    });
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
    Set<Marker> markers = {};
    
    for (int i = 0; i < _shopsWithPrice.length; i++) {
      final shop = _shopsWithPrice[i].shop;
      final price = _shopsWithPrice[i].drinkShopLink.price;
      
      // カスタムマーカーを生成
      final BitmapDescriptor markerIcon = await CustomMarkerGenerator.createPriceMarker(
        price: price,
        isSelected: _selectedShop?.shop.id == shop.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('お店を探す'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
                _updateMarkerPositions();
              },
              onCameraMove: (_) {},
              onCameraIdle: () => _updateMarkerPositions(),
            ),
          ),
          
          // 店舗カードをページビューで表示（スワイプ可能）
          if (_shopsWithPrice.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 190,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _shopsWithPrice.length,
                  onPageChanged: (index) {
                    // ページが変わったら選択店舗を更新
                    if (index >= 0 && index < _shopsWithPrice.length) {
                      _updateSelectedShop(_shopsWithPrice[index]);
                      _animateToShop(_shopsWithPrice[index]);
                    }
                  },
                  itemBuilder: (context, index) {
                    final shopWithPrice = _shopsWithPrice[index];
                    return GestureDetector(
                      onTap: () => _navigateToShopDetail(shopWithPrice),
                      child: ShopCardWidget(
                        shopWithPrice: shopWithPrice,
                      ),
                    );
                  },
                ),
              ),
            ),
            
          // ローディング表示
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          // データが空の場合
          if (!_isLoading && _shopsWithPrice.isEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'お店が見つかりませんでした',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _generateMockData,
                        child: const Text('モックデータを表示'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
