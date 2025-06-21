import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import '../models/shop.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeId;

  const StoreDetailScreen({Key? key, required this.storeId}) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _isBookmarked = false;
  int _currentCarouselIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('shops').doc(widget.storeId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラーが発生しました: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.not_interested, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('お店情報が見つかりませんでした'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            );
          }
          
          // ドキュメントからShopを作成
          final shopData = snapshot.data!.data() as Map<String, dynamic>;
          final shop = Shop.fromMap(widget.storeId, shopData);
          
          // 画像URLリストを作成 (モックデータ。実際のデータモデルに合わせて調整)
          List<String> imageUrls = [];
          if (shop.imageUrl != null && shop.imageUrl!.isNotEmpty) {
            imageUrls.add(shop.imageUrl!);
          } else if (shop.imageURL != null && shop.imageURL!.isNotEmpty) {
            imageUrls.add(shop.imageURL!);
          }
          
          // 仮のダミー画像を追加（実際の実装では複数の画像フィールドを参照または配列フィールドを使用）
          if (imageUrls.isEmpty) {
            imageUrls = [
              'https://source.unsplash.com/random/800x600/?bar',
              'https://source.unsplash.com/random/800x600/?restaurant',
              'https://source.unsplash.com/random/800x600/?cafe',
            ];
          } else if (imageUrls.length == 1) {
            // モック用に追加の画像を加える（実際の実装では不要）
            imageUrls.add('https://source.unsplash.com/random/800x600/?bar');
            imageUrls.add('https://source.unsplash.com/random/800x600/?cafe');
          }
          
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アプリバー
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 店名とブックマークボタン
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: _isBookmarked ? Theme.of(context).primaryColor : Colors.black,
                                  size: 30,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isBookmarked = !_isBookmarked;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_isBookmarked ? 'お気に入りに追加しました' : 'お気に入りから削除しました'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // 住所
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop.address,
                                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 画像カルーセル
                        const SizedBox(height: 12),
                        carousel.CarouselSlider(
                          options: carousel.CarouselOptions(
                            height: 240,
                            viewportFraction: 1.0,
                            enlargeCenterPage: false,
                            autoPlay: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentCarouselIndex = index;
                              });
                            },
                          ),
                          items: imageUrls.map((url) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                  ),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                            );
                          }).toList(),
                        ),
                        
                        // カルーセルインジケーター
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: imageUrls.asMap().entries.map((entry) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentCarouselIndex == entry.key
                                  ? Colors.black
                                  : Colors.grey[350],
                              ),
                            );
                          }).toList(),
                        ),
                        
                        // 店舗説明
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            shopData['description'] ?? '日中からお楽しみいただけるバー&カフェ。ビビットカラーをアクセントにした空間で気軽に語らうひとときをお過ごしください。',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        
                        // 平均予算
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '平均予算：¥ ${shopData['averageBudget'] ?? '4,000'} -',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        
                        // メニューとクーポンボタン
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // メニューボタンのアクション
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('メニューを表示します')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  icon: const Icon(Icons.book),
                                  label: const Text('メニュー'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // クーポンボタンのアクション
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('クーポンを表示します')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.grey[700],
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  icon: const Icon(Icons.confirmation_number),
                                  label: const Text('クーポン'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 余白
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
