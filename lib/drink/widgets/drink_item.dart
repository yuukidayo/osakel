import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DrinkItem extends StatelessWidget {
  final QueryDocumentSnapshot document;
  final List<Map<String, dynamic>> categories;
  final bool isPr;
  
  const DrinkItem({
    super.key,
    required this.document,
    required this.categories,
    this.isPr = false,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> d = document.data() as Map<String, dynamic>;
    
    // カテゴリ情報は簡素化されたデザインでは表示しない
    
    // PR表示の場合は縮小版を表示
    if (isPr) {
      return _buildPrItem(context, d);
    }
    
    // 通常の商品表示
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/drink_detail', arguments: {'drinkId': document.id});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _isValidImageUrl(d['imageUrl']) ? d['imageUrl'] : 'https://placeholder.com/80x80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF5F5F5), // 薄いグレー背景
                    child: const Icon(Icons.local_bar, color: Color(0xFF8A8A8A)), // グレーアイコン
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_formatPriceRange(d['minPrice'] ?? 0, d['maxPrice'] ?? 0),
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (d['rating'] != null) Text('(${d['rating']})', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('お気に入り機能は準備中です')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 新デザインではカテゴリラベルを使用しない

  String _formatPriceRange(int min, int max) {
    if (min == 0 && max == 0) return '価格情報なし';
    if (min == max) return '¥$min';
    return '¥$min ~ $max';
  }

  /// PR商品表示用のウィジェット
  Widget _buildPrItem(BuildContext context, Map<String, dynamic> data) {
    // 親要素の幅に合わせて画像サイズを自動調整
    double containerWidth = 100; // 小さめのサイズに設定
    double containerHeight = 100; // 小さめのサイズに設定
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 画像表示
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: CachedNetworkImage(
            imageUrl: _isValidImageUrl(data['imageUrl']) ? data['imageUrl'] : 'https://placeholder.com/100x100',
            width: containerWidth,
            height: containerHeight,
            fit: BoxFit.cover,
            placeholder: (_, __) => SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: containerWidth,
              height: containerHeight,
              color: const Color(0xFFF5F5F5),
              child: const Icon(Icons.local_bar, size: 30, color: Color(0xFF8A8A8A)),
            ),
          ),
        ),
        
        // PRラベル - 横長長方形
        Container(
          width: containerWidth,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: const Center(
            child: Text(
              'PR',
              style: TextStyle(
                color: Colors.white, 
                fontSize: 12, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 画像URLが有効かどうかチェック
  bool _isValidImageUrl(dynamic url) {
    if (url == null) return false;
    if (url is! String) return false;
    if (url.isEmpty) return false;
    if (!url.startsWith('http')) return false;
    return true;
  }
}
