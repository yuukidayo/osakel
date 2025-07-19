import 'package:flutter/material.dart';
import '../../../../models/shop.dart';
import 'shop_card.dart';

/// お店検索結果表示ウィジェット
class ShopSearchResults extends StatelessWidget {
  final List<Shop> shops;
  final bool isLoading;
  final bool isSearching;
  final String searchError;
  final VoidCallback onRetry;
  final Function(Shop) onShopTap;

  const ShopSearchResults({
    Key? key,
    required this.shops,
    required this.isLoading,
    required this.isSearching,
    required this.searchError,
    required this.onRetry,
    required this.onShopTap,
  }) : super(key: key);

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

    // お店一覧表示
    if (shops.isNotEmpty) {
      return Column(
        children: [
          // 検索結果ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.store, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${shops.length}件のお店が見つかりました',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // お店リスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return ShopCard(
                  shop: shop,
                  onTap: () => onShopTap(shop),
                );
              },
            ),
          ),
        ],
      );
    }

    // 初期表示（検索結果が空の時）
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'お店が見つかりません',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '上のカテゴリボタンで\n別のカテゴリを選択してみてください',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
