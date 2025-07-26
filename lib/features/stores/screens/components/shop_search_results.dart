import 'package:flutter/material.dart';
import '../../../../models/shop_with_price.dart';
import '../../../../shared/widgets/modern_bar_card_widget.dart';

/// お店検索結果表示ウィジェット（モダンデザイン対応）
class ShopSearchResults extends StatelessWidget {
  final List<ShopWithPrice> shopsWithPrices;
  final bool isLoading;
  final bool isSearching;
  final String searchError;
  final VoidCallback onRetry;
  final Function(ShopWithPrice) onShopTap;

  const ShopSearchResults({
    super.key,
    required this.shopsWithPrices,
    required this.isLoading,
    required this.isSearching,
    required this.searchError,
    required this.onRetry,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    // ローディング中
    if (isLoading || isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('検索中...'),
          ],
        ),
      );
    }

    // エラー表示
    if (searchError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              searchError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    // お店一覧表示（モダンデザイン）
    if (shopsWithPrices.isNotEmpty) {
      return Column(
        children: [
          // 検索結果ヘッダー（モダンスタイル）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_bar_outlined,
                    color: Color(0xFF1A1A1A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${shopsWithPrices.length}件のバーが見つかりました',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          
          // バーリスト（モダンカードデザイン）
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA), // 背景色を少し変更
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: shopsWithPrices.length,
                itemBuilder: (context, index) {
                  final shopWithPrice = shopsWithPrices[index];
                  return ModernBarCardWidget(
                    shopWithPrice: shopWithPrice,
                    onTap: () => onShopTap(shopWithPrice),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // 初期表示（検索結果が空の時）
    return Container(
      color: const Color(0xFFFAFAFA),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_bar_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              'バーが見つかりません',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '上のカテゴリボタンで\n別のカテゴリを選択してみてください',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
