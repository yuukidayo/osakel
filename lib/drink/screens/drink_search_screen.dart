import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import '../../store/screens/shop_search_screen.dart';
import '../../shared/widgets/filters/drink_filter_bottom_sheet.dart';
import '../../shared/widgets/modals/category_selection_modal.dart';
import '../widgets/category_top_bar.dart';
import '../widgets/search_bar.dart';
import '../widgets/subcategory_bar.dart';
import '../widgets/search_results_list.dart';
import '../widgets/drink_search_notifier.dart';

class DrinkSearchScreen extends StatefulWidget {
  static const String routeName = '/drink_search';

  /// お店検索画面への切り替えコールバック
  final VoidCallback? onSwitchToShopSearch;

  const DrinkSearchScreen({super.key, this.onSwitchToShopSearch});

  @override
  State<DrinkSearchScreen> createState() => _DrinkSearchScreenState();
}

class _DrinkSearchScreenState extends State<DrinkSearchScreen> {
  // Search input
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 遅延初期化を使用して、最初のビルド後にプロバイダーを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchNotifier = Provider.of<DrinkSearchNotifier>(context, listen: false);
      searchNotifier.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // お店検索画面への遷移（右から左へのスライドアニメーション）
  // 右側のアイコンタップ時の遷移処理
  void _navigateToShopSearch() {
    developer.log('DrinkSearchScreen: お店検索画面への遷移を試みます');
    // IndexedStackによる切り替えが設定されている場合はそれを使用
    if (widget.onSwitchToShopSearch != null) {
      developer.log('DrinkSearchScreen: IndexedStackでの切り替えを使用');
      widget.onSwitchToShopSearch!();
      return;
    }
  
    // コールバックがない場合のフォールバック処理（デバッグ用）
    developer.log('DrinkSearchScreen: コールバックがないため通常ナビゲーションを使用');
    
    // 従来のナビゲーション方法（後方互換性のため残す）
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ShopSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // カテゴリ読み込みはProviderに移行済み  // サブカテゴリ選択処理
  void _selectSubcategory(String? name, String? id) {
    final provider = Provider.of<DrinkSearchNotifier>(context, listen: false);
    provider.selectSubcategory(name, id);
  }

  // カテゴリ選択処理
  void _selectCategory(String id, String name) {
    final provider = Provider.of<DrinkSearchNotifier>(context, listen: false);
    provider.selectCategory(id, name);
  }



  @override
  Widget build(BuildContext context) {
    // ConsumerWidgetを使用して状態変更を監視
    return Consumer<DrinkSearchNotifier>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white, // 純白(#FFFFFF)に設定
          body: SafeArea(
            child: Column(
              children: [
                _buildCategoryTopBar(),
                _buildSearchBar(),
                _buildSubcategoryBar(),
                Expanded(child: _buildSearchResultsList()),
              ],
            ),
          ),

        );
      },
    );
  }

  // 画面上部のバー（左：プロフィールアイコン、中央：カテゴリ選択、右：店舗検索アイコン）
  Widget _buildCategoryTopBar() {
    final provider = Provider.of<DrinkSearchNotifier>(context);
    return CategoryTopBar(
      categoryDisplayName: provider.categoryDisplayName,
      onCategoryTap: _showCategoryModal,
      onSwitchToShopSearch: _navigateToShopSearch,
    );
  }

  // カテゴリ選択ダイアログ
  void _showCategoryModal() {
    final provider = Provider.of<DrinkSearchNotifier>(context, listen: false);
    
    CategorySelectionModal.show(
      context: context,
      categories: provider.categories,
      selectedCategory: provider.selectedCategory,
      onCategorySelected: (categoryId, categoryName) {
        provider.selectCategory(categoryId, categoryName);
      },
      title: 'カテゴリを選択',
    );
  }

  // Milestone3: 検索ボックス
  Widget _buildSearchBar() {
    final provider = Provider.of<DrinkSearchNotifier>(context);
    return DrinkSearchBar(
      controller: _searchController,
      onChanged: provider.updateSearchKeyword,
      searchKeyword: provider.searchKeyword,
      isEnabled: provider.selectedCategory == 'すべてのカテゴリ' &&
          (provider.selectedSubcategory == null || provider.selectedSubcategory!.isEmpty),
    );
  }

  // Milestone4: サブカテゴリバー
  Widget _buildSubcategoryBar() {
    final provider = Provider.of<DrinkSearchNotifier>(context);
    return SubcategoryBar(
      isLoadingCategories: provider.isLoading,
      categories: provider.categories.map((category) => {
        'id': category.id,
        'name': category.name,
        'order': category.order,
        'subcategories': category.subcategories,
      }).toList(),
      subcategories: provider.subcategories,
      selectedCategory: provider.selectedCategory,
      selectedSubcategory: provider.selectedSubcategory,
      onCategorySelected: _selectCategory,
      onSubcategorySelected: (name, id) => _selectSubcategory(name, id),
      onShowFilterBottomSheet: _showFilterBottomSheet,
      buildSubcategoryChip: ({required String label, required bool isSelected, required VoidCallback onTap}) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ActionChip(
            label: Text(label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
            backgroundColor: isSelected ? Colors.black87 : Colors.grey.shade200,
            onPressed: onTap,
          ),
        );
      },
    );
  }

  // 詳細検索ボトムシートを表示
  void _showFilterBottomSheet() {
    final provider = Provider.of<DrinkSearchNotifier>(context, listen: false);
    
    DrinkFilterBottomSheet.show(
      context: context,
      category: provider.selectedCategory,
      filterValues: provider.searchCriteria.filterValues,
      onApplyFilters: (Map<String, dynamic> updatedFilters) {
        provider.applyFilters(updatedFilters);
      },
      onClearFilters: () {
        provider.clearFilters();
      },
    );
  }

  // Milestone5＆6: 検索結果リスト
  Widget _buildSearchResultsList() {
    final provider = Provider.of<DrinkSearchNotifier>(context);
    
    return SearchResultsList(
      searchSnapshot: provider.searchSnapshot,
      hasError: provider.hasError,
      isDebugMode: provider.isDebugMode,
      buildDebugPanel: _buildDebugPanel,
      categories: provider.categories.map((category) => {
        'id': category.id,
        'name': category.name,
        'order': category.order,
        'subcategories': category.subcategories,
      }).toList(),
    );
  }

  // デバッグパネルを構築（ドキュメント数を引数で受け取る）
  Widget _buildDebugPanel(int resultCount) {
    final provider = Provider.of<DrinkSearchNotifier>(context, listen: false);
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.8), // 黒背景（半透明）
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📊 デバッグ情報', 
                style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold), // 白テキスト
              ),
              GestureDetector(
                onTap: () => provider.toggleDebugMode(),
                child: const Icon(Icons.close, color: Color(0xFFFFFFFF), size: 20), // 白アイコン
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🔍 検索: ${provider.selectedCategory == 'すべてのカテゴリ' ? 'すべて' : provider.selectedCategory}'  
            '${provider.selectedSubcategory != null ? ' > ${provider.selectedSubcategory}' : ''}'  
            '${provider.searchKeyword.isNotEmpty ? ' "${provider.searchKeyword}"' : ''}',
            style: const TextStyle(color: Color(0xFFFFFFFF)), // 白テキスト
          ),
          Text('📄 結果: $resultCount 件', style: const TextStyle(color: Color(0xFFFFFFFF))), // 白テキスト
          Text('🕒 検索時間: ${provider.lastSearchTime != null ? provider.lastSearchTime!.toIso8601String().substring(11, 19) : "-"} ', 
            style: const TextStyle(color: Color(0xFFFFFFFF))),
        ],
      ),
    );
  }
}
