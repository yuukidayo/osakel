import 'package:flutter/material.dart';

/// カテゴリ選択用ウィジェット
/// カテゴリ選択バーとモーダルシートを提供
class CategorySelectorWidget extends StatelessWidget {
  final String selectedCategory;
  final String categoryDisplayName;
  final List<Map<String, dynamic>> categories;
  final bool isLoadingCategories;
  final Function(String id, String name) onCategorySelected;
  final VoidCallback onShowCategoryModal;

  const CategorySelectorWidget({
    super.key,
    required this.selectedCategory,
    required this.categoryDisplayName,
    required this.categories,
    required this.isLoadingCategories,
    required this.onCategorySelected,
    required this.onShowCategoryModal,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCategoryTopBar(context);
  }

  /// カテゴリトップバー（全カテゴリ/選択カテゴリの表示と選択用ボタン）
  Widget _buildCategoryTopBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE), // 薄いグレーの下線
            width: 1,
          ),
        ),
        color: Colors.white, // 白背景
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // カテゴリ選択ボタン
          Expanded(
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: onShowCategoryModal,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEEEEEE)), // 薄いグレーの枠線
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.category,
                        size: 20,
                        color: Color(0xFF333333), // ダークグレーアイコン
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryDisplayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333), // ダークグレーテキスト
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF333333), // ダークグレーアイコン
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// カテゴリ選択モーダルを表示
  static void showCategoryModal({
    required BuildContext context,
    required List<Map<String, dynamic>> categories,
    required String selectedCategory,
    required Function(String id, String name) onCategorySelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // モーダルヘッダー
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'カテゴリを選択',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // カテゴリリスト
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryId = category['id'];
                    final categoryName = category['name'];
                    final isSelected = categoryId == selectedCategory;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : const Color(0xFF333333),
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFF5F5F5), // 選択時の薄いグレー背景
                      onTap: () {
                        Navigator.pop(context);
                        onCategorySelected(categoryId, categoryName);
                      },
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.black,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
