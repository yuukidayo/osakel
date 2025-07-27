import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../drink/models/drink_category.dart';

/// 共有カテゴリ状態管理（お酒検索とお店検索で同期）
class SharedCategoryProvider extends ChangeNotifier {
  static const String _selectedCategoryKey = 'selected_category';
  static const String _selectedCategoryIdKey = 'selected_category_id';
  
  String _selectedCategory = 'すべてのカテゴリ';
  String _selectedCategoryId = 'all';
  List<DrinkCategory> _categories = [];
  bool _isLoaded = false;

  // Getters
  String get selectedCategory => _selectedCategory;
  String get selectedCategoryId => _selectedCategoryId;
  List<DrinkCategory> get categories => _categories;
  bool get isLoaded => _isLoaded;

  /// 初期化（SharedPreferencesから復元）
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCategory = prefs.getString(_selectedCategoryKey) ?? 'すべてのカテゴリ';
      _selectedCategoryId = prefs.getString(_selectedCategoryIdKey) ?? 'all';
      _isLoaded = true;
      
      debugPrint('🔄 SharedCategoryProvider初期化完了');
      debugPrint('📂 復元されたカテゴリ: $_selectedCategory (ID: $_selectedCategoryId)');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SharedCategoryProvider初期化エラー: $e');
    }
  }

  /// カテゴリリストを設定
  void setCategories(List<DrinkCategory> categories) {
    _categories = categories;
    notifyListeners();
  }

  /// カテゴリを選択（両画面で共有）
  Future<void> selectCategory(String categoryId, String categoryName) async {
    if (_selectedCategoryId == categoryId) return;
    
    _selectedCategoryId = categoryId;
    _selectedCategory = categoryName;
    
    // SharedPreferencesに永続化
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCategoryKey, categoryName);
      await prefs.setString(_selectedCategoryIdKey, categoryId);
      
      debugPrint('💾 カテゴリ選択を保存: $categoryName (ID: $categoryId)');
    } catch (e) {
      debugPrint('❌ カテゴリ選択保存エラー: $e');
    }
    
    notifyListeners();
  }

  /// 選択状態をリセット
  Future<void> resetSelection() async {
    await selectCategory('all', 'すべてのカテゴリ');
  }

  /// 指定されたカテゴリが選択されているかチェック
  bool isSelected(String categoryName) {
    return _selectedCategory == categoryName;
  }

  /// 指定されたカテゴリIDが選択されているかチェック
  bool isSelectedById(String categoryId) {
    return _selectedCategoryId == categoryId;
  }

  /// デバッグ情報を出力
  void debugInfo() {
    debugPrint('🔍 SharedCategoryProvider状態:');
    debugPrint('  - 選択カテゴリ: $_selectedCategory');
    debugPrint('  - 選択カテゴリID: $_selectedCategoryId');
    debugPrint('  - カテゴリ数: ${_categories.length}');
    debugPrint('  - 初期化済み: $_isLoaded');
  }
}
