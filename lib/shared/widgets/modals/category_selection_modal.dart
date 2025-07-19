import 'package:flutter/material.dart';
import '../../../screens/drinks/models/drink_category.dart';

/// 美しいカテゴリ選択モーダル（共通コンポーネント）
class CategorySelectionModal extends StatelessWidget {
  final List<DrinkCategory> categories;
  final String selectedCategory;
  final Function(String categoryId, String categoryName) onCategorySelected;
  final String title;

  const CategorySelectionModal({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.title = 'カテゴリを選択',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 画面の85%の高さ
      decoration: const BoxDecoration(
        color: Colors.white, // 白背景
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ヘッダー（モーダルのタイトル部分）
          _buildHeader(context),
          
          // カテゴリ一覧（スクロール可能）
          Expanded(
            child: _buildCategoryList(context),
          ),
        ],
      ),
    );
  }

  /// ヘッダー部分の構築
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // 白背景
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  /// エレガントな閉じるボタン
  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // 非常に薄いグレー
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE0E0E0), // 薄いグレー枠線
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.close,
          size: 18,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  /// カテゴリリストの構築（「すべてのカテゴリ」を最初に追加）
  Widget _buildCategoryList(BuildContext context) {
    // 重複する「すべてのカテゴリ」を除外
    final filteredCategories = categories.where((category) => 
        category.name != 'すべてのカテゴリ').toList();
    
    // 「すべてのカテゴリ」 + フィルタリングされたカテゴリリスト
    final totalItemCount = 1 + filteredCategories.length;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // 最初の項目: 「すべてのカテゴリ」
          final isSelected = selectedCategory == 'すべてのカテゴリ';
          return Column(
            children: [
              _buildAllCategoryItem(context, isSelected),
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFF0F0F0),
                indent: 20,
                endIndent: 20,
              ),
            ],
          );
        } else {
          // 通常のカテゴリ項目（フィルタリングされたリストを使用）
          final categoryIndex = index - 1;
          final category = filteredCategories[categoryIndex];
          final isSelected = selectedCategory == category.name;
          
          return Column(
            children: [
              _buildCategoryItem(context, category, isSelected),
              // リストの区切り線（最後の項目以外）
              if (categoryIndex < filteredCategories.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xFFF0F0F0),
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }
      },
    );
  }

  /// カテゴリ項目の構築
  Widget _buildCategoryItem(BuildContext context, DrinkCategory category, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // モーダルを閉じる
          Navigator.of(context).pop();
          // カテゴリを選択
          onCategorySelected(category.id, category.name);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : const Color(0xFF333333),
                      ),
                    ),
                    // サブカテゴリのプレビュー（あれば表示）
                    if (category.subcategories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          category.subcategories
                              .take(3) // 最初の3つだけ表示
                              .join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // 選択状態のチェックマーク
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// モーダルを表示するヘルパーメソッド
  static Future<void> show({
    required BuildContext context,
    required List<DrinkCategory> categories,
    required String selectedCategory,
    required Function(String categoryId, String categoryName) onCategorySelected,
    String title = 'カテゴリを選択',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 高さの制約を外す
      backgroundColor: Colors.transparent, // 背景を透明に
      builder: (context) => CategorySelectionModal(
        categories: categories,
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
        title: title,
      ),
    );
  }

  /// 「すべてのカテゴリ」項目の構築
  Widget _buildAllCategoryItem(BuildContext context, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // モーダルを閉じる
          Navigator.of(context).pop();
          // 「すべてのカテゴリ」を選択
          onCategorySelected('all', 'すべてのカテゴリ');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'すべてのカテゴリ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : const Color(0xFF333333),
                  ),
                ),
              ),
              // 選択状態のチェックマーク
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
