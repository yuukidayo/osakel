import 'package:flutter/material.dart';
import '../store/models/shop_with_price.dart';

/// MapScreen の状態管理クラス
class MapScreenState extends ChangeNotifier {
  // UI状態
  bool _isSearchModalVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Getters
  bool get isSearchModalVisible => _isSearchModalVisible;
  TextEditingController get searchController => _searchController;
  FocusNode get searchFocusNode => _searchFocusNode;

  /// 検索モーダル表示
  void showSearchModal() {
    _isSearchModalVisible = true;
    notifyListeners();
  }

  /// 検索モーダル非表示
  void hideSearchModal() {
    _isSearchModalVisible = false;
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    notifyListeners();
  }

  /// 検索実行
  void executeSearch(String location, Function(String) onLocationSearch) {
    // キーボードを閉じる
    FocusManager.instance.primaryFocus?.unfocus();
    
    // モーダルを閉じる
    hideSearchModal();
    
    // 位置検索を実行
    onLocationSearch(location);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
