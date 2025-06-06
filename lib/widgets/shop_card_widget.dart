import 'package:flutter/material.dart';
import 'package:store_map_app/models/shop_with_price.dart';

class ShopCardWidget extends StatelessWidget {
  final ShopWithPrice shopWithPrice;

  const ShopCardWidget({
    Key? key,
    required this.shopWithPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shop = shopWithPrice.shop;
    
    String? imageUrl;
    if (shop.imageURL != null && shop.imageURL!.isNotEmpty) {
      imageUrl = shop.imageURL;
    } else if (shop.imageUrl != null && shop.imageUrl!.isNotEmpty) {
      imageUrl = shop.imageUrl;
    }
    
    // 店舗情報の取得
    
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗画像
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 150,
                    height: 84, // 16:9のアスペクト比
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 150,
                        height: 84,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 150,
                    height: 84,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  ),
            ),
            const SizedBox(width: 12),

            // 右側情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 店名＋青ドット
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // グラスと価格
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'グラス',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${shopWithPrice.drinkShopLink.price.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // ノミタイの数
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ノミタイの数: ${shopWithPrice.drinkShopLink.note != null ? '10' : '5'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // お店の雰囲気（タグデザイン）
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          shop.category ?? 'カジュアル',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '静か',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 営業時間
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.openTime ?? '17:00 - 24:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // ボタンを削除しました
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
