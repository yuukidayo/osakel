import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/shop.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  final int price;

  const ShopDetailScreen({
    super.key,
    required this.shop,
    required this.price,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 現段階ではコメント読み込みは行わない
  }

  void _openGoogleMaps() async {
    final String urlString = 'https://www.google.com/maps/search/?api=1&query=${widget.shop.lat},${widget.shop.lng}';
    final Uri mapUri = Uri.parse(urlString);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('マップアプリを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // カスタムAppBar（画像付き）
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.shop.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Hero(
                tag: 'shop-image-${widget.shop.id}',
                child: Image.network(
                  widget.shop.imageUrl ?? 'https://via.placeholder.com/400x250?text=No+Image',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // シェア機能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('シェア機能は準備中です')),
                  );
                },
              ),
            ],
          ),

          // 店舗情報
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 価格表示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '¥${widget.price}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 店舗情報
                  const Text(
                    '店舗情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 住所
                  _buildInfoRow(Icons.location_on, widget.shop.address),
                  
                  // 位置情報
                  _buildInfoRow(Icons.place, '${widget.shop.lat}, ${widget.shop.lng}'),
                  
                  const SizedBox(height: 16),
                  
                  // Google Mapsボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map),
                      label: const Text('Google Mapsで見る'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // コメントセクション
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'コメント',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // コメント一覧画面へ
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('コメント機能は準備中です')),
                          );
                        },
                        child: const Text('全て見る'),
                      ),
                    ],
                  ),
                  
                  // コメントがない場合の表示
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text('まだコメントがありません'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // コメント一覧は現段階では表示しない
          const SliverToBoxAdapter(child: SizedBox()),

          // 下部の余白
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      
      // コメント追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // コメント追加画面へ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('コメント機能は準備中です')),
          );
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // コメント表示用のメソッドは現段階では必要ないため削除

  // 日付フォーマット用のメソッドは現段階では必要ないため削除
}
