import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/shop_with_price.dart';

/// 店舗カードページビューコンポーネント
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 画像表示部分
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: _buildShopImage(shopWithPrice.shop.imageUrl),
                  ),
                  
                  // 店舗情報部分
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 店舗名と価格
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopWithPrice.shop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${NumberFormat('#,###').format(shopWithPrice.drinkShopLink.price.toInt())}円',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // 住所
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shopWithPrice.shop.address,
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          // カテゴリー（存在する場合）
                          if (shopWithPrice.shop.category != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                shopWithPrice.shop.category!,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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

  /// 店舗画像を構築
  Widget _buildShopImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 100,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  /// プレースホルダー画像
  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Icon(
        Icons.store,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }
}
