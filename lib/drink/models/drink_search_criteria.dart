import 'package:flutter/material.dart';

/// ドリンク検索の条件を管理するモデルクラス
class DrinkSearchCriteria {
  /// アルコール度数のデフォルト範囲
  static final RangeValues defaultAlcoholRange = const RangeValues(0, 100);
  
  /// 価格のデフォルト範囲
  static final RangeValues defaultPriceRange = const RangeValues(0, 50000);
  /// 選択されたカテゴリ（表示用の名前）
  String selectedCategory;
  
  /// 選択されたカテゴリのID（検索用）
  String selectedCategoryId;
  
  /// カテゴリの表示名
  String categoryDisplayName;
  
  /// 選択されたサブカテゴリ（表示用の名前）
  String? selectedSubcategory;
  
  /// 選択されたサブカテゴリID（検索用）
  String? selectedSubcategoryId;
  
  /// 検索キーワード
  String searchKeyword;
  
  /// 詳細フィルターの適用状態
  bool isFiltersApplied;
  
  /// 詳細フィルターの値
  Map<String, dynamic> filterValues;

  DrinkSearchCriteria({
    this.selectedCategory = 'すべてのカテゴリ',
    this.selectedCategoryId = 'all',
    this.categoryDisplayName = 'すべてのカテゴリ',
    this.selectedSubcategory,
    this.selectedSubcategoryId,
    this.searchKeyword = '',
    this.isFiltersApplied = false,
    Map<String, dynamic>? filterValues,
  }) : filterValues = filterValues ?? {};

  /// 深いコピーを作成
  DrinkSearchCriteria copyWith({
    String? selectedCategory,
    String? selectedCategoryId,
    String? categoryDisplayName,
    String? Function()? selectedSubcategory,
    String? Function()? selectedSubcategoryId,
    String? searchKeyword,
    bool? isFiltersApplied,
    Map<String, dynamic>? filterValues,
  }) {
    return DrinkSearchCriteria(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      categoryDisplayName: categoryDisplayName ?? this.categoryDisplayName,
      selectedSubcategory: selectedSubcategory != null
          ? selectedSubcategory()
          : this.selectedSubcategory,
      selectedSubcategoryId: selectedSubcategoryId != null
          ? selectedSubcategoryId()
          : this.selectedSubcategoryId,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isFiltersApplied: isFiltersApplied ?? this.isFiltersApplied,
      filterValues: filterValues ?? Map<String, dynamic>.from(this.filterValues),
    );
  }

  /// カテゴリ選択を更新
  void updateCategory(String id, String name) {
    selectedCategory = name;
    selectedCategoryId = id;
    categoryDisplayName = name;
    selectedSubcategory = null;
    selectedSubcategoryId = null;
  }

  /// サブカテゴリを更新（名前とIDを別々に管理）
  void updateSubcategory(String? name, String? id) {
    selectedSubcategory = name; // 表示用
    selectedSubcategoryId = id;  // 検索用
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
        'subcategoryId: $selectedSubcategoryId, '
        'keyword: $searchKeyword, '
        'filtersApplied: $isFiltersApplied, '
        'filterValues: $filterValues)';
  }
}
