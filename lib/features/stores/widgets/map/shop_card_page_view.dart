import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/shop_with_price.dart';

/// 店舗カードページビューコンポーネント（モノトーン版）
/// 
/// マップ下部に表示される店舗カードのスライダー
class ShopCardPageView extends StatelessWidget {
  final List<ShopWithPrice> shops;
  final PageController controller;
  final Function(int) onPageChanged;
  final Function(ShopWithPrice) onShopTap;

  const ShopCardPageView({
    Key? key,
    required this.shops,
    required this.controller,
    required this.onPageChanged,
    required this.onShopTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const SizedBox.shrink();
    }

    return PageView.builder(
      controller: controller,
      itemCount: shops.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final shopWithPrice = shops[index];
        return GestureDetector(
          onTap: () => onShopTap(shopWithPrice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA), // オフホワイト背景
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 左側: 店舗画像
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFE2E8F0), // ライトグレー
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildShopImage(shopWithPrice.shop.imageUrls),
                    ),
                  ),
                  
                  // 右側: 店舗情報
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 上部: 店舗名
                          Text(
                            shopWithPrice.shop.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A202C), // ダークグレー
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // 中部: 料金
                          Text(
                            '¥${NumberFormat('#,###').format(shopWithPrice.drinkShopLink.price.toInt())}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748), // 強調ダークグレー
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // 下部: カテゴリと営業時間
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // カテゴリバッジ
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0), // ライトグレー背景
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getCategoryText(shopWithPrice.shop.category),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4A5568), // ミディアムグレー
                                  ),
                                ),
                              ),
                              
                              // 営業時間
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getBusinessHours(shopWithPrice.shop),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4A5568), // ミディアムグレー
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  /// 店舗画像を構築（imageUrls配列から最初の画像を使用）
  Widget _buildShopImage(List<String> imageUrls) {
    // 配列から最初の有効な画像URLを取得
    String? imageUrl = _getFirstValidImageUrl(imageUrls);
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderImage();
        },
      );
    }
    return _buildPlaceholderImage();
  }
  
  /// imageUrls配列から最初の有効な画像URLを取得するヘルパーメソッド
  String? _getFirstValidImageUrl(List<String> imageUrls) {
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    return null;
  }

  /// プレースホルダー画像を構築
  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.store,
        size: 40,
        color: Color(0xFF9CA3AF), // グレーアイコン
      ),
    );
  }

  /// カテゴリテキストを取得
  String _getCategoryText(String? category) {
    if (category == null || category.isEmpty) {
      return 'Bar'; // デフォルト
    }
    
    // カテゴリの正規化
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('bar') || lowerCategory.contains('バー')) {
      return 'Bar';
    } else if (lowerCategory.contains('shop') || 
               lowerCategory.contains('store') || 
               lowerCategory.contains('販売')) {
      return '販売店';
    }
    
    return category; // そのまま返す
  }

  /// 営業時間を取得
  String _getBusinessHours(shop) {
    // 営業開始時刻を取得（closeTimeプロパティが存在しないため、openTimeのみ表示）
    final openTime = shop.openTime ?? '18:00';
    
    return '${openTime}〜'; // 開始時刻のみ表示
  }
}
