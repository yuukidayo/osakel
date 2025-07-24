import 'package:flutter/material.dart';
import '../models/category.dart';
import '../../core/services/category_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/side_menu.dart';
import './subcategory_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firebaseからカテゴリデータを取得
      final categories = await _categoryService.getCategories();
      
      // データが取得できなかった場合はモックデータを使用
      if (categories.isEmpty) {
        debugPrint('No categories found in Firestore, using mock data');
        final mockCategories = _categoryService.getMockCategories();
        setState(() {
          _categories = mockCategories;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      debugPrint('Loaded ${categories.length} categories from Firestore');
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // エラー時はモックデータを使用
      final mockCategories = _categoryService.getMockCategories();
      setState(() {
        _categories = mockCategories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 現在のユーザー情報を取得
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'ユーザー';
    final profileImageUrl = user?.photoURL;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        onProfileTap: () {
          showSideMenu(
            context,
            userName: userName,
            profileImage: profileImageUrl,
            notificationCount: 2, // 通知数は実際のデータに置き換え可能
          );
        },
      ),
      drawer: SideMenu(
        userName: user?.displayName ?? 'ゲスト',
        onClose: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: _categories.isEmpty
                  ? const Center(child: Text('カテゴリがありません'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 検索バー
                          Container(
                            margin: const EdgeInsets.only(bottom: 24.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'お酒名・キーワード を入力',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                              ),
                              onSubmitted: (value) {
                                // 検索機能の実装（今後の課題）
                              },
                            ),
                          ),
                          
                          // カテゴリータイトル
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'カテゴリーを選ぶ',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // カテゴリーグリッド
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return _buildCategoryCard(context, category);
                            },
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    // カテゴリに応じたアイコンを選択
    IconData categoryIcon = Icons.local_bar;
    if (category.name.contains('ビール')) {
      categoryIcon = Icons.sports_bar;
    } else if (category.name.contains('ワイン')) {
      categoryIcon = Icons.wine_bar;
    } else if (category.name.contains('ウイスキー') || category.name.contains('ウィスキー')) {
      categoryIcon = Icons.liquor;
    } else if (category.name.contains('日本酒') || category.name.contains('sake')) {
      categoryIcon = Icons.rice_bowl;
    } else if (category.name.contains('カクテル')) {
      categoryIcon = Icons.local_bar;
    } else if (category.name.contains('焼酎')) {
      categoryIcon = Icons.liquor;
    }
    
    // サブカテゴリの数を表示
    final subcategoryCount = category.subcategories.length;
    final subcategoryText = subcategoryCount > 0
        ? '$subcategoryCount ${subcategoryCount == 1 ? 'Type' : 'Types'}'
        : 'Coming soon';
    
    return Card(
      elevation: 1.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[200]!, width: 1.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoryScreen(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // カテゴリアイコン
              Icon(
                categoryIcon,
                size: 40.0,
                color: Colors.black87,
              ),
              const SizedBox(height: 16.0),
              // カテゴリ名
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              // サブカテゴリ数
              Text(
                subcategoryText,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
