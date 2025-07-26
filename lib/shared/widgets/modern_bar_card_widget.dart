import 'package:flutter/material.dart';
import '../../models/shop_with_price.dart';

/// モダンなバー検索画面用のショップカードウィジェット
/// デザイン要求に基づいた洗練されたレイアウト
class ModernBarCardWidget extends StatelessWidget {
  final ShopWithPrice shopWithPrice;
  final VoidCallback? onTap;

  const ModernBarCardWidget({
    super.key,
    required this.shopWithPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shop = shopWithPrice.shop;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ショップ名（大きく、太字、エレガント）
              Text(
                shop.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // カテゴリ・都市ラベル
              Row(
                children: [
                  Icon(
                    Icons.local_bar_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${shop.category ?? 'バー'} · 札幌市',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 6枚の写真グリッド（2行3列）
              _buildImageGrid(shop.imageUrls),
              const SizedBox(height: 20),
              
              // 駅距離、価格、営業時間
              Column(
                children: [
                  // 駅距離
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    text: '最寄駅 表参道駅 298m',
                    color: Colors.grey[700]!,
                  ),
                  const SizedBox(height: 12),
                  
                  // 価格と営業時間を横並び
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 価格
                      Row(
                        children: [
                          Text(
                            '¥${shopWithPrice.drinkShopLink.price.toInt()}-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      
                      // 営業時間
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '営業開始 ${shop.openTime ?? '17:00'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 情報行を構築するヘルパーメソッド
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  /// 6枚の写真グリッドを構築
  Widget _buildImageGrid(List<String>? imageUrls) {
    // 画像URLリストを6枚に調整（足りない場合はプレースホルダー）
    final List<String?> displayImages = List.generate(6, (index) {
      if (imageUrls != null && index < imageUrls.length) {
        return imageUrls[index];
      }
      return null;
    });

    return SizedBox(
      height: 200, // 2行の高さ
      child: Column(
        children: [
          // 1行目（3枚）
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: _buildImageTile(displayImages[i], isFirst: i == 0),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // 2行目（3枚）
          Expanded(
            child: Row(
              children: [
                for (int i = 3; i < 6; i++) ...[
                  Expanded(
                    child: _buildImageTile(displayImages[i], isFirst: false),
                  ),
                  if (i < 5) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 個別の画像タイルを構築
  Widget _buildImageTile(String? imageUrl, {required bool isFirst}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingPlaceholder();
              },
            )
          : _buildPlaceholderImage(),
      ),
    );
  }

  /// プレースホルダー画像
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// ローディングプレースホルダー
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
}