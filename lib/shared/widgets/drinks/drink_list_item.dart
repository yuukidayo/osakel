import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 検索結果の各ドリンクアイテムを表示するウィジェット
class DrinkListItem extends StatelessWidget {
  final QueryDocumentSnapshot document;
  final VoidCallback? onFavoritePressed;

  const DrinkListItem({
    super.key,
    required this.document,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    final data = document.data() as Map<String, dynamic>;
    
    // カテゴリ名の取得
    String categoryName = '';
    if (data.containsKey('categoryId') && data['categoryId'] != null) {
      try {
        categoryName = data['categoryName'] ?? '不明';
      } catch (e) {
        categoryName = '不明';
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFEEEEEE)), // 薄いグレーの枠線
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrinkImage(data),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildCategoryLabel(categoryName),
                      _buildSubcategoryLabel(data['type'] ?? ''),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF333333)), // ダークグレーアイコン
                      const SizedBox(width: 4),
                      Text(_formatPriceRange(data['minPrice'] ?? 0, data['maxPrice'] ?? 0)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.black),
              onPressed: onFavoritePressed,
            ),
          ],
        ),
      ),
    );
  }

  /// ドリンク画像を表示するウィジェット
  Widget _buildDrinkImage(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'];
    final bool isValidImage = _isValidImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: isValidImage
          ? CachedNetworkImage(
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              imageUrl: imageUrl,
              placeholder: (_, __) => const SizedBox(
                width: 80,
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  /// 画像プレースホルダーを生成
  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFF5F5F5), // 薄いグレー背景
      child: const Icon(Icons.local_bar, color: Color(0xFF8A8A8A)), // グレーアイコン
    );
  }

  /// カテゴリラベルウィジェットを生成
  Widget _buildCategoryLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // 薄いグレー背景
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF333333)), // ダークグレーテキスト
      ),
    );
  }

  /// サブカテゴリラベルウィジェットを生成
  Widget _buildSubcategoryLabel(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE), // やや濃いめのグレー背景
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF333333)), // ダークグレーテキスト
      ),
    );
  }

  /// 価格範囲をフォーマット
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
    
    // 例として無効なURLのパターンをチェック
    if (url == 'https://example.com/ipa.jpg') return false;
    
    return true;
  }
}
