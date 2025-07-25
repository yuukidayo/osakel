import 'package:flutter/material.dart';
import '../../../models/filters/filter_option.dart';
import '../../../models/filters/drink_filter_options.dart';

/// ドリンク検索のフィルターボトムシート
/// 
/// `category` - 表示するカテゴリ（「ビール」、「ワイン」など）
/// `filterValues` - 現在のフィルター値
/// `onApplyFilters` - フィルター適用時のコールバック
/// `onClearFilters` - フィルタークリア時のコールバック
class DrinkFilterBottomSheet extends StatefulWidget {
  final String category;
  final Map<String, dynamic> filterValues;
  final Function(Map<String, dynamic>) onApplyFilters;
  final Function() onClearFilters;

  const DrinkFilterBottomSheet({
    super.key,
    required this.category,
    required this.filterValues,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  /// フィルターボトムシートを表示する便利なメソッド
  static Future<void> show({
    required BuildContext context,
    required String category,
    required Map<String, dynamic> filterValues,
    required Function(Map<String, dynamic>) onApplyFilters,
    required Function() onClearFilters,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DrinkFilterBottomSheet(
          category: category,
          filterValues: filterValues,
          onApplyFilters: onApplyFilters,
          onClearFilters: onClearFilters,
        );
      },
      barrierColor: Colors.black54,
    );
  }

  @override
  State<DrinkFilterBottomSheet> createState() => _DrinkFilterBottomSheetState();
}

class _DrinkFilterBottomSheetState extends State<DrinkFilterBottomSheet> {
  // 現在のフィルター値（編集可能なコピー）
  late Map<String, dynamic> _currentFilterValues;
  late List<FilterOption> _filterOptions;
  
  @override
  void initState() {
    super.initState();
    // フィルター値のディープコピーを作成して編集可能にする
    _currentFilterValues = Map<String, dynamic>.from(widget.filterValues);
    
    // カテゴリに対応するフィルターオプションを取得
    _filterOptions = DrinkFilterOptions.getOptionsForCategory(
      widget.category,
      context,
      _currentFilterValues,
      _updateFilterValue,
    );
  }
  
  // フィルター値を更新するコールバック
  void _updateFilterValue(String key, dynamic value) {
    setState(() {
      _currentFilterValues[key] = value;
    });
  }
  
  // フィルターをクリアする
  void _clearFilters() {
    setState(() {
      _currentFilterValues.clear();
    });
    widget.onClearFilters();
    Navigator.pop(context);
  }
  
  // フィルターを適用する
  void _applyFilters() {
    widget.onApplyFilters(_currentFilterValues);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_filterOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '詳細検索',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // フィルターオプション
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        option.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    option.buildWidget(context, _currentFilterValues, _updateFilterValue),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          
          // アクションボタン
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('フィルターを適用', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('フィルターをリセット', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
