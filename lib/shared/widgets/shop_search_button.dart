import 'package:flutter/material.dart';
import '../../../models/drink.dart';

/// お店検索ボタンコンポーネント
class ShopSearchButton extends StatelessWidget {
  final Drink drink;
  final VoidCallback? onTap;

  const ShopSearchButton({
    super.key,
    required this.drink,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: Stack(
          children: [
            // 背景画像
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/map_background.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                  );
                },
              ),
            ),
            // 半透明のオーバーレイ
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            // ボタン
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTap ?? () => _defaultOnTap(context),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '飲めるお店を探す',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _defaultOnTap(BuildContext context) {
    debugPrint('🍺 ShopSearchButton: タップされました - drinkId: ${drink.id}');
    
    try {
      Navigator.of(context).pushNamed(
        '/map',
        arguments: {'drinkId': drink.id},
      );
      debugPrint('🍺 ShopSearchButton: ナビゲート完了');
    } catch (e) {
      debugPrint('❌ ShopSearchButton: ナビゲートエラー - $e');
    }
  }
}
