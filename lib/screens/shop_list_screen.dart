import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';

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
  String _selectedFilter = 'バー';
  final List<String> _filters = ['バー', 'ひとり歓迎', '試飲可', '静か'];

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
      // Firestoreからショップデータを取得
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('shops')
          .limit(20)
          .get();

      List<Shop> shops = [];
      for (var doc in snapshot.docs) {
        final shop = Shop.fromFirestore(doc);
        shops.add(shop);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                // 料金
                Row(
                  children: [
                    Text(
                      '¥ ${shop.price != null ? shop.price : 3200}-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
