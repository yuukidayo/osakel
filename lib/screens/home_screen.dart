import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/drink.dart';
import '../models/category.dart';
import '../models/shop.dart';
import 'dart:developer' as developer;
import 'drink_detail_screen.dart';
import 'store_detail_screen.dart';
import '../widgets/side_menu.dart' show showSideMenu;

// 画面の種類を表す列挙型
enum ScreenType { drink, shop }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 現在表示している画面の種類
  ScreenType _currentScreen = ScreenType.drink;
  
  // お酒検索画面関連の状態
  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<Drink> _drinks = [];
  List<Drink> _filteredDrinks = [];
  bool _isLoading = false;
  
  // お店検索画面関連の状態
  final List<Shop> _shops = [];
  bool _isLoadingShops = false;
  String _selectedFilter = 'バー';
  final List<String> _filters = ['バー', 'ひとり歓迎', '試飲可', '静か'];

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
  

  // カテゴリデータを読み込む
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('displayOrder')
          .get();

      setState(() {
        _categories = categorySnapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading categories: $e');
    }
  }

  // カテゴリが選択されたときの処理
  void _onCategorySelected(String categoryId) {
    setState(() {
      // 同じカテゴリが選択された場合は選択をクリア
      _selectedCategoryId = _selectedCategoryId == categoryId ? null : categoryId;
      _drinks = [];
      _filteredDrinks = [];
    });

    if (_selectedCategoryId != null) {
      _loadDrinksByCategory(_selectedCategoryId!);
    }
  }

  // カテゴリに基づいてお酒データを読み込む
  Future<void> _loadDrinksByCategory(String categoryId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drinkSnapshot = await FirebaseFirestore.instance
          .collection('drinks')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      setState(() {
        _drinks = drinkSnapshot.docs
            .map((doc) => Drink.fromMap(doc.id, doc.data()))
            .toList();
        _filteredDrinks = _drinks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error loading drinks: $e');
    }
  }
  
  // 検索機能
  void _filterDrinks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrinks = _drinks;
      } else {
        _filteredDrinks = _drinks
            .where((drink) =>
                drink.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // カテゴリトップバーの構築
  Widget _buildCategoryTopBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: Row(
        children: [
          // メニューボタン
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              showSideMenu(context);
            },
          ),
          // カテゴリ選択ドロップダウン
          Expanded(
            child: GestureDetector(
              onTap: () {
                // カテゴリ選択ダイアログの表示など
                _showCategoryDialog();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // カテゴリ選択テキスト
                    Row(
                      children: [
                        Text(
                          _selectedCategoryId == null
                              ? 'カテゴリを選択'
                              : _categories
                                  .firstWhere((cat) => cat.id == _selectedCategoryId)
                                  .name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                    // 画面切り替えアイコン
                    _buildToggleIcon(),
                  ],
                ),
              ),
            ),
          ),
          
          // 画面切り替えボタン（これは共通アプリバーに統合するため、ここでは非表示）
          const SizedBox(width: 40),
        ],
      ),
    );
  }
  
  // カテゴリ選択ダイアログの表示
  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カテゴリを選択'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((category) {
                return ListTile(
                  title: Text(category.name),
                  selected: _selectedCategoryId == category.id,
                  onTap: () {
                    _onCategorySelected(category.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryId = null;
                  _drinks = [];
                  _filteredDrinks = [];
                });
                Navigator.pop(context);
              },
              child: const Text('クリア'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  // UI関連ヘルパーメソッド
  Widget _buildCategoryLabel(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFBBDEFB), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF0D47A1))),
      );

  Widget _buildTypeLabel(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFFECB3), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFFF6F00))),
    );
  }

  String _formatPrice(double price) {
    if (price == 0) return '価格情報なし';
    return '¥${price.toInt()}';
  }

  // URLが有効かチェック
  bool _isValidImageUrl(String? url) {
    if (url == null) return false;
    if (url.isEmpty) return false;
    return url.startsWith('http');
  }

  // お酒検索画面のコンテンツ
  Widget _buildDrinkSearchContent() {
    return Column(
      children: [
        // カテゴリ選択トップバー
        _buildCategoryTopBar(),
        
        // 検索バー
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'お酒を検索...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _filterDrinks('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFEEEEEE),
            ),
            onChanged: _filterDrinks,
          ),
        ),
        
        // お酒リスト
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedCategoryId == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.category, size: 48, color: Color(0xFFBDBDBD)),
                          const SizedBox(height: 16),
                          const Text('カテゴリを選択してください',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : _filteredDrinks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: Color(0xFFBDBDBD)),
                              const SizedBox(height: 16),
                              const Text('該当するお酒が見つかりません',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredDrinks.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final drink = _filteredDrinks[index];
                            // カテゴリ名を取得
                            final categoryName = _getCategoryName(drink.categoryId);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DrinkDetailScreen(drinkId: drink.id),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 画像
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _isValidImageUrl(drink.imageUrl)
                                            ? CachedNetworkImage(
                                                imageUrl: drink.imageUrl,
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
                                                  color: const Color(0xFFEEEEEE),
                                                  child: const Icon(Icons.local_bar, color: Color(0xFFBDBDBD)),
                                                ),
                                              )
                                            : Container(
                                                width: 80,
                                                height: 80,
                                                color: const Color(0xFFEEEEEE),
                                                child: const Icon(Icons.local_bar, color: Color(0xFFBDBDBD)),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 詳細情報
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(drink.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                _buildCategoryLabel(categoryName),
                                                _buildTypeLabel(drink.type),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF1B8D3F)),
                                                const SizedBox(width: 4),
                                                Text(_formatPrice(drink.price)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // お気に入りボタン
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
                          },
                        ),
        ),
      ],
    );
  }
  
  // カテゴリIDからカテゴリ名を取得するヘルパーメソッド
  String _getCategoryName(String categoryId) {
    try {
      final category = _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => Category(
          id: 'unknown',
          name: '不明カテゴリ',
          order: 999,
          imageUrl: '',
          subcategories: [],
        ),
      );
      return category.name;
    } catch (e) {
      developer.log('Error getting category name: $e');
      return '不明カテゴリ';
    }
  }

  // 店舗データを読み込む
  Future<void> _loadShops() async {
    setState(() {
      _isLoadingShops = true;
    });

    try {
      // デフォルトで全ての店舗を取得
      developer.log('すべてのお店を取得します');
      
      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .limit(20) // 最初は20件に制限
          .get();
          
      List<Shop> shops = [];
      for (var doc in shopsSnapshot.docs) {
        final shop = Shop.fromFirestore(doc);
        shops.add(shop);
      }
      
      setState(() {
        _shops.clear();
        _shops.addAll(shops);
        _isLoadingShops = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingShops = false;
      });
      developer.log('Error loading shops: $e');
    }
  }

  // お店検索画面用のフィルターチップを構築
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : '';
                });
                // フィルターに基づいてデータ再取得などの処理を追加予定
              },
              selectedColor: const Color(0xFFB2DFDB),
              backgroundColor: const Color(0xFFEEEEEE),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 店舗アイテムの構築
  Widget _buildShopItem(Shop shop) {
    String? imageUrl;
    if (shop.imageURL != null && shop.imageURL!.isNotEmpty) {
      imageUrl = shop.imageURL;
    } else if (shop.imageUrl != null && shop.imageUrl!.isNotEmpty) {
      imageUrl = shop.imageUrl;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(storeId: shop.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗名と詳細
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 店舗名
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 店舗タイプと場所
                  Row(
                    children: [
                      const Text('バー・',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(shop.address,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 店舗画像
            SizedBox(
              height: 150,
              width: double.infinity,
              child: (imageUrl != null)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE0E0E0),
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            
            // 店舗情報（住所、営業時間）
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 住所と距離
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.address} ${shop.distance != null ? '${shop.distance}m' : ''}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 営業時間
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '営業開始 ${shop.openTime ?? '17:00'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // お店検索画面のコンテンツ
  Widget _buildShopSearchContent() {
    // 初回表示時に店舗データを取得
    if (_shops.isEmpty && !_isLoadingShops) {
      _loadShops();
    }
    
    return Column(
      children: [
        // フィルターチップ
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.white,
          child: _buildFilterChips(),
        ),
        
        // リスト表示
        Expanded(
          child: _isLoadingShops
              ? const Center(child: CircularProgressIndicator())
              : _shops.isEmpty
                  ? const Center(child: Text('店舗が見つかりません'))
                  : ListView.builder(
                      itemCount: _shops.length,
                      itemBuilder: (context, index) {
                        return _buildShopItem(_shops[index]);
                      },
                    ),
        ),
      ],
    );
  }

  // 切り替えアイコンを表示するWidget
  Widget _buildToggleIcon() {
    return IconButton(
      icon: Icon(
        _currentScreen == ScreenType.drink
            ? Icons.store
            : Icons.local_drink,
        color: Colors.teal,
      ),
      onPressed: () {
        setState(() {
          _currentScreen = _currentScreen == ScreenType.drink
              ? ScreenType.shop
              : ScreenType.drink;
        });
      },
      tooltip: _currentScreen == ScreenType.drink
          ? 'お店検索に切り替え'
          : 'お酒検索に切り替え',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _currentScreen == ScreenType.drink
            ? _buildDrinkSearchContent()
            : _buildShopSearchContent(),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'OSAKEL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu),
              title: const Text('サイドメニュー'),
              onTap: () {
                showSideMenu(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
