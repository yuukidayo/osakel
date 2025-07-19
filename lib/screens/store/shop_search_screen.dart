import 'package:flutter/material.dart';

import '../drinks/components/category_top_bar.dart';
import 'components/shop_search_results.dart';
import '../drinks/models/drink_category.dart';
import 'services/shop_search_service.dart';
import 'models/shop_search_criteria.dart';
import '../../models/shop.dart';
import 'shop_detail_screen.dart';

/// お店検索画面（簡潔版）
class ShopSearchScreen extends StatefulWidget {
  final VoidCallback? onSwitchToDrinkSearch;
  
  const ShopSearchScreen({
    Key? key,
    this.onSwitchToDrinkSearch,
  }) : super(key: key);

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  final ShopSearchService _searchService = ShopSearchService();
  
  // 状態管理
  List<DrinkCategory> _categories = [];
  String _selectedCategory = 'すべてのカテゴリ';
  String _selectedCategoryId = 'all';
  bool _isLoading = true;
  
  // 検索結果
  List<Shop> _shops = [];
  bool _isSearching = false;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// カテゴリを読み込む
  Future<void> _loadCategories() async {
    try {
      final categories = await _searchService.loadCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      
      // 初期検索を実行
      await _performInitialSearch();
    } catch (e) {
      setState(() {
        _searchError = 'カテゴリの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  /// 初期検索を実行
  Future<void> _performInitialSearch() async {
    print('🔍 初期検索を実行: すべてのカテゴリ');
    
    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final criteria = ShopSearchCriteria(
        selectedCategoryId: 'all',
        selectedCategory: 'すべてのカテゴリ',
      );
      
      final shops = await _searchService.searchShops(criteria);
      
      setState(() {
        _shops = shops;
        _isSearching = false;
      });
      
      print('✅ 初期検索完了: ${shops.length}件のお店が見つかりました');
    } catch (e) {
      setState(() {
        _searchError = '検索に失敗しました: $e';
        _isSearching = false;
      });
      print('❌ 初期検索エラー: $e');
    }
  }

  /// カテゴリモーダルを表示（お酒検索画面と同じ美しいデザイン）
  void _showCategoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 高さの制約を外す
      backgroundColor: Colors.transparent, // 背景を透明に
      builder: (context) => Container(
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
            Container(
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
                  const Text(
                    'カテゴリを選択',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE), // 薄いグレー
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close, size: 20, color: Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),
                            
            // カテゴリ一覧（スクロール可能）
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category.name;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                        onTap: () {
                          // モーダルを閉じる
                          Navigator.of(context).pop();
                          // カテゴリを選択
                          _selectCategory(category.id, category.name);
                        },
                      ),
                      // リストの区切り線
                      if (index < _categories.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// カテゴリを選択
  void _selectCategory(String categoryId, String categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategory = categoryName;
    });
    
    Navigator.pop(context);
    _performSearch();
  }

  /// 検索を実行
  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final criteria = ShopSearchCriteria(
        selectedCategoryId: _selectedCategoryId,
        selectedCategory: _selectedCategory,
      );
      
      final shops = await _searchService.searchShops(criteria);
      
      setState(() {
        _shops = shops;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = '検索に失敗しました: $e';
        _isSearching = false;
      });
    }
  }

  /// お酒検索画面に切り替え
  void _switchToDrinkSearch() {
    if (widget.onSwitchToDrinkSearch != null) {
      // IndexStackでの切り替え
      widget.onSwitchToDrinkSearch!();
    } else {
      // フォールバック: 既存のナビゲーション
      Navigator.pop(context);
    }
  }

  /// お店詳細画面に遷移
  void _navigateToShopDetail(Shop shop) {
    print('🏪 お店詳細画面に遷移: ${shop.name}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailScreen(
          shop: shop,
          price: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // カテゴリ選択バー（SafeAreaでステータスバーから保護）
          SafeArea(
            child: CategoryTopBar(
              categoryDisplayName: _selectedCategory,
              onCategoryTap: _showCategoryModal,
              onSwitchToShopSearch: _switchToDrinkSearch,
              switchIcon: Icons.local_bar, // お酒アイコンでお酒検索に切り替え
            ),
          ),
          
          // 検索結果表示エリア
          Expanded(
            child: ShopSearchResults(
              shops: _shops,
              isLoading: _isLoading,
              isSearching: _isSearching,
              searchError: _searchError,
              onRetry: _performSearch,
              onShopTap: _navigateToShopDetail,
            ),
          ),
        ],
      ),
    );
  }
}
