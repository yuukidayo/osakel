import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DrinkSearchScreen extends StatefulWidget {
  static const String routeName = '/drink_search';
  
  const DrinkSearchScreen({Key? key}) : super(key: key);

  @override
  State<DrinkSearchScreen> createState() => _DrinkSearchScreenState();
}

class _DrinkSearchScreenState extends State<DrinkSearchScreen> {
  // Category state management
  String _selectedCategory = 'all';
  String? _selectedSubcategory;
  String _categoryDisplayName = 'すべてのカテゴリ';
  List<Map<String, dynamic>> _categories = [];
  List<String> _subcategories = [];
  bool _isLoadingCategories = true;
  
  // Search state management
  String _searchKeyword = '';
  
  // Query results
  bool _isLoadingResults = false;
  List<QueryDocumentSnapshot> _searchResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Milestone 2: Load category data from Firestore
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
      
      // Process categories data
      final categoriesData = categoriesSnapshot.docs.map((doc) {
        print('カテゴリデータ: ${doc.id} - ${doc.data()}'); // カテゴリデータの内容を確認
        return {
          'id': doc.id,
          'name': doc['name'] as String,
          'subcategories': doc['subcategories'] ?? <String>[],
        };
      }).toList();
      
      setState(() {
        _categories = categoriesData;
        _isLoadingCategories = false;
        
        // Initially show all categories as "subcategories" when in "all" mode
        _updateSubcategories();
      });
      
      print('Loaded ${categoriesData.length} categories from Firestore');
      for (var cat in categoriesData) {
        var subcats = cat['subcategories'];
        print('カテゴリ: ${cat['name']} - サブカテゴリ: $subcats (${subcats.runtimeType})');
      }
      
      // Load initial results
      _executeSearch();
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = 'カテゴリ情報の読み込みに失敗しました';
      });
    }
  }

  // カテゴリ変更時にサブカテゴリを更新
  void _updateSubcategories() {
    print('カテゴリ更新: _selectedCategory = $_selectedCategory');
    
    if (_selectedCategory == 'all') {
      // 「すべてのカテゴリ」選択時はカテゴリ一覧を表示
      setState(() {
        _subcategories = _categories.map((cat) => cat['name'] as String).toList();
        _categoryDisplayName = 'すべてのカテゴリ';
        print('すべてのカテゴリモード - カテゴリ一覧に更新: ${_subcategories.length}件');
      });
    } else {
      // 特定のカテゴリ選択時は、そのカテゴリに紐づくサブカテゴリを表示
      print('カテゴリ一覧: ${_categories.map((c) => c['id']).toList()}');
      final selectedCategoryData = _categories.firstWhere(
        (cat) => cat['id'] == _selectedCategory,
        orElse: () {
          print('選択したカテゴリが見つかりません: $_selectedCategory');
          return {'id': 'all', 'name': 'すべてのカテゴリ', 'subcategories': <String>[]};
        },
      );
      
      print('選択したカテゴリデータ: $selectedCategoryData');
      final subcategories = selectedCategoryData['subcategories'];
      print('サブカテゴリデータ: $subcategories (${subcategories.runtimeType})');
      
      List<String> subcategoryList = [];
      try {
        if (subcategories != null) {
          if (subcategories is List) {
            subcategoryList = List<String>.from(subcategories);
          }
        }
      } catch (e) {
        print('サブカテゴリ処理エラー: $e');
      }
      
      setState(() {
        _subcategories = subcategoryList;
        _categoryDisplayName = selectedCategoryData['name'] as String;
        _selectedSubcategory = null; // サブカテゴリ選択をリセット
        print('カテゴリ「${_categoryDisplayName}」のサブカテゴリを更新: ${_subcategories.length}件 - $subcategoryList');
      });
    }
  }

  // Milestone 3: Build the Firestore query
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('drinks');
    
    // Apply category filter
    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    // Apply subcategory filter
    if (_selectedSubcategory != null) {
      query = query.where('subcategory', isEqualTo: _selectedSubcategory);
    }
    
    // Apply keyword search if provided
    if (_searchKeyword.isNotEmpty) {
      // Japanese name search (prefix search)
      query = query
        .where('nameJa', isGreaterThanOrEqualTo: _searchKeyword)
        .where('nameJa', isLessThan: _searchKeyword + '\uf8ff');
      
      // Note: For English name search, we would need to create a separate query and merge results
      // This would be a more complex implementation using multiple queries or Cloud Functions
    }
    
    return query.limit(20); // Limit to 20 results for performance
  }

  // Execute search with current filters
  Future<void> _executeSearch() async {
    setState(() {
      _isLoadingResults = true;
      _errorMessage = null;
    });
    
    try {
      final query = _buildQuery();
      final querySnapshot = await query.get();
      
      setState(() {
        _searchResults = querySnapshot.docs;
        _isLoadingResults = false;
      });
      
      print('Found ${querySnapshot.docs.length} drinks matching query');
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _errorMessage = '検索中にエラーが発生しました';
        _isLoadingResults = false;
      });
    }
  }

  void _selectCategory(String categoryId, String categoryName) {
    setState(() {
      _selectedCategory = categoryId;
      _categoryDisplayName = categoryName;
      _selectedSubcategory = null; // Reset subcategory when changing category
    });
    
    _updateSubcategories(); // カテゴリに紐づくサブカテゴリを更新
    _executeSearch(); // 検索結果を更新
  }

  // サブカテゴリ選択処理
  void _selectSubcategory(String? subcategory) {
    print('サブカテゴリを選択: $subcategory');
    setState(() {
      _selectedSubcategory = subcategory;
    });
    
    _executeSearch(); // 検索結果を更新
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お酒検索'),
        automaticallyImplyLeading: false, // No back button for the main screen
      ),
      body: Column(
        children: [
          // Milestone 2: Category switcher bar
          _buildCategoryTopBar(),
          
          // Milestone 3: Search box
          _buildSearchBox(),
          
          // Milestone 4: Subcategory bar
          _buildSubcategoryBar(),
          
          // Divider
          const Divider(height: 1),
          
          // Milestone 5 & 6: Results area with loading/error states
          Expanded(
            child: _buildResultsArea(),
          ),
        ],
      ),
    );
  }

  // Milestone 2: Top bar with category selector
  Widget _buildCategoryTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[50],
      child: Row(
        children: [
          // "すべてのカテゴリ" button
          ElevatedButton(
            onPressed: () => _showCategoryModal(),
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
              mainAxisSize: MainAxisSize.min,
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

  // Show category selection modal
  void _showCategoryModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カテゴリを選択'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length + 1, // +1 for "All" option
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  // "All categories" option
                  return ListTile(
                    title: const Text('すべてのカテゴリ'),
                    selected: _selectedCategory == 'all',
                    onTap: () {
                      Navigator.pop(context);
                      print('「すべてのカテゴリ」を選択');
                      _selectCategory('all', 'すべてのカテゴリ');
                    },
                  );
                } else {
                  final category = _categories[index - 1];
                  final categoryId = category['id'] as String;
                  final categoryName = category['name'] as String;
                  return ListTile(
                    title: Text(categoryName),
                    selected: _selectedCategory == categoryId,
                    onTap: () {
                      Navigator.pop(context);
                      print('カテゴリを選択: $categoryName (ID: $categoryId)');
                      _selectCategory(categoryId, categoryName);
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Milestone 3: Search box
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'キーワードで検索',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
          });
          _executeSearch(); // Real-time search as user types
        },
      ),
    );
  }

  // Milestone 4: Subcategory bar
  Widget _buildSubcategoryBar() {
    if (_isLoadingCategories) {
      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    }
    
    // サブカテゴリがない場合の処理
    if (_subcategories.isEmpty) {
      return const SizedBox(height: 50, child: Center(
        child: Text('サブカテゴリはありません', style: TextStyle(color: Colors.grey)),
      ));
    }
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _subcategories.length + 1, // +1 for 'All' option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            return _buildSubcategoryChip(
              'すべて',
              _selectedSubcategory == null,
              () => _selectSubcategory(null),
            );
          } else {
            final subcategory = _subcategories[index - 1];
            
            // 「すべてのカテゴリ」モード時はカテゴリ名をタップするとそのカテゴリに切り替える
            if (_selectedCategory == 'all') {
              // カテゴリ名からカテゴリIDを検索
              final categoryData = _categories.firstWhere(
                (cat) => cat['name'] == subcategory,
                orElse: () => {'id': 'all', 'name': subcategory},
              );
              final categoryId = categoryData['id'] as String;
              
              return _buildSubcategoryChip(
                subcategory,
                false,
                () {
                  print('カテゴリ切り替え: $subcategory (ID: $categoryId)');
                  _selectCategory(categoryId, subcategory);
                },
              );
            } else {
              // 通常のサブカテゴリ選択
              return _buildSubcategoryChip(
                subcategory,
                _selectedSubcategory == subcategory,
                () => _selectSubcategory(subcategory),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildSubcategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Milestone 5 & 6: Results area
  Widget _buildResultsArea() {
    // Show loading indicator
    if (_isLoadingResults) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Show error message if any
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _executeSearch,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }
    
    // Show empty state
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('検索結果が見つかりませんでした'),
            const SizedBox(height: 8),
            Text(
              '検索条件を変更してお試しください',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Show results list
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildDrinkItem(_searchResults[index]),
    );
  }

  // Milestone 5: Drink list item
  Widget _buildDrinkItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final drinkId = doc.id;
    
    // Extract drink data
    final nameJa = data['nameJa'] as String? ?? '名称なし';
    final nameEn = data['nameEn'] as String? ?? '';
    final category = data['category'] as String? ?? '';
    final subcategory = data['subcategory'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    
    // Price range
    final minPrice = data['minPrice'] as int? ?? 0;
    final maxPrice = data['maxPrice'] as int? ?? 0;
    final priceRange = _formatPriceRange(minPrice, maxPrice);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/drink_detail',
          arguments: {'drinkId': drinkId},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.local_bar, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.local_bar, color: Colors.grey),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Drink details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      nameJa,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nameEn.isNotEmpty)
                      Text(
                        nameEn,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    
                    // Category and subcategory
                    if (category.isNotEmpty || subcategory.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: [
                          if (category.isNotEmpty)
                            _buildCategoryLabel(category),
                          if (subcategory.isNotEmpty)
                            _buildCategoryLabel(subcategory, isSubcategory: true),
                        ],
                      ),
                    const SizedBox(height: 8),
                    
                    // Price range
                    Text(
                      priceRange,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bookmark button
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  // Bookmark functionality would be implemented here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('お気に入り機能は準備中です')),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for price formatting
  String _formatPriceRange(int minPrice, int maxPrice) {
    if (minPrice == 0 && maxPrice == 0) {
      return '価格情報なし';
    }
    
    if (minPrice == maxPrice) {
      return '¥${minPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")}';
    }
    
    final minFormatted = minPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    final maxFormatted = maxPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    
    return '¥$minFormatted ～ ¥$maxFormatted';
  }

  // Helper for category label
  Widget _buildCategoryLabel(String label, {bool isSubcategory = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSubcategory ? Colors.blue[50] : Colors.teal[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isSubcategory ? Colors.blue[700] : Colors.teal[700],
        ),
      ),
    );
  }
}