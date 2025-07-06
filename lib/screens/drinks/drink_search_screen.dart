import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/drink_filter_options.dart';
import '../../widgets/side_menu.dart' show showSideMenu;
import '../store/shop_list_screen.dart';

class DrinkSearchScreen extends StatefulWidget {
  static const String routeName = '/drink_search';

  const DrinkSearchScreen({Key? key}) : super(key: key);

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
  String? _errorMessage;
  bool _hasError = false;
  
  // デバッグ用の状態
  bool _isDebugMode = false;

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
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ShopListScreen(
          title: 'お店を探す',
        ),
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
        if (docData.containsKey('name')) {
          print('  nameフィールド: ${docData['name']} (型: ${docData['name'].runtimeType})');
        } else {
          print('  nameフィールド: 存在しません');
        }
        
        if (docData.containsKey('order')) {
          print('  orderフィールド: ${docData['order']} (型: ${docData['order'].runtimeType})');
        } else {
          print('  orderフィールド: 存在しません');
        }
        
        if (docData.containsKey('subcategories')) {
          print('  subcategoriesフィールド: ${docData['subcategories']} (型: ${docData['subcategories'].runtimeType})');
        } else {
          print('  subcategoriesフィールド: 存在しません');
        }
        
        // 安全にマップに変換
        return {
          'id': doc.id,
          'name': docData['name'] as String? ?? '名称なし',
          'subcategories': docData['subcategories'] ?? <String>[],
          'order': docData['order'] ?? 9999,
        };
      }).toList();
      
      // プログラム側でorderフィールドで幅び替え（文字列型と数値型の両方に対応）
      data.sort((a, b) {
        // orderフィールドの型をチェックして適切に比較
        var orderA = a['order'];
        var orderB = b['order'];
        
        // 両方とも同じ型なら直接比較
        if (orderA is num && orderB is num) {
          return orderA.compareTo(orderB);
        } else if (orderA is String && orderB is String) {
          // 文字列の場合は数値に変換してから比較
          return int.tryParse(orderA)?.compareTo(int.tryParse(orderB) ?? 9999) ?? 0;
        } else {
          // 型が異なる場合は文字列として比較
          return orderA.toString().compareTo(orderB.toString());
        }
      });
      
      print('並び替え後カテゴリ順: ${data.map((c) => "${c['name']}(順序:${c['order']})").toList()}');

      setState(() {
        _categories = data;
        _isLoadingCategories = false;
        _hasError = false; // エラー状態をリセット
      });
      
      // カテゴリが「すべて」の時、カテゴリ一覧をサブカテゴリとして表示
      if (_selectedCategory == 'すべてのカテゴリ' && data.isNotEmpty) {
        setState(() {
          // 並び替えられた順序でサブカテゴリを表示
          _subcategories = data.map((c) => c['name']).toList();
          _selectedSubcategory = null;
          print('初期ロード時: サブカテゴリ自動選択なし');
          print('サブカテゴリリスト: $_subcategories');
        });
      } else {
        _updateSubcategories();
      }
      
      // デバッグのためにロード後の状態を確認
      print('カテゴリロード完了後のステート:');
      print('  _isLoadingCategories: $_isLoadingCategories');
      print('  _categories数: ${_categories.length}');
      print('  _categories内容: ${_categories.map((c) => c['name']).toList()}');
      print('  _selectedCategory: $_selectedCategory');
      print('  _subcategories数: ${_subcategories.length}');
      print('  _subcategories内容: $_subcategories');
      
      // ビルドサイクル完了後に検索実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('ポストフレームコールバック実行中');
          print('  現在の_categories数: ${_categories.length}');
          _executeSearch();
        }
      });
    } catch (e, stackTrace) {
      print('カテゴリロードエラー: $e');
      print('スタックトレース: $stackTrace');
      
      setState(() {
        _isLoadingCategories = false;
        _hasError = true;
        _errorMessage = 'カテゴリ情報の読み込みに失敗しました: ${e.toString()}';
      });
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
  Query _buildQuery() {
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
  void _executeSearch() {
    try {
      final q = _buildQuery();
      // デバッグ用: クエリ情報をログ出力
      print('🔍 検索クエリ実行: カテゴリ=$_selectedCategory, サブカテゴリ=$_selectedSubcategory, キーワード=$_searchKeyword');
      
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _searchSnapshot = q.snapshots();
        _isDebugMode = true; // デバッグモードを有効化
      });
    } catch (e) {
      print('❌ 検索エラー: ${e.toString()}');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().contains('requires an index')
            ? 'Firestoreインデックスが必要です。Firebase Consoleで作成してください。'
            : '検索中にエラーが発生しました';
        _searchSnapshot = null;
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

  void _selectSubcategory(String? name) {
    setState(() {
      _selectedSubcategory = name;
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
      backgroundColor: Colors.white,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 左側のプロフィールアイコン
          GestureDetector(
            onTap: () {
              // サイドメニューを表示
              showSideMenu(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.grey[400]),
            ),
          ),
          
          // 中央のカテゴリ選択
          Expanded(
            child: Center(
              child: InkWell(
                onTap: _showCategoryModal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                  ),
                ),
              ),
            ),
          
          // 右側の店舗表示への切り替えアイコン
          GestureDetector(
            onTap: _navigateToShopSearch,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.storefront,
                    size: 20,
                    color: Color(0xFF525252),
                  ),
                  // 右下に青い丸と右矢印を表示 (ショップリスト画面と統一感を持たせる)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ドリンク名で検索',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _onSearchChanged,
        enabled: _selectedCategory == 'すべてのカテゴリ' &&
            (_selectedSubcategory == null || _selectedSubcategory!.isEmpty),
      ),
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
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    // 最優先：「すべてのカテゴリ」選択時は必ずカテゴリ一覧を表示
    if (_selectedCategory == 'すべてのカテゴリ') {
      print('すべてのカテゴリ選択時の特別表示を実行'); // デバッグログ
      // カテゴリが空かどうかをチェック
      if (_categories.isEmpty) {
        return const SizedBox(
          height: 50,
          child: Center(child: Text('カテゴリが読み込まれていません', style: TextStyle(color: Colors.grey))),
        );
      }
      
      // カテゴリ一覧を表示 + フィルターアイコン追加
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // フィルターアイコン (最左端に配置)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, size: 20),
                onPressed: _showFilterBottomSheet,
                tooltip: '詳細検索',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ),
            // すべてのカテゴリ選択中なので固有の表示方法
          ..._categories.map((category) {
            final name = category['name'].toString();
            final id = category['id'].toString();
            return _buildSubcategoryChip(
              label: name,
              isSelected: _selectedSubcategory == name,
              onTap: () {
                // タップ時にカテゴリも連動して切り替える
                print('下部カテゴリリストから「$name」を選択');
                _selectCategory(id, name);
              },
            );
          }),
          ],
        ),
      );
    }
    
    // 通常のサブカテゴリ表示（特定のカテゴリが選択されている場合）
    // 「すべてのカテゴリ」以外の場合のみ「サブカテゴリはありません」を表示
    if (_subcategories.isEmpty && _selectedCategory != 'すべてのカテゴリ') {
      return const SizedBox(
        height: 50,
        child: Center(child: Text('サブカテゴリはありません', style: TextStyle(color: Colors.grey))),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // フィルターアイコン (最左端に配置)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, size: 20),
              onPressed: _showFilterBottomSheet,
              tooltip: '詳細検索',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
          // サブカテゴリチップ
          _buildSubcategoryChip(
            label: 'すべて',
            isSelected: _selectedSubcategory == null,
            onTap: () => _selectSubcategory(null),
          ),
          ..._subcategories.map((s) {
            final name = s is String ? s : s['name'].toString();
            return _buildSubcategoryChip(
              label: name,
              isSelected: _selectedSubcategory == name,
              onTap: () => _selectSubcategory(name),
            );
          }),
        ],
      ),
    );
  }

  // 詳細検索用フィルター値の更新
  void _updateFilterValue(String key, dynamic value) {
    setState(() {
      _filterValues[key] = value;
      _isFiltersApplied = true;
    });
  }
  
  // 詳細検索ボトムシートを表示
  void _showFilterBottomSheet() {
    // カテゴリに対応するフィルターオプションを取得
    print('_showFilterBottomSheet: カテゴリ = $_selectedCategory');
    final filterOptions = DrinkFilterOptions.getOptionsForCategory(
      _selectedCategory,
      context,
      _filterValues,
      _updateFilterValue
    );
    if (filterOptions.isEmpty) {
      print('フィルターオプションがありません');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このカテゴリには詳細検索オプションがありません')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // ハンドル部分
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedCategory}の詳細検索',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 検索フォーム
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動的にフィルターオプションを生成
                    ...filterOptions.map((option) => _buildFilterOptionItem(option)),
                    
                    const SizedBox(height: 24),
                    
                    // 検索ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _executeSearch(); // 検索を実行
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('この条件で検索', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // リセットボタン (フィルターが適用されている場合のみ表示)
                    if (_isFiltersApplied)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterValues.clear();
                              _isFiltersApplied = false;
                            });
                            Navigator.pop(context);
                            _executeSearch(); // 検索を実行
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('フィルターをリセット', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.black54,
    );
  }
  
  // フィルターオプションのウィジェットを生成
  Widget _buildFilterOptionItem(FilterOption option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(option.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        option.buildWidget(context, _filterValues, _updateFilterValue),
        const SizedBox(height: 16),
      ],
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
            color: isSelected ? Colors.teal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  // Milestone5＆6: 検索結果リスト
  Widget _buildSearchResultsList() {
    if (_searchSnapshot == null) {
      if (_hasError) {
        return _buildErrorWidget();
      }
      return const Center(
        child: Text('検索条件を選択してください', style: TextStyle(fontSize: 16)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _searchSnapshot,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          print('❌ StreamBuilderエラー: ${snap.error}');
          return Center(
            child: Text('エラーが発生しました: ${snap.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        final docs = snap.data?.docs ?? [];
        
        // ビルド中にデバッグ情報を表示（setState呼び出しなし）
        if (_isDebugMode) {
          _updateDebugInfo(docs);
        }
        
        // ビルド中のsetState()呼び出しを完全に排除
        // 代わりにUIコンポーネントに直接ドキュメント数を渡す
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('検索結果が見つかりません',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('検索条件を変更してお試しください',
                    style: TextStyle(color: Colors.grey[600])),
                if (_isDebugMode) _buildDebugPanel(docs.length),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            if (_isDebugMode) _buildDebugPanel(docs.length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _buildDrinkItem(docs[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  // デバッグ情報を更新
  void _updateDebugInfo(List<QueryDocumentSnapshot> docs) {
    if (!_isDebugMode) return;
    
    // 先頭5件のデータ構造をログに出力
    if (docs.isNotEmpty) {
      print('📊 検索結果: ${docs.length}件');
      for (int i = 0; i < math.min(5, docs.length); i++) {
        final data = docs[i].data() as Map<String, dynamic>;
        print('📄 結果[$i]: ${data['name']} (${data['category']}/${data['type'] ?? 'N/A'})');
      }
    }
  }
  
  // デバッグパネルを構築（ドキュメント数を引数で受け取る）
  Widget _buildDebugPanel(int resultCount) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📊 デバッグ情報', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => setState(() => _isDebugMode = false),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🔍 検索: ${_selectedCategory == 'すべてのカテゴリ' ? 'すべて' : _selectedCategory}'  
            '${_selectedSubcategory != null ? ' > $_selectedSubcategory' : ''}'
            '${_searchKeyword.isNotEmpty ? ' "$_searchKeyword"' : ''}',
            style: const TextStyle(color: Colors.white),
          ),
          Text('📄 結果: $resultCount 件', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// エラー時の UI
  Widget _buildErrorWidget() {
    final needsIndex = _errorMessage?.contains('インデックスが必要') ?? false;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage ?? '検索中にエラーが発生しました',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          if (needsIndex)
            TextButton(
              onPressed: _openFirebaseConsole,
              child: const Text('Firebase Consoleを開く'),
            ),
          ElevatedButton(
            onPressed: _executeSearch,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  // Milestone5: ドリンクアイテム
  Widget _buildDrinkItem(QueryDocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    String categoryName;
    try {
      final cat = _categories.firstWhere((c) => c['id'] == d['category']);
      categoryName = cat['name'];
    } catch (_) {
      categoryName = d['category'];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/drink_detail', arguments: {'drinkId': doc.id});
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _isValidImageUrl(d['imageUrl']) ? d['imageUrl'] : 'https://placeholder.com/80x80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(Icons.local_bar, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategoryLabel(categoryName),
                        _buildSubcategoryLabel(d['type'] ?? ''),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(_formatPriceRange(d['minPrice'] ?? 0, d['maxPrice'] ?? 0)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('お気に入り機能は準備中です')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryLabel(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(fontSize: 12, color: Colors.blue[900])),
      );

  Widget _buildSubcategoryLabel(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: Colors.amber[900])),
    );
  }

  String _formatPriceRange(int min, int max) {
    if (min == 0 && max == 0) return '価格情報なし';
    if (min == max) return '¥$min';
    return '¥$min ~ ¥$max';
  }

  /// 画像URLが有効かどうかチェック
  bool _isValidImageUrl(dynamic url) {
    if (url == null) return false;
    if (url is! String) return false;
    if (url.isEmpty) return false;
    if (!url.startsWith('http')) return false;
    
    // 例として無効なURLのパターンをチェック
    if (url == 'https://example.com/ipa.jpg') return false;
    
    return true;
  }

  /// Firebase コンソールを開く（未実装ダイアログ表示）
  void _openFirebaseConsole() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Firebase コンソール'),
        content: const Text(
            '機能未実装のため手動で Firebase Console のインデックス設定を行ってください。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }
}
