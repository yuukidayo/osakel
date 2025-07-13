import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DrinkItem extends StatelessWidget {
  final QueryDocumentSnapshot document;
  final List<Map<String, dynamic>> categories;
  
  const DrinkItem({
    Key? key,
    required this.document,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> d = document.data() as Map<String, dynamic>;
    
    // カテゴリ名の取得
    String categoryName;
    try {
      final cat = categories.firstWhere((c) => c['id'] == d['category']);
      categoryName = cat['name'];
    } catch (_) {
      categoryName = d['category'];
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/drink_detail', arguments: {'drinkId': document.id});
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategoryLabel(categoryName),
                        _buildSubcategoryLabel(d['type'] ?? ''),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF333333)), // ダークグレーアイコン
                        const SizedBox(width: 4),
                        Text(_formatPriceRange(d['minPrice'] ?? 0, d['maxPrice'] ?? 0)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
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

  Widget _buildCategoryLabel(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(4)), // 薄いグレー背景
    child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))), // ダークグレーテキスト
  );

  Widget _buildSubcategoryLabel(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(4)), // やや濃いめのグレー背景
      child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))), // ダークグレーテキスト
    );
  }

  String _formatPriceRange(int min, int max) {
    if (min == 0 && max == 0) return '価格情報なし';
    if (min == max) return '¥$min';
    return '¥$min ~ ¥$max';
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
