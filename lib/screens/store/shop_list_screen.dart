import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;

import '../../models/shop.dart';
import 'store_detail_screen.dart' show StoreDetailScreen;
import '../drinks/drink_search_screen.dart';

class ShopListScreen extends StatefulWidget {
  final String? categoryId;
  final String? drinkId;
  final String title;
  
  /// お酒検索画面への切り替えコールバック
  final VoidCallback? onSwitchToDrinkSearch;

  const ShopListScreen({
    Key? key,
    this.categoryId,
    this.drinkId,
    this.title = 'お店を表示',
    this.onSwitchToDrinkSearch,
  }) : super(key: key);

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final List<Shop> _shops = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String _selectedFilter = 'バー';
  final List<String> _filters = ['バー', 'ひとり歓迎', '試飲可', '静か'];
  int _updatedCount = 0;
  int _errorCount = 0;
  
  // お酒/お店切替用の状態変数
  // トグルモード管理用フラグ（将来的に使用予定）
  // bool _isCurrentlyShopMode = true; // true: お店検索モード, false: お酒検索モード

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Shop> shops = [];
      
      // タブ切り替えで表示した場合（カテゴリID、ドリンクIDなし）
      if (widget.categoryId == null && widget.drinkId == null) {
        // デフォルトで全ての店舗を取得
        developer.log('すべてのお店を取得します');
        
        final shopsSnapshot = await FirebaseFirestore.instance
            .collection('shops')
            .limit(20) // 最初は20件に制限
            .get();
            
        for (var doc in shopsSnapshot.docs) {
          final shop = Shop.fromFirestore(doc);
          shops.add(shop);
        }
      }
      // カテゴリIDがあれば、drink_shop_linksコレクションからカテゴリIDに関連する店舗を取得
      else if (widget.categoryId != null) {
        developer.log('カテゴリID: ${widget.categoryId} に基づいてお店を取得します');
        
        // 1. まず、カテゴリIDに関連するドリンクを取得
        final drinksSnapshot = await FirebaseFirestore.instance
            .collection('drinks')
            .where('categoryId', isEqualTo: widget.categoryId)
            .get();
            
        // 2. 取得したドリンクのIDを使ってdrink_shop_linksから関連する店舗IDを取得
        Set<String> shopIds = {}; // 重複を避けるためにSetを使用
        
        for (var drinkDoc in drinksSnapshot.docs) {
          final drinkId = drinkDoc.id;
          
          final linksSnapshot = await FirebaseFirestore.instance
              .collection('drink_shop_links')
              .where('drinkId', isEqualTo: drinkId)
              .get();
              
          for (var linkDoc in linksSnapshot.docs) {
            final data = linkDoc.data();
            if (data.containsKey('shopId')) {
              shopIds.add(data['shopId']);
            }
          }
        }
        
        developer.log('取得した店舗IDの数: ${shopIds.length}');
        
        // 3. 店舗IDを使ってshopsコレクションから店舗データを取得
        for (String shopId in shopIds) {
          final shopDoc = await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .get();
              
          if (shopDoc.exists) {
            final shop = Shop.fromFirestore(shopDoc);
            shops.add(shop);
          }
        }
      } 
      // ドリンクIDがあれば、そのドリンクを提供している店舗を取得
      else if (widget.drinkId != null) {
        developer.log('ドリンクID: ${widget.drinkId} に基づいてお店を取得します');
        
        // drink_shop_linksからドリンクIDに関連する店舗を取得
        final linksSnapshot = await FirebaseFirestore.instance
            .collection('drink_shop_links')
            .where('drinkId', isEqualTo: widget.drinkId)
            .get();
            
        Set<String> shopIds = {};
        for (var doc in linksSnapshot.docs) {
          final data = doc.data();
          if (data.containsKey('shopId')) {
            shopIds.add(data['shopId']);
          }
        }
        
        // 店舗IDを使ってshopsコレクションから店舗データを取得
        for (String shopId in shopIds) {
          final shopDoc = await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .get();
              
          if (shopDoc.exists) {
            final shop = Shop.fromFirestore(shopDoc);
            shops.add(shop);
          }
        }
      }
      
      setState(() {
        _shops.clear();
        _shops.addAll(shops);
        _isLoading = false;
      });
      
      developer.log('お店の数: ${_shops.length}');
    } catch (e) {
      developer.log('お店の取得エラー: $e');
      setState(() {
        _isLoading = false;
      });
      
      // エラーメッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('お店の取得に失敗しました: $e'))
        );
      }
    }
  }

  // drink_shop_linksコレクションにカテゴリIDを追加するメソッド
  Future<void> _updateLinksCategoryId() async {
    if (_isUpdating) {
      developer.log('すでに更新中のため、処理をスキップします。');
      return;
    }
    
    setState(() {
      _isUpdating = true;
      _updatedCount = 0;
      _errorCount = 0;
    });
    
    try {
      // 1. まず、すべてのドリンクを取得
      final drinksSnapshot = await FirebaseFirestore.instance
          .collection('drinks')
          .get();
          
      // ドキュメントIDとカテゴリIDのマップを作成
      Map<String, String> drinkCategoryMap = {};
      for (var doc in drinksSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('categoryId')) {
          drinkCategoryMap[doc.id] = data['categoryId'];
        }
      }
      
      // 2. すべてのリンクを取得
      final linksSnapshot = await FirebaseFirestore.instance
          .collection('drink_shop_links')
          .get();
          
      // 各リンクにカテゴリIDを追加
      for (var doc in linksSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('drinkId')) {
          final drinkId = data['drinkId'];
          if (drinkCategoryMap.containsKey(drinkId)) {
            final categoryId = drinkCategoryMap[drinkId];
            
            // カテゴリIDがすでに設定されているか確認
            if (!data.containsKey('categoryId') || data['categoryId'] != categoryId) {
              try {
                await FirebaseFirestore.instance
                    .collection('drink_shop_links')
                    .doc(doc.id)
                    .update({'categoryId': categoryId});
                _updatedCount++;
              } catch (e) {
                developer.log('リンク更新エラー: ${e.toString()}');
                _errorCount++;
              }
            }
          }
        }
      }
      
      setState(() {
        _isUpdating = false;
      });
      
      // 完了メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新完了: $_updatedCount 件のリンクを更新しました。エラー: $_errorCount 件'))
      );
    } catch (e) {
      developer.log('カテゴリID更新エラー: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: ${e.toString()}'))
      );
      
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // お酒検索画面に切り替えるメソッド
  void _navigateToDrinkSearch() {
    // IndexedStackによる切り替えが設定されている場合はそれを使用
    if (widget.onSwitchToDrinkSearch != null) {
      widget.onSwitchToDrinkSearch!();
      return;
    }
    
    // 従来のナビゲーション方法（後方互換性のため残す）
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DrinkSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // お酒検索画面と同じトップバーの実装
  Widget _buildCategoryTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 左側のプロフィールアイコン
          GestureDetector(
            onTap: () {
              // サイドメニューを表示
              showSideMenu(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // 薄いグレー背景
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: const Color(0xFF8A8A8A)), // グレーアイコン
            ),
          ),
          
          // 中央のタイトル
          Expanded(
            child: Center(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 右側のお酒検索への切り替えアイコン
          GestureDetector(
            onTap: _navigateToDrinkSearch,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA), // 非常に薄いグレー背景
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDDDDD)), // 薄いグレー枠線
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.local_drink,
                    size: 20,
                    color: const Color(0xFF333333), // ダークグレー
                  ),
                  // 左下に青い丸と左矢印を表示
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: const Color(0xFF000000), // 黒色背景
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 10,
                        color: const Color(0xFFFFFFFF), // 白色アイコン
                      ),
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

  // サイドメニューを表示するメソッド
  void showSideMenu(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 純白背景(#FFFFFF)に統一
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'メニュー',
                style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: 24), // 白色テキスト
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('ホーム'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('プロフィール'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('設定'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // カスタムトップバー
            _buildCategoryTopBar(),
            // フィルターリスト
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 40,
              child: Row(
                children: [
                  const Text('フィルター:', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  // フィルターボタン
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _filters.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (isSelected) {
                                if (isSelected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                  // フィルター適用時に店舗を再読み込み
                                  _loadShops();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // デバッグ用の更新ボタン
                  IconButton(
                    icon: const Icon(Icons.sync, size: 20),
                    onPressed: _updateLinksCategoryId,
                    tooltip: 'カテゴリIDを更新',
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // 店舗一覧
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shops.isEmpty
                  ? const Center(child: Text('該当するお店がありません'))
                  : ListView.builder(
                      itemCount: _shops.length,
                      itemBuilder: (context, index) => _buildShopItem(_shops[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.categoryId != null
          ? FloatingActionButton(
              onPressed: _updateLinksCategoryId,
              child: const Icon(Icons.update),
            )
          : null,
    );
  }

  Widget _buildShopItem(Shop shop) {
    // 画像URLを取得
    String? imageUrl = shop.imageUrl ?? shop.imageURL;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(storeId: shop.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗名と場所
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 店舗タイプと場所
                  Row(
                    children: [
                      const Text(
                        'バー・',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        shop.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 店舗画像
            if (imageUrl != null && imageUrl.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: const Color(0xFFEEEEEE), // 薄いグレープレースホルダー
                child: const Icon(Icons.image, color: Color(0xFF8A8A8A), size: 50), // グレーアイコン
              ),
            
            // 店舗情報（住所、料金、営業時間）
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 住所と距離
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF8A8A8A)), // グレー位置アイコン
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${shop.address} ${shop.distance != null ? '${shop.distance}m' : ''}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 営業時間
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Color(0xFF8A8A8A)), // グレー時間アイコン
                      const SizedBox(width: 4),
                      Text(
                        '営業開始 ${shop.openTime ?? '17:00'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
