import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';
import 'dart:developer' as developer;
import 'store_detail_screen.dart';

class ShopListScreen extends StatefulWidget {
  final String? categoryId;
  final String? drinkId;
  final String title;

  const ShopListScreen({
    Key? key,
    this.categoryId,
    this.drinkId,
    this.title = 'お店を表示',
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
      
      // カテゴリIDがあれば、drink_shop_linksコレクションからカテゴリIDに関連する店舗を取得
      if (widget.categoryId != null) {
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
      // どちらもなければ、全ての店舗を取得
      else {
        developer.log('全てのお店を取得します');
        
        final snapshot = await FirebaseFirestore.instance.collection('shops').get();
        for (var doc in snapshot.docs) {
          final shop = Shop.fromFirestore(doc);
          shops.add(shop);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // デバッグ用のボタン（drink_shop_linksコレクションにカテゴリIDを追加するボタン）
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _updateLinksCategoryId,
            tooltip: 'カテゴリIDを更新',
          ),
          // フィルターボタン
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            itemBuilder: (context) {
              return _filters.map((filter) {
                return PopupMenuItem<String>(
                  value: filter,
                  child: Row(
                    children: [
                      _selectedFilter == filter
                          ? const Icon(Icons.check, color: Colors.blue)
                          : const SizedBox(width: 24),
                      const SizedBox(width: 8),
                      Text(filter),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_mall_directory, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('お店が見つかりませんでした'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadShops,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    final shop = _shops[index];
                    return _buildShopItem(shop);
                  },
                ),
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
            
            // 店舗画像グリッド
            SizedBox(
              height: 200,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: List.generate(
                  6,
                  (i) => ClipRRect(
                    borderRadius: i == 0
                        ? const BorderRadius.only(topLeft: Radius.circular(8))
                        : i == 2
                            ? const BorderRadius.only(topRight: Radius.circular(8))
                            : i == 3
                                ? const BorderRadius.only(bottomLeft: Radius.circular(8))
                                : i == 5
                                    ? const BorderRadius.only(bottomRight: Radius.circular(8))
                                    : BorderRadius.zero,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
              ),
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
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.address} ${shop.distance != null ? '${shop.distance}m' : ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 営業時間
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
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
            
            // 区切り線
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }
}
