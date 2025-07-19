import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../store/shop_search_screen.dart';
import '../../widgets/filters/drink_filter_bottom_sheet.dart';
import './components/category_top_bar.dart';
import './components/search_bar.dart';
import './components/subcategory_bar.dart';
import './components/search_results_list.dart';

class DrinkSearchScreen extends StatefulWidget {
  static const String routeName = '/drink_search';

  /// お店検索画面への切り替えコールバック
  final VoidCallback? onSwitchToShopSearch;

  const DrinkSearchScreen({Key? key, this.onSwitchToShopSearch}) : super(key: key);

  @override
  State<DrinkSearchScreen> createState() => _DrinkSearchScreenState();
}

class _DrinkSearchScreenState extends State<DrinkSearchScreen> {
  // Category state management
  String _selectedCategory = 'すべてのカテゴリ';
  String? _selectedSubcategory;
  String _categoryDisplayName = 'すべてのカテゴリ';
  List<Map<String, dynamic>> _categories = [];
  List<dynamic> _subcategories = [];
  bool _isLoadingCategories = true;

  // Search state management
  String _searchKeyword = '';

  // Query results state
  bool _hasError = false;
  
  // デバッグ用の状態
  bool _isDebugMode = false;
  
  // 初期検索状態のトラッキング
  bool _isInitialSearchPerformed = false;

  // Search input
  final _searchController = TextEditingController();
  Stream<QuerySnapshot>? _searchSnapshot;

  // 詳細フィルター関連
  final Map<String, dynamic> _filterValues = {}; // _showFilterBottomSheetと_updateFilterValueメソッドで使用
  bool _isFiltersApplied = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // お店検索画面への遷移（右から左へのスライドアニメーション）
  // 右側のアイコンタップ時の遷移処理
  void _navigateToShopSearch() {
    // IndexedStackによる切り替えが設定されている場合はそれを使用
    if (widget.onSwitchToShopSearch != null) {
      widget.onSwitchToShopSearch!();
      return;
    }
  
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

  /// マイルストーン2：Firestore からカテゴリをロード
  Future<void> _loadCategories() async {
    try {
      print('カテゴリ読み込み開始');
      
      // まず通常のクエリで取得してみる
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      
      print('取得成功: ${snap.docs.length}件のカテゴリ');
      
      // ドキュメントの内容をマップに変換し、orderフィールドを追加
      print('全ドキュメント数: ${snap.docs.length}');
      
      final data = snap.docs.map((doc) {
        // ドキュメントデータの詳細なデバッグ情報
        final docData = doc.data();
        print('ドキュメントID: ${doc.id}');
        print('  全データ: $docData');
        print('  データ型: ${docData.runtimeType}');
        print('  キー一覧: ${docData.keys.toList()}');
        print('  値一覧: ${docData.values.toList()}');
        
        // 各フィールドを個別にデバッグ
        if (docData['name'] != null) print('  name: ${docData['name']}');
        if (docData['order'] != null) print('  order: ${docData['order']}');
        if (docData['subcategories'] != null) print('  サブカテゴリ数: ${(docData['subcategories'] as List?)?.length ?? 0}');
        
        return {
          'id': doc.id,
          'name': docData['name'] ?? 'No Name',
          'order': docData['order'] ?? 999,
          'subcategories': docData['subcategories'] ?? [],
        };
      }).toList();
      
      // order フィールドでソート（文字列型と整数型の両方に対応）
      data.sort((a, b) {
        var orderA = a['order'];
        var orderB = b['order'];
        
        // 数値型に変換して比較
        int numA = (orderA is int) ? orderA : (orderA is String) ? int.tryParse(orderA) ?? 999 : 999;
        int numB = (orderB is int) ? orderB : (orderB is String) ? int.tryParse(orderB) ?? 999 : 999;
        
        return numA.compareTo(numB);
      });
      
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoadingCategories = false;
          
          if (_selectedCategory != 'すべてのカテゴリ') {
            _updateSubcategories();
          }
        });
      }
      
    } catch (e) {
      print('❌ カテゴリの取得に失敗: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _hasError = true;
        });
      }
    }
  }

  /// カテゴリ選択時に _subcategories を更新
  void _updateSubcategories() {
    print('_updateSubcategories 呼び出し: _selectedCategory=$_selectedCategory');
    print('現在のカテゴリ一覧: ${_categories.map((c) => c['name']).toList()}');
    
    if (_selectedCategory == 'すべてのカテゴリ') {
      // すべてのカテゴリが選択されている場合、カテゴリ一覧をサブカテゴリとして表示
      if (_categories.isNotEmpty) {
        setState(() {
          _subcategories = _categories.map((c) => c['name']).toList();
          print('サブカテゴリ更新 (all選択時): $_subcategories');
        });
      } else {
        print('警告: カテゴリ一覧が空です。データロードに問題がある可能性があります。');
      }
      return;
    }

    // カテゴリ名から対応するカテゴリ情報を取得
    final cat = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {'subcategories': [], 'name': _selectedCategory},
    );
    setState(() {
      _subcategories = List<dynamic>.from(cat['subcategories'] ?? []);
      _categoryDisplayName = cat['name'] as String;
      _selectedSubcategory = null;
    });
  }

  /// Firestore クエリを構築
  Query? _buildQuery() {
    Query q = FirebaseFirestore.instance.collection('drinks');
    
    // 「すべてのカテゴリ」選択時の処理
    if (_selectedCategory == 'すべてのカテゴリ') {
      print('すべてのカテゴリモードでクエリ構築'); // デバッグログ
      
      if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty) {
        // サブカテゴリが選択されている場合はそのカテゴリのお酒を表示
        print('サブカテゴリ($_selectedSubcategory)でフィルタリング');
        q = q.where('category', isEqualTo: _selectedSubcategory);
      } else {
        // サブカテゴリが選択されていない場合はすべてのお酒を表示
        print('すべてのお酒を表示');
        // フィルタリングなし - すべてのドキュメントを取得
      }
    } 
    // 特定のカテゴリが選択されている場合
    else {
      // カテゴリ名で検索
      print('カテゴリ($_selectedCategory)でフィルタリング');
      q = q.where('category', isEqualTo: _selectedCategory);
      
      // サブカテゴリでさらにフィルタリング
      if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty) {
        print('サブカテゴリ($_selectedSubcategory)でフィルタリング');
        q = q.where('type', isEqualTo: _selectedSubcategory);
      }
    }
    
    // キーワード検索が指定されている場合
    if (_searchKeyword.isNotEmpty) {
      print('キーワード検索: $_searchKeyword');
      q = q
          .where('name', isGreaterThanOrEqualTo: _searchKeyword)
          .where('name', isLessThan: _searchKeyword + '\uf8ff');
    }
    
    // 詳細フィルターの適用
    if (_isFiltersApplied && _filterValues.isNotEmpty) {
      print('詳細フィルターを適用: $_filterValues');
      
      // 国フィルター
      if (_filterValues.containsKey('country') && 
          (_filterValues['country'] as List<String>?)?.isNotEmpty == true) {
        final countries = _filterValues['country'] as List<String>;
        print('国フィルター適用: $countries');
        // 複数の国を「OR」条件でクエリするためには配列検索を使用
        // Firestoreの制限により、単純な「IN」クエリでは不十分なケースがある
        // ドキュメントに国の配列フィールドがあることを前提とする
        if (countries.length == 1) {
          q = q.where('country', isEqualTo: countries.first);
        } else {
          // 複数の場合は「array-contains-any」を使用
          // 注意: ドキュメント構造によって適切なクエリ方法は異なる
          q = q.where('country', arrayContainsAny: countries);
        }
      }
      
      // 地域フィルター
      if (_filterValues.containsKey('region') && 
          (_filterValues['region'] as List<String>?)?.isNotEmpty == true) {
        final regions = _filterValues['region'] as List<String>;
        print('地域フィルター適用: $regions');
        if (regions.length == 1) {
          q = q.where('region', isEqualTo: regions.first);
        } else {
          q = q.where('region', arrayContainsAny: regions);
        }
      }
      
      // タイプフィルター
      if (_filterValues.containsKey('type') && 
          (_filterValues['type'] as List<String>?)?.isNotEmpty == true) {
        final types = _filterValues['type'] as List<String>;
        print('タイプフィルター適用: $types');
        if (types.length == 1) {
          q = q.where('type', isEqualTo: types.first);
        } else {
          q = q.where('type', arrayContainsAny: types);
        }
      }
      
      // ぶどう品種フィルター (ワイン用)
      if (_filterValues.containsKey('grape') && 
          (_filterValues['grape'] as List<String>?)?.isNotEmpty == true) {
        final grapes = _filterValues['grape'] as List<String>;
        print('ぶどう品種フィルター適用: $grapes');
        if (grapes.length == 1) {
          q = q.where('grape', isEqualTo: grapes.first);
        } else {
          q = q.where('grape', arrayContainsAny: grapes);
        }
      }
      
      // 味わいフィルター
      if (_filterValues.containsKey('taste') && 
          (_filterValues['taste'] as List<String>?)?.isNotEmpty == true) {
        final tastes = _filterValues['taste'] as List<String>;
        print('味わいフィルター適用: $tastes');
        if (tastes.length == 1) {
          q = q.where('taste', isEqualTo: tastes.first);
        } else {
          q = q.where('taste', arrayContainsAny: tastes);
        }
      }
      
      // ヴィンテージフィルター (ワイン用)
      if (_filterValues.containsKey('vintage') && 
          (_filterValues['vintage'] as int?) != null && 
          (_filterValues['vintage'] as int) > 0) {
        final vintage = _filterValues['vintage'] as int;
        print('ヴィンテージフィルター適用: $vintage');
        q = q.where('vintage', isEqualTo: vintage);
      }
      
      // 熟成年数フィルター
      if (_filterValues.containsKey('aging') && 
          (_filterValues['aging'] as String?) != null && 
          (_filterValues['aging'] as String) != 'すべて') {
        final aging = _filterValues['aging'] as String;
        print('熟成年数フィルター適用: $aging');
        q = q.where('aging', isEqualTo: aging);
      }
      
      // アルコール度数フィルター
      if (_filterValues.containsKey('alcoholRange')) {
        final alcoholRange = _filterValues['alcoholRange'] as RangeValues;
        print('アルコール度数フィルター適用: ${alcoholRange.start}% - ${alcoholRange.end}%');
        q = q.where('alcoholPercentage', isGreaterThanOrEqualTo: alcoholRange.start)
            .where('alcoholPercentage', isLessThanOrEqualTo: alcoholRange.end);
      }
      
      // 価格帯フィルター
      if (_filterValues.containsKey('priceRange')) {
        final priceRange = _filterValues['priceRange'] as RangeValues;
        print('価格帯フィルター適用: ¥${priceRange.start.round()} - ¥${priceRange.end.round()}');
        q = q.where('price', isGreaterThanOrEqualTo: priceRange.start.round())
            .where('price', isLessThanOrEqualTo: priceRange.end.round());
      }
    }
    
    // 並べ替え
    q = q.orderBy('name');
    
    // 結果数を制限
    return q.limit(50); // 上限を50件に増やす
  }

  /// 検索クエリを実行
  Future<void> _executeSearch() async {
    try {
      // インジケータを表示
      setState(() {
        _hasError = false;
      });

      // クエリを生成
      Query query = _buildQuery() ?? FirebaseFirestore.instance.collection('drinks').limit(50);
      
      // 常に生成されたクエリをセットして検索結果を表示
      setState(() {
        _searchSnapshot = query.snapshots();
      });

    } catch (e) {
      print('❌ 検索処理エラー: $e');
      setState(() {
        _searchSnapshot = null;
        _hasError = true;
      });
    }
  }

  void _selectCategory(String id, String name) {
    print('カテゴリ選択: id=$id, name=$name'); // デバッグログ追加
  
    if (name == 'すべてのカテゴリ') {
      // 「すべてのカテゴリ」選択時の特別処理
      setState(() {
        _selectedCategory = name;
        _categoryDisplayName = name;
      });

      // ビルドサイクル完了後にサブカテゴリ更新と検索実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // すべてのカテゴリの場合も明示的に_updateSubcategoriesを呼び出す
          _updateSubcategories(); // これにより「すべて」→他→「すべて」の流れでも正しくカテゴリが表示される
          _executeSearch();
        }
      });
    } else {
      // 通常のカテゴリ選択処理
      setState(() {
        _selectedCategory = name;
        _selectedSubcategory = null;
        _categoryDisplayName = name;
      });

      // ビルドサイクル完了後に実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSubcategories();
          _executeSearch();
        }
      });
    }
  }

  void _selectSubcategory(String? name, String? id) {
    setState(() {
      _selectedSubcategory = name; // 表示用には名前を使用
      // バックアップファイルなのでIDは保存しない
      if (name != null) {
        _searchController.clear();
        _searchKeyword = '';
      }
    });
  
    // ビルドサイクル完了後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _executeSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景色を白に設定
      backgroundColor: Theme.of(context).colorScheme.background, // 白色背景
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryTopBar(),   // カスタムヘッダー
            _buildSearchBar(),        // 検索バー
            _buildSubcategoryBar(),   // サブカテゴリ選択
            Expanded(child: _buildSearchResultsList()), // 検索結果
          ],
        ),
      ),
    );
  }

  // 画面上部のバー（左：プロフィールアイコン、中央：カテゴリ選択、右：店舗検索アイコン）
  Widget _buildCategoryTopBar() {
    return CategoryTopBar(
      categoryDisplayName: _categoryDisplayName,
      onCategoryTap: _showCategoryModal,
      onSwitchToShopSearch: _navigateToShopSearch,
    );
  }

  
  // カテゴリ選択ダイアログ
  void _showCategoryModal() {
    // デバッグ情報の出力
    print('カテゴリモーダル表示時のデータ:');
    print('  _categories数: ${_categories.length}');
    print('  _categories内容: ${_categories.map((c) => "${c['name']}(${c['id']})").toList()}');
    print('  _selectedCategory: $_selectedCategory');
  
    // カテゴリが空の場合のエラー表示
    if (_categories.isEmpty && !_isLoadingCategories) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('エラー'),
          content: const Text('カテゴリ情報が読み込まれていません。\nデータベースに接続できているか確認してください。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // カテゴリを再読み込み
                _loadCategories();
              },
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
      return;
    }

    // 通常のカテゴリモーダルを表示
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('カテゴリを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length + 1,
                itemBuilder: (_, idx) {
                  if (idx == 0) {
                    return ListTile(
                      title: const Text('すべてのカテゴリ'),
                      selected: _selectedCategory == 'すべてのカテゴリ',
                      onTap: () {
                        Navigator.pop(context);
                        _selectCategory('すべてのカテゴリ', 'すべてのカテゴリ');
                      },
                    );
                  }
                  final cat = _categories[idx - 1];
                  return ListTile(
                    title: Text(cat['name'] as String? ?? '名称なし'),
                    subtitle: Text('ID: ${cat['id']}'),
                    selected: _selectedCategory == cat['name'],
                    onTap: () {
                      Navigator.pop(context);
                      _selectCategory(cat['id'] as String, cat['name'] as String? ?? '名称なし');
                    },
                  );
                },
              ),
        ),
      ),
    );
  }
  
  // Milestone3: 検索ボックス
  Widget _buildSearchBar() {
    return DrinkSearchBar(
      controller: _searchController,
      onChanged: _onSearchChanged,
      searchKeyword: _searchKeyword,
      isEnabled: _selectedCategory == 'すべてのカテゴリ' &&
          (_selectedSubcategory == null || _selectedSubcategory!.isEmpty),
    );
  }

  void _onSearchChanged(String v) {
    setState(() => _searchKeyword = v);
  
    // ビルドサイクル完了後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _executeSearch();
      }
    });
  }

  // Milestone4: サブカテゴリバー
  Widget _buildSubcategoryBar() {
    return SubcategoryBar(
      isLoadingCategories: _isLoadingCategories,
      categories: _categories,
      subcategories: _subcategories,
      selectedCategory: _selectedCategory,
      selectedSubcategory: _selectedSubcategory,
      onCategorySelected: _selectCategory,
      onSubcategorySelected: (name, id) => _selectSubcategory(name, id),
      onShowFilterBottomSheet: _showFilterBottomSheet,
      buildSubcategoryChip: _buildSubcategoryChip,
    );
  }

  // 詳細検索ボトムシートを表示
  // この関数はコンポーネント化により不要になりました

  void _showFilterBottomSheet() {
    // 新しいフィルターコンポーネントを使用
    print('_showFilterBottomSheet: カテゴリ = $_selectedCategory');
    
    DrinkFilterBottomSheet.show(
      context: context,
      category: _selectedCategory,
      filterValues: _filterValues,
      onApplyFilters: (Map<String, dynamic> updatedFilters) {
        setState(() {
          _filterValues.clear();
          _filterValues.addAll(updatedFilters);
          _isFiltersApplied = updatedFilters.isNotEmpty;
        });
        _executeSearch();
      },
      onClearFilters: () {
        setState(() {
          _filterValues.clear();
          _isFiltersApplied = false;
        });
        _executeSearch();
      },
    );
  }
  
  Widget _buildSubcategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF000000) : const Color(0xFFFFFFFF), // 選択時黒、非選択時白
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDDDDD)), // 薄いグレー枠線
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF000000), // 選択時白、非選択時黒
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  // Milestone5＆6: 検索結果リスト
  Widget _buildSearchResultsList() {
    // 検索結果がない場合でも初期表示を行うために自動検索を実行
    if (_searchSnapshot == null && !_isInitialSearchPerformed) {
      _executeSearch();
      _isInitialSearchPerformed = true;
    }
    
    return SearchResultsList(
      searchSnapshot: _searchSnapshot,
      hasError: _hasError,
      isDebugMode: _isDebugMode,
      buildDebugPanel: _buildDebugPanel,
      categories: _categories,
    );
  }
  
  // デバッグパネルを構築（ドキュメント数を引数で受け取る）
  Widget _buildDebugPanel(int resultCount) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withOpacity(0.8), // 黒背景（半透明）
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
                onTap: () => setState(() => _isDebugMode = false),
                child: const Icon(Icons.close, color: Color(0xFFFFFFFF), size: 20), // 白アイコン
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🔍 検索: ${_selectedCategory == 'すべてのカテゴリ' ? 'すべて' : _selectedCategory}'  
            '${_selectedSubcategory != null ? ' > $_selectedSubcategory' : ''}'
            '${_searchKeyword.isNotEmpty ? ' "$_searchKeyword"' : ''}',
            style: const TextStyle(color: Color(0xFFFFFFFF)), // 白テキスト
          ),
          Text('📄 結果: $resultCount 件', style: const TextStyle(color: Color(0xFFFFFFFF))), // 白テキスト
        ],
      ),
    );
  }


}
