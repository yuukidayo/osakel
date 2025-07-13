import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'drink_item.dart';

class SearchResultsList extends StatelessWidget {
  final Stream<QuerySnapshot>? searchSnapshot;
  final bool hasError;
  final bool isDebugMode;
  final Widget Function(int docsLength) buildDebugPanel;
  final List<Map<String, dynamic>> categories;

  const SearchResultsList({
    Key? key,
    required this.searchSnapshot,
    this.hasError = false,
    this.isDebugMode = false,
    required this.buildDebugPanel,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (searchSnapshot == null) {
      if (hasError) {
        return _buildErrorWidget();
      }
      return const Center(
        child: Text('検索条件を選択してください', style: TextStyle(fontSize: 16)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: searchSnapshot,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text('エラーが発生しました: ${snap.error}',
                style: const TextStyle(color: Color(0xFF000000))), // 黒色テキスト
          );
        }

        final docs = snap.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Color(0xFF8A8A8A)), // グレーアイコン
                const SizedBox(height: 16),
                const Text('検索結果が見つかりません',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('検索条件を変更してお試しください',
                    style: const TextStyle(color: Color(0xFF8A8A8A))), // グレーテキスト
                if (isDebugMode) buildDebugPanel(docs.length),
              ],
            ),
          );
        }
        
        // PRアイテム（最大3つ）と通常アイテムに分割
        final prItems = docs.take(3).toList(); // 先頭3つをPRアイテムとして扱う
        final regularItems = docs.skip(3).toList(); // 残りを通常アイテムとして扱う
        
        return Column(
          children: [
            if (isDebugMode) buildDebugPanel(docs.length),
            
            // PR商品セクション（横3列）
            if (prItems.isNotEmpty) _buildPrSection(context, prItems),
            
            // 通常商品リスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: regularItems.length,
                itemBuilder: (_, i) => DrinkItem(
                  document: regularItems[i], 
                  categories: categories,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// PRセクションの構築（3列固定グリッド - スクロールなし）
  Widget _buildPrSection(BuildContext context, List<QueryDocumentSnapshot> prItems) {
    // 最大3つのアイテムに制限
    final limitedPrItems = prItems.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRアイテムの3列固定グリッド - 常に均等配置にする
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              // 常にspaceEvenlyで均等配置
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < limitedPrItems.length; i++)
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 32) / 3.5, // 画面幅に基づいて適切なサイズを設定
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/drink_detail', arguments: {'drinkId': limitedPrItems[i].id});
                        },
                        child: DrinkItem(
                          document: limitedPrItems[i], 
                          categories: categories, 
                          isPr: true,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('検索中にエラーが発生しました',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('検索条件を変更して再試行してください',
              style: TextStyle(color: Color(0xFF8A8A8A))),
        ],
      ),
    );
  }
}
