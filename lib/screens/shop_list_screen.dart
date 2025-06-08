import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';
import 'dart:developer' as developer;

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
        print('カテゴリID: ${widget.categoryId} に基づいてお店を取得します');
        
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
        
        print('取得した店舗IDの数: ${shopIds.length}');
        
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
        print('ドリンクID: ${widget.drinkId} に基づいてお店を取得します');
        
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
        print('全てのお店を取得します');
        final snapshot = await FirebaseFirestore.instance
            .collection('shops')
            .limit(20)
            .get();
            
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

      print('ショップデータを${shops.length}件取得しました');
    } catch (e) {
      print('ショップデータの取得に失敗しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // drink_shop_linksコレクションにカテゴリIDを追加するメソッド
  Future<void> _updateLinksCategoryId() async {
    setState(() {
      _isUpdating = true;
      _updatedCount = 0;
      _errorCount = 0;
    });
    
    try {
      // カテゴリIDがない場合は更新しない
      if (widget.categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カテゴリIDがありません。'))
        );
        setState(() {
          _isUpdating = false;
        });
        return;
      }
      
      final categoryId = widget.categoryId!;
      
      // 1. カテゴリIDに関連するドリンクを取得
      final drinksSnapshot = await FirebaseFirestore.instance
          .collection('drinks')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      
      // 2. 各ドリンクについて、関連するdrink_shop_linksドキュメントを更新
      for (var drinkDoc in drinksSnapshot.docs) {
        final drinkId = drinkDoc.id;
        
        // ドリンクに関連するリンクを取得
        final linksSnapshot = await FirebaseFirestore.instance
            .collection('drink_shop_links')
            .where('drinkId', isEqualTo: drinkId)
            .get();
            
        // 各リンクにカテゴリIDを追加
        for (var linkDoc in linksSnapshot.docs) {
          try {
            await FirebaseFirestore.instance
                .collection('drink_shop_links')
                .doc(linkDoc.id)
                .update({
                  'categoryId': categoryId,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
            _updatedCount++;
          } catch (e) {
            developer.log('リンク更新エラー: ${e.toString()}');
            _errorCount++;
          }
        }
      }
      
      // 更新完了後にUIに通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新完了: $_updatedCount 件のリンクを更新しました。エラー: $_errorCount 件'))
      );
    } catch (e) {
      developer.log('カテゴリID更新エラー: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 更新用ボタン
          if (widget.categoryId != null)
            IconButton(
              icon: Icon(_isUpdating ? Icons.sync : Icons.update, color: Colors.black),
              tooltip: 'カテゴリIDを更新',
              onPressed: _isUpdating ? null : _updateLinksCategoryId,
            ),
          // 店舗リスト再読み込みボタン
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadShops,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {
                  // 通知画面への遷移（未実装）
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 地図表示部分
          Container(
            height: 100,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // 地図のプレースホルダー
                  Container(
                    color: Colors.grey[300],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // 中央のマーカー
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // フィルターチップ
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // エリア選択と並び替え
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // エリア選択
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // エリア選択ダイアログ（未実装）
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 4),
                        const Text('エリア 全国'),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 並び替え
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // 並び替えダイアログ（未実装）
                    },
                    child: Row(
                      children: [
                        const Text('並び替え 標準'),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 店舗リスト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shops.isEmpty
                    ? const Center(child: Text('お店が見つかりませんでした'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: _shops.length,
                        itemBuilder: (context, index) {
                          final shop = _shops[index];
                          return _buildShopItem(shop);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(Shop shop) {
    // 画像URLを取得
    String? imageUrl = shop.imageUrl ?? shop.imageURL;
    
    return InkWell(
      onTap: () {
        // 店舗詳細画面への遷移（未実装）
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店舗名と場所
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 店舗名
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
    );
  }
}
