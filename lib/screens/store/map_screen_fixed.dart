import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:osakel/models/shop.dart';
import 'package:osakel/models/shop_with_price.dart';
import 'package:osakel/models/drink_shop_link.dart';
import 'shop_detail_screen.dart';
import 'package:osakel/services/firestore_service.dart';
import 'package:osakel/utils/custom_marker_generator.dart';

class MapScreen extends StatefulWidget {
  final String? drinkId;

  const MapScreen({Key? key, this.drinkId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final Completer<GoogleMapController> _mapController = Completer();
  final ScrollController _scrollController = ScrollController();
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
      
      // 初回フォーカス処理
      await _performInitialFocus();
      
      // マーカーを更新
      _updateMarkerPositions();
      
    } catch (e) {
      // print('データ取得エラー: $e');
      // エラー時はモックデータを生成
      _generateMockData();
    }
  }
  
  // 初回フォーカス処理
  Future<void> _performInitialFocus() async {
    if (_shopsWithPrice.isNotEmpty && !_isInitialFocusComplete) {
      final firstShop = _shopsWithPrice.first;
      
      // 先頭店舗を選択状態にする
      setState(() {
        _selectedShop = firstShop;
        _isInitialFocusComplete = true;
      });
      
      // マップコントローラが利用可能になるまで待機
      final controller = await _mapController.future;
      
      // 先頭店舗の位置にカメラを移動
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstShop.shop.lat, firstShop.shop.lng),
            zoom: 15.0,
          ),
        ),
      );
      
      // PageViewも先頭に設定
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
  
  // モックデータを生成
  void _generateMockData() async {
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
        price: 500.0 + (i * 100),
        isAvailable: true,
        note: '',
      );
      
      mockShops.add(ShopWithPrice(shop: shop, drinkShopLink: drinkShopLink));
    }
    
    setState(() {
      _shopsWithPrice = mockShops;
      _isLoading = false;
    });
    
    // 初回フォーカス処理
    await _performInitialFocus();
    
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

  // 検索候補リスト
  final List<String> _locationSuggestions = [
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
  
  // モーダル内の検索キーワード
  String _searchQuery = '';
  
  // 表示する候補リスト
  List<String> _filteredSuggestions = [];
  
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
    
    // 検索文字列をクリアし、モーダルを閉じる
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filteredSuggestions = [];
      _isSearchModalVisible = false;
    });
    
    // デモ実装としてハードコードした位置情報を使用
    Map<String, LatLng> locationMap = {
      '東京都渋谷区': const LatLng(35.658517, 139.701334),
      '東京都新宿区': const LatLng(35.693908, 139.703645),
      '東京都江東区': const LatLng(35.669068, 139.778213),
      '東京都品川区': const LatLng(35.607286, 139.730133),
      '東京都目黒区': const LatLng(35.642908, 139.699525),
      '東京都中央区': const LatLng(35.672048, 139.772359),
      '東京都豊島区': const LatLng(35.723436, 139.715446),
      '東京都台東区': const LatLng(35.712833, 139.780515),
      '東京都文京区': const LatLng(35.720495, 139.751935),
      '東京都千代田区': const LatLng(35.694003, 139.754202),
    };
    
    if (locationMap.containsKey(location)) {
      // 地図を選択された場所に移動
      _mapController.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: locationMap[location]!,
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
      _searchQuery = '';
      _filteredSuggestions = [];
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
      _searchQuery = '';
      _searchController.clear();
      _filteredSuggestions = [];
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }
  
  // 検索キーワードに基づき候補をフィルタリング
  void _filterSuggestions(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSuggestions = [];
      } else {
        _filteredSuggestions = _locationSuggestions
            .where((location) =>
                location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Google Mapを最初に配置（一番下に表示）
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
          
          // 検索ボックスを次に配置（地図の上に表示）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 検索フィールド
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _showSearchModal,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '場所を検索（例：東京都渋谷区）',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // マップコントロール（ズームボタン、現在位置ボタン等）
          Positioned(
            right: 16,
            bottom: 236, // 店舗カードの固定高さ + マージン
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 現在位置ボタン
                FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: () async {
                    final controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  elevation: 4,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                // ズームインボタン
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () async {
                    final controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  elevation: 4,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                // ズームアウトボタン
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () async {
                    final controller = await _mapController.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  elevation: 4,
                  child: const Icon(Icons.remove),
                ),
              ],
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
                  // 店舗カードページビュー
                  Positioned(
                    bottom: 00,
                    left: 0,
                    right: 0,
                    height: 150, // カードの高さインジケーターの下に配置
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _shopsWithPrice.length,
                      onPageChanged: (index) {
                        if (index >= 0 && index < _shopsWithPrice.length) {
                          _updateSelectedShop(_shopsWithPrice[index]);
                          _animateToShop(_shopsWithPrice[index]);
                        }
                      },
                      itemBuilder: (context, index) {
                        final shopWithPrice = _shopsWithPrice[index];
                        return GestureDetector(
                          onTap: () => _navigateToShopDetail(shopWithPrice),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 画像表示部分
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                    child: shopWithPrice.shop.imageUrl != null
                                      ? Image.network(
                                          shopWithPrice.shop.imageUrl!,
                                          width: 120,
                                          height: 210,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              width: 120,
                                              height: 210,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 120,
                                              height: 210,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 120,
                                          height: 210,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // 店名と料金表示
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      shopWithPrice.shop.name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).primaryColor,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${NumberFormat('#,###').format(shopWithPrice.drinkShopLink.price.toInt())}円',
                                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // 住所
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      shopWithPrice.shop.address,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (shopWithPrice.shop.category != null) ...[
                                                const SizedBox(height: 8),
                                                // カテゴリー
                                                Row(
                                                  children: [
                                                    const Icon(Icons.store, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      shopWithPrice.shop.category!,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                          // 詳細ボタン
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => _navigateToShopDetail(shopWithPrice),
                                              child: const Text('詳細を見る'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
          
          // 全画面検索モーダル - Stackの最後に追加して一番上に表示する
          if (_isSearchModalVisible)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // モーダルヘッダー
                    Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        left: 8,
                        right: 8,
                        bottom: 8,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _hideSearchModal,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _filterSuggestions,
                              decoration: InputDecoration(
                                hintText: '場所を検索（例：東京都渋谷区）',
                                border: InputBorder.none,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _filteredSuggestions = [];
                                        });
                                      },
                                    )
                                  : null,
                              ),
                              autofocus: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 候補リスト
                    Expanded(
                      child: _filteredSuggestions.isEmpty && _searchQuery.isNotEmpty
                        ? const Center(
                            child: Text('検索結果がありません'),
                          )
                        : ListView.builder(
                            itemCount: _searchQuery.isEmpty
                              ? _locationSuggestions.length
                              : _filteredSuggestions.length,
                            itemBuilder: (context, index) {
                              final String location = _searchQuery.isEmpty
                                ? _locationSuggestions[index]
                                : _filteredSuggestions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(location),
                                onTap: () => _searchLocation(location),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
