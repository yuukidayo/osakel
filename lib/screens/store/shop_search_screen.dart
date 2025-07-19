import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../drinks/components/category_top_bar.dart';
import '../../widgets/modals/category_selection_modal.dart';
import '../../providers/shared_category_provider.dart';
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
  
  // 状態管理（カテゴリ選択は共有状態で管理）
  List<DrinkCategory> _categories = [];
  bool _isLoading = true;
  
  // 検索結果
  List<Shop> _shops = [];
  bool _isSearching = false;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    // 共有状態を初期化してからカテゴリを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sharedProvider = Provider.of<SharedCategoryProvider>(context, listen: false);
      sharedProvider.initialize().then((_) {
        _loadCategories();
      });
    });
  }

  /// カテゴリを読み込む
  Future<void> _loadCategories() async {
    try {
      final categories = await _searchService.loadCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      
      // 共有状態にカテゴリリストを設定
      if (mounted) {
        final sharedProvider = Provider.of<SharedCategoryProvider>(context, listen: false);
        sharedProvider.setCategories(categories);
      }
      
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
    if (!mounted) return;
    
    final sharedProvider = Provider.of<SharedCategoryProvider>(context, listen: false);
    print('🔍 初期検索を実行: ${sharedProvider.selectedCategory}');
    
    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final criteria = ShopSearchCriteria(
        selectedCategoryId: sharedProvider.selectedCategoryId,
        selectedCategory: sharedProvider.selectedCategory,
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
    final sharedProvider = Provider.of<SharedCategoryProvider>(context, listen: false);
    CategorySelectionModal.show(
      context: context,
      categories: _categories,
      selectedCategory: sharedProvider.selectedCategory,
      onCategorySelected: _selectCategory,
      title: 'カテゴリを選択',
    );
  }

  /// カテゴリを選択（モーダルは既に閉じられている）
  void _selectCategory(String categoryId, String categoryName) {
    print('📝 カテゴリ選択開始: $categoryName (ID: $categoryId)');
    
    try {
      // 共有状態を更新
      final sharedProvider = Provider.of<SharedCategoryProvider>(context, listen: false);
      print('📝 SharedProvider取得成功');
      
      sharedProvider.selectCategory(categoryId, categoryName);
      print('📝 共有状態更新成功');
      
      // モーダルは既にCategorySelectionModal内で閉じられているので、ここではNavigator.pop()を呼ばない
      print('📝 モーダルは既に閉じられている');
      
      _performSearch();
      print('📝 検索実行開始');
    } catch (e, stackTrace) {
      print('❌ カテゴリ選択エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      
      // エラー状態を表示
      if (mounted) {
        setState(() {
          _searchError = 'カテゴリ選択エラー: $e';
        });
      }
    }
  }

  /// 検索を実行
  Future<void> _performSearch() async {
    print('🔍 検索実行開始');
    
    try {
      final sharedProvider = Provider.of<SharedCategoryProvider>(context, listen: false);
      print('🔍 SharedProvider取得: ${sharedProvider.selectedCategory}');
      
      setState(() {
        _isSearching = true;
        _searchError = '';
      });
      print('🔍 検索状態を更新');

      final criteria = ShopSearchCriteria(
        selectedCategoryId: sharedProvider.selectedCategoryId,
        selectedCategory: sharedProvider.selectedCategory,
      );
      print('🔍 検索条件作成: ${criteria.selectedCategory}');
      
      final shops = await _searchService.searchShops(criteria);
      print('🔍 検索結果: ${shops.length}件');
      
      if (mounted) {
        setState(() {
          _shops = shops;
          _isSearching = false;
        });
        print('🔍 検索結果を表示更新');
      }
    } catch (e, stackTrace) {
      print('❌ 検索エラー: $e');
      print('❌ スタックトレース: $stackTrace');
      
      if (mounted) {
        setState(() {
          _searchError = '検索に失敗しました: $e';
          _isSearching = false;
        });
      }
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
    return Consumer<SharedCategoryProvider>(
      builder: (context, sharedProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // カテゴリ選択バー（SafeAreaでステータスバーから保護）
              SafeArea(
                child: CategoryTopBar(
                  categoryDisplayName: sharedProvider.selectedCategory,
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
      },
    );
  }
}
