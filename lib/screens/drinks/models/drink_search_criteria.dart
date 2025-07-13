import 'package:flutter/material.dart';

/// ドリンク検索の条件を管理するモデルクラス
class DrinkSearchCriteria {
  /// アルコール度数のデフォルト範囲
  static final RangeValues defaultAlcoholRange = const RangeValues(0, 100);
  
  /// 価格のデフォルト範囲
  static final RangeValues defaultPriceRange = const RangeValues(0, 50000);
  /// 選択されたカテゴリ
  String selectedCategory;
  
  /// カテゴリの表示名
  String categoryDisplayName;
  
  /// 選択されたサブカテゴリ
  String? selectedSubcategory;
  
  /// 検索キーワード
  String searchKeyword;
  
  /// 詳細フィルターの適用状態
  bool isFiltersApplied;
  
  /// 詳細フィルターの値
  Map<String, dynamic> filterValues;

  DrinkSearchCriteria({
    this.selectedCategory = 'すべてのカテゴリ',
    this.categoryDisplayName = 'すべてのカテゴリ',
    this.selectedSubcategory,
    this.searchKeyword = '',
    this.isFiltersApplied = false,
    Map<String, dynamic>? filterValues,
  }) : filterValues = filterValues ?? {};

  /// 深いコピーを作成
  DrinkSearchCriteria copyWith({
    String? selectedCategory,
    String? categoryDisplayName,
    String? Function()? selectedSubcategory,
    String? searchKeyword,
    bool? isFiltersApplied,
    Map<String, dynamic>? filterValues,
  }) {
    return DrinkSearchCriteria(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categoryDisplayName: categoryDisplayName ?? this.categoryDisplayName,
      selectedSubcategory: selectedSubcategory != null
          ? selectedSubcategory()
          : this.selectedSubcategory,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isFiltersApplied: isFiltersApplied ?? this.isFiltersApplied,
      filterValues: filterValues ?? Map<String, dynamic>.from(this.filterValues),
    );
  }

  /// カテゴリ選択を更新
  void updateCategory(String id, String name) {
    selectedCategory = name;
    categoryDisplayName = name;
    selectedSubcategory = null;
  }

  /// サブカテゴリを更新
  void updateSubcategory(String? name) {
    selectedSubcategory = name;
  }

  /// 検索キーワードを更新
  void updateSearchKeyword(String keyword) {
    searchKeyword = keyword;
  }

  /// フィルターを適用
  void applyFilters(Map<String, dynamic> filters) {
    filterValues = Map<String, dynamic>.from(filters);
    isFiltersApplied = filters.isNotEmpty;
  }
  
  /// アルコール度数フィルターを適用
  void applyAlcoholRangeFilter(RangeValues range) {
    filterValues['alcoholRange'] = range;
    isFiltersApplied = true;
  }
  
  /// 価格フィルターを適用
  void applyPriceRangeFilter(RangeValues range) {
    filterValues['priceRange'] = range;
    isFiltersApplied = true;
  }

  /// フィルターをクリア
  void clearFilters() {
    filterValues.clear();
    isFiltersApplied = false;
  }
  
  @override
  String toString() {
    return 'DrinkSearchCriteria(category: $selectedCategory, '
        'subcategory: $selectedSubcategory, '
        'keyword: $searchKeyword, '
        'filtersApplied: $isFiltersApplied, '
        'filterValues: $filterValues)';
  }
}
