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
        
        return Column(
          children: [
            if (isDebugMode) buildDebugPanel(docs.length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => DrinkItem(document: docs[i], categories: categories),
              ),
            ),
          ],
        );
      },
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
