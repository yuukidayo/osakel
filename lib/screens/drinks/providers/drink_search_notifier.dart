import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/drink_category.dart';
import '../models/drink_search_criteria.dart';
import '../services/drink_search_service.dart';

/// ドリンク検索画面の状態を管理するChangeNotifier
class DrinkSearchNotifier extends ChangeNotifier {
  // サービス
  final DrinkSearchService _searchService = DrinkSearchService();
  
  // 状態
  final DrinkSearchCriteria _searchCriteria = DrinkSearchCriteria();
  List<DrinkCategory> _categories = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDebugMode = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _searchSnapshot;
  bool _isInitialSearchPerformed = false;
  DateTime? _lastSearchTime;

  // ゲッター
  DrinkSearchCriteria get searchCriteria => _searchCriteria;
  List<DrinkCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isDebugMode => _isDebugMode;
  Stream<QuerySnapshot<Map<String, dynamic>>>? get searchSnapshot => _searchSnapshot;
  bool get isInitialSearchPerformed => _isInitialSearchPerformed;
  DateTime? get lastSearchTime => _lastSearchTime;
  
  /// 選択されたカテゴリ
  String get selectedCategory => _searchCriteria.selectedCategory;
  
  /// カテゴリの表示名
  String get categoryDisplayName => _searchCriteria.categoryDisplayName;
  
  /// 選択されたサブカテゴリ
  String? get selectedSubcategory => _searchCriteria.selectedSubcategory;
  
  /// 検索キーワード
  String get searchKeyword => _searchCriteria.searchKeyword;
  
  /// サブカテゴリのリスト
  List<String> _subcategories = [];
  List<String> get subcategories => _subcategories;

  /// 初期化
  Future<void> initialize() async {
    await loadCategories();
    executeSearch();
  }

  /// カテゴリを読み込む
  Future<void> loadCategories() async {
    _setLoading(true);
    
    try {
      // カテゴリ情報を取得
      _categories = await _searchService.loadCategories();
      
      // 「すべてのカテゴリ」を先頭に追加
      _categories.insert(0, DrinkCategory(
        id: 'all',
        name: 'すべてのカテゴリ',
        order: -1,
        subcategories: [],
      ));
      
      // サブカテゴリを更新
      await updateSubcategories();
      
      _setLoading(false);
    } catch (e) {
      print('カテゴリ読み込みエラー: $e');
      _setError(true);
      _setLoading(false);
    }
  }

  /// 選択されたカテゴリに基づいてサブカテゴリを更新
  Future<void> updateSubcategories() async {
    try {
      if (_searchCriteria.selectedCategory == 'すべてのカテゴリ') {
        // 「すべてのカテゴリ」の場合、すべてのカテゴリからサブカテゴリを集める
        final allSubcategories = <String>{};
        
        for (final category in _categories) {
          if (category.id != 'all') {
            allSubcategories.addAll(category.subcategories);
          }
        }
        
        _subcategories = allSubcategories.toList()
          ..sort((a, b) => a.compareTo(b));
      } else {
        // 特定のカテゴリの場合、そのカテゴリのサブカテゴリを取得
        final selectedCategoryItem = _categories.firstWhere(
          (category) => category.name == _searchCriteria.selectedCategory,
          orElse: () => DrinkCategory(
            id: '',
            name: '',
            order: 0,
            subcategories: [],
          ),
        );
        
        _subcategories = List<String>.from(selectedCategoryItem.subcategories)
          ..sort((a, b) => a.compareTo(b));
      }
      
      notifyListeners();
    } catch (e) {
      print('サブカテゴリ更新エラー: $e');
    }
  }

  /// カテゴリを選択
  Future<void> selectCategory(String id, String name) async {
    // カテゴリ情報を更新
    _searchCriteria.updateCategory(id, name);
    
    // サブカテゴリを更新
    await updateSubcategories();
    
    // 検索を実行
    executeSearch();
    
    notifyListeners();
  }

  /// サブカテゴリを選択
  void selectSubcategory(String? subcategory) {
    _searchCriteria.updateSubcategory(subcategory);
    executeSearch();
    notifyListeners();
  }

  /// 検索キーワードを更新
  void updateSearchKeyword(String keyword) {
    _searchCriteria.updateSearchKeyword(keyword);
    executeSearch();
    notifyListeners();
  }

  /// フィルターを適用
  void applyFilters(Map<String, dynamic> filters) {
    _searchCriteria.applyFilters(filters);
    executeSearch();
    notifyListeners();
  }

  /// フィルターをクリア
  void clearFilters() {
    _searchCriteria.clearFilters();
    executeSearch();
    notifyListeners();
  }

  /// デバッグモードを切り替え
  void toggleDebugMode() {
    _isDebugMode = !_isDebugMode;
    notifyListeners();
  }

  /// 検索を実行
  void executeSearch() {
    try {
      _hasError = false;
      
      // クエリを生成
      final query = _searchService.buildQuery(_searchCriteria);
      
      // 検索実行時刻を記録
      _lastSearchTime = DateTime.now();
      
      // 検索結果を取得
      _searchSnapshot = query.snapshots();
      _isInitialSearchPerformed = true;
      
      notifyListeners();
    } catch (e) {
      print('❌ 検索処理エラー: $e');
      _searchSnapshot = null;
      _hasError = true;
      notifyListeners();
    }
  }

  // ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // エラー状態を設定
  void _setError(bool hasError) {
    _hasError = hasError;
    notifyListeners();
  }
}
