import 'package:flutter/material.dart';

class SubcategoryBar extends StatelessWidget {
  // 基本情報
  final bool isLoadingCategories;
  final List<dynamic> categories;
  final List<dynamic> subcategories;
  final String selectedCategory;
  final String? selectedSubcategory;
  
  // コールバック関数
  final Function(String id, String name) onCategorySelected;
  final Function(String?) onSubcategorySelected;
  final VoidCallback onShowFilterBottomSheet;
  
  // カテゴリチップを生成する関数
  final Widget Function({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) buildSubcategoryChip;

  const SubcategoryBar({
    Key? key,
    required this.isLoadingCategories,
    required this.categories,
    required this.subcategories,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
    required this.onShowFilterBottomSheet,
    required this.buildSubcategoryChip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ローディング中
    if (isLoadingCategories) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    // 最優先：「すべてのカテゴリ」選択時は必ずカテゴリ一覧を表示
    if (selectedCategory == 'すべてのカテゴリ') {
      // カテゴリが空かどうかをチェック
      if (categories.isEmpty) {
        return const SizedBox(
          height: 50,
          child: Center(child: Text('カテゴリが読み込まれていません', style: TextStyle(color: Color(0xFF8A8A8A)))), // グレーテキスト
        );
      }
      
      // カテゴリ一覧を表示 + フィルターアイコン追加
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // フィルターアイコン (最左端に配置)
            _buildFilterIcon(),
            // すべてのカテゴリ選択中なので固有の表示方法
          ...categories.map((category) {
            final name = category['name'].toString();
            final id = category['id'].toString();
            return buildSubcategoryChip(
              label: name,
              isSelected: selectedSubcategory == name,
              onTap: () {
                // タップ時にカテゴリも連動して切り替える
                onCategorySelected(id, name);
              },
            );
          }),
          ],
        ),
      );
    }
    
    // 通常のサブカテゴリ表示（特定のカテゴリが選択されている場合）
    // 「すべてのカテゴリ」以外の場合のみ「サブカテゴリはありません」を表示
    if (subcategories.isEmpty && selectedCategory != 'すべてのカテゴリ') {
      return const SizedBox(
        height: 50,
        child: Center(child: Text('サブカテゴリはありません', style: TextStyle(color: Color(0xFF8A8A8A)))), // グレーテキスト
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // フィルターアイコン (最左端に配置)
          _buildFilterIcon(),
          // サブカテゴリチップ
          buildSubcategoryChip(
            label: 'すべて',
            isSelected: selectedSubcategory == null,
            onTap: () => onSubcategorySelected(null),
          ),
          ...subcategories.map((s) {
            final name = s is String ? s : s['name'].toString();
            return buildSubcategoryChip(
              label: name,
              isSelected: selectedSubcategory == name,
              onTap: () => onSubcategorySelected(name),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterIcon() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // 白色背景
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDDDD)), // 薄いグレー枠線
      ),
      child: IconButton(
        icon: const Icon(Icons.filter_list, size: 20),
        onPressed: onShowFilterBottomSheet,
        tooltip: '詳細検索',
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
