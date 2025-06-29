import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

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

  /// マイルストーン2：Firestore からカテゴリをロード
  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('categories').get();
      final data = snap.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'] as String,
          'subcategories': doc['subcategories'] ?? <String>[],
        };
      }).toList();

      setState(() {
        _categories = data;
        _isLoadingCategories = false;
      });
      
      // カテゴリが「すべて」の時、カテゴリ一覧をサブカテゴリとして表示
      if (_selectedCategory == 'すべてのカテゴリ' && data.isNotEmpty) {
        setState(() {
          _subcategories = data.map((c) => c['name']).toList();
          // 自動選択しない - デフォルトはnull
          _selectedSubcategory = null;
          print('初期ロード時: サブカテゴリ自動選択なし');
        });
      } else {
        _updateSubcategories();
      }
      
      // ビルドサイクル完了後に検索実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _executeSearch();
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _hasError = true;
        _errorMessage = 'カテゴリ情報の読み込みに失敗しました';
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
      
      // キーワード検索が指定されている場合
      if (_searchKeyword.isNotEmpty) {
        print('キーワード検索: $_searchKeyword');
        q = q
            .where('name', isGreaterThanOrEqualTo: _searchKeyword)
            .where('name', isLessThan: _searchKeyword + '\uf8ff');
      }
      
      // 並べ替え
      q = q.orderBy('name');
    } 
    // 特定のカテゴリが選択されている場合
    else {
      // カテゴリ名で検索
      q = q.where('category', isEqualTo: _selectedCategory);
      
      // サブカテゴリでさらにフィルタリング
      if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty) {
        q = q.where('type', isEqualTo: _selectedSubcategory);
      }
      
      // 並べ替え
      q = q.orderBy('name');
    }
    
    // 結果数を制限
    return q.limit(20);
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
      appBar: AppBar(
        title: const Text('お酒検索'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildCategoryTopBar(),   // Milestone2
          _buildSearchBar(),        // Milestone3
          _buildSubcategoryBar(),   // Milestone4
          Expanded(child: _buildSearchResultsList()), // Milestone5 & 6
        ],
      ),
    );
  }

  // Milestone2: カテゴリトップバー
  Widget _buildCategoryTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _showCategoryModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Text(_categoryDisplayName),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // カテゴリ選択ダイアログ
  void _showCategoryModal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('カテゴリを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
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
                title: Text(cat['name']),
                selected: _selectedCategory == cat['name'],
                onTap: () {
                  Navigator.pop(context);
                  _selectCategory(cat['id'], cat['name']);
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
      
      // カテゴリ一覧を表示
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // すべてのカテゴリ選択中なので固有の表示方法
            ..._categories.map((category) {
              final name = category['name'].toString();
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
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
