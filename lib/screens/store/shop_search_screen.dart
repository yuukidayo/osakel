import 'package:flutter/material.dart';

import '../drinks/components/category_top_bar.dart';
import '../../widgets/modals/category_selection_modal.dart';
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

  /// カテゴリモーダルを表示（美しい共通コンポーネント使用）
  void _showCategoryModal() {
    CategorySelectionModal.show(
      context: context,
      categories: _categories,
      selectedCategory: _selectedCategory,
      onCategorySelected: _selectCategory,
      title: 'お店カテゴリを選択',
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
