import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/drink.dart';
import 'drink_detail_screen.dart';
import 'shop_list_screen.dart';

class SubcategoryScreen extends StatefulWidget {
  final Category category;

  const SubcategoryScreen({super.key, required this.category});

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  String? _selectedSubcategory;
  final List<Drink> _drinks = [];
  List<Drink> _filteredDrinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // カテゴリから最初のサブカテゴリを選択
    if (widget.category.subcategories.isNotEmpty) {
      _selectedSubcategory = widget.category.subcategories.first;
    }
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _isLoading = true;
    });

    // デバッグ情報：カテゴリのサブカテゴリを表示
    print('カテゴリ「${widget.category.name}」のサブカテゴリ: ${widget.category.subcategories.join(', ')}');

    try {
      // Firebaseのドリンクコレクションの全ドキュメントをデバッグ用に取得
      // final allDrinksSnapshot = await FirebaseFirestore.instance
      //     .collection('drinks')
      //     .limit(20)
      //     .get();
      
      // print('全ドリンクドキュメント数: ${allDrinksSnapshot.docs.length}');
      
      // 全ドキュメントのデータ構造を確認
      // for (var doc in allDrinksSnapshot.docs) {
      //   // final data = doc.data();
      //   // print('ドキュメントID: ${doc.id}, データ全体: $data');
      //   // print('カテゴリID: ${data['category']}, タイプ: ${data['type']}');
      // }
      
      // print('現在のカテゴリID: ${widget.category.id}');
      
      // Firestoreから全てのドリンクデータを取得
      // print('選択されたカテゴリID: ${widget.category.id}');
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('drinks')
          .get();
          
      // print('取得した全ドリンク数: ${snapshot.docs.length}');
      
      // カテゴリIDとそのドリンクの関係を確認
      Map<String, List<String>> categoryToDrinks = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final drinkId = doc.id;
        final categoryId = data['category'];
        if (categoryId != null) {
          if (!categoryToDrinks.containsKey(categoryId)) {
            categoryToDrinks[categoryId] = [];
          }
          categoryToDrinks[categoryId]!.add(drinkId);
        }
      }
      
      // 各カテゴリに含まれるドリンク数を表示
      categoryToDrinks.forEach((categoryId, drinkIds) {
        // print('カテゴリID: $categoryId, ドリンク数: ${drinkIds.length}');
      });
      
      // カテゴリ名に基づいてドリンクをフィルタリング
      List<DocumentSnapshot> filteredDocs = [];
      
      // カテゴリ名に基づいてフィルタリング条件を設定
      String categoryName = widget.category.name.toLowerCase();
      // print('選択されたカテゴリ名: ${widget.category.name}');
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final drinkType = (data['type'] as String?)?.toLowerCase() ?? '';
        
        bool shouldInclude = false;
        
        // カテゴリ名に基づいてフィルタリング
        if (categoryName == 'ビール' && 
            (drinkType.contains('ラガー') || drinkType.contains('ipa') || 
             drinkType.contains('スタウト') || drinkType.contains('エール'))) {
          shouldInclude = true;
        } else if (categoryName == 'ワイン' && 
                  (drinkType.contains('赤ワイン') || drinkType.contains('白ワイン') || 
                   drinkType.contains('スパークリング'))) {
          shouldInclude = true;
        } else if (categoryName == 'ウイスキー' && 
                  (drinkType.contains('シングルモルト') || drinkType.contains('ブレンデッド') || 
                   drinkType.contains('アイラ') || drinkType.contains('バーボン'))) {
          shouldInclude = true;
        }
        
        if (shouldInclude) {
          filteredDocs.add(doc);
          // print('ドリンク追加: ${data['name']}, タイプ: $drinkType');
        }
      }
      
      // print('カテゴリ ${widget.category.name} に関連するドリンク数: ${filteredDocs.length}');
      
      // フィルタリングしたドキュメントからドリンクリストを生成
      final List<Drink> fetchedDrinks = filteredDocs.map((doc) {
        return Drink.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      // print('取得したドリンク数: ${fetchedDrinks.length}');
      
      // データが取得できなかった場合はモックデータを使用
      if (fetchedDrinks.isEmpty) {
        // print('Firestoreからドリンクが見つかりませんでした。モックデータを使用します。');
        final mockDrinks = _createMockDrinks();
        
        setState(() {
          _drinks.clear();
          _drinks.addAll(mockDrinks);
          _filteredDrinks = List.from(_drinks);
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _drinks.clear();
        _drinks.addAll(fetchedDrinks);
        _filteredDrinks = List.from(_drinks);
        _isLoading = false;
      });
      
      // デバッグ情報
      // for (var drink in _drinks) {
        // print('ドリンク: ${drink.name}, タイプ: ${drink.type}');
      // }
      
    } catch (e) {
      // print('Firestoreからドリンクを取得中にエラーが発生しました: $e');
      
      // エラー時はモックデータを使用
      final mockDrinks = _createMockDrinks();
      
      setState(() {
        _drinks.clear();
        _drinks.addAll(mockDrinks);
        _filteredDrinks = List.from(_drinks);
        _isLoading = false;
      });
    }
  }

  List<Drink> _createMockDrinks() {
    if (widget.category.id == 'whisky') {
      return [
        Drink(
          id: 'macallan12',
          name: 'イチローズモルト&グレーン 20thアニバーサリー',
          categoryId: 'whisky',
          subcategoryId: 'japanese',
          type: 'japanese',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: true,
        ),
        Drink(
          id: 'hakushu',
          name: '獺祭 磨き その先へ',
          categoryId: 'whisky',
          subcategoryId: 'japanese',
          type: 'japanese',
          imageUrl: 'https://images.unsplash.com/photo-1579619168343-e9633bad7e74',
          price: 3200,
          isPR: true,
        ),
        Drink(
          id: 'portcharlotte',
          name: 'モンプロポス エスパディン',
          categoryId: 'whisky',
          subcategoryId: 'islay',
          type: 'islay',
          imageUrl: 'https://images.unsplash.com/photo-1569529465841-dfecdab7503b',
          price: 3200,
          isPR: true,
        ),
        Drink(
          id: 'hakushu12',
          name: '白州 NV',
          categoryId: 'whisky',
          subcategoryId: 'japanese',
          type: 'japanese',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: false,
        ),
        Drink(
          id: 'dalmore',
          name: 'デイロン トレヴィユー VSOP マルティニーク',
          categoryId: 'whisky',
          subcategoryId: 'single_malt',
          type: 'single_malt',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: false,
        ),
        Drink(
          id: 'yamazaki',
          name: 'イチローズモルト 20th アニバーサリー',
          categoryId: 'whisky',
          subcategoryId: 'japanese',
          type: 'japanese',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: false,
        ),
        Drink(
          id: 'michters',
          name: 'ミシク アイリッシュ ジン',
          categoryId: 'whisky',
          subcategoryId: 'bourbon',
          type: 'bourbon',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: false,
        ),
        Drink(
          id: 'ichiros',
          name: 'イチローズ・モルト&グレーン・ホワイトラベル',
          categoryId: 'whisky',
          subcategoryId: 'japanese',
          type: 'japanese',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: false,
        ),
        Drink(
          id: 'yamazaki18',
          name: '山崎 18年',
          categoryId: 'whisky',
          subcategoryId: 'japanese',
          type: 'japanese',
          imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8',
          price: 3200,
          isPR: false,
        ),
      ];
    }
    return [];
  }

  void _selectSubcategory(String subcategory) {
    // print('選択前のサブカテゴリ: $_selectedSubcategory');
    // print('タップされたサブカテゴリ: $subcategory');
    // print('現在のドリンク数: ${_drinks.length}');
    
    // ドリンクのタイプを確認
    // for (var drink in _drinks) {
    //   // print('ドリンク: ${drink.name}, タイプ: ${drink.type}, サブカテゴリ: ${drink.subcategoryId}');
    // }
    
    setState(() {
      if (_selectedSubcategory == subcategory) {
        // 同じものをタップしたら選択解除
        _selectedSubcategory = null;
        _filteredDrinks = List.from(_drinks); // フィルタ解除
        // print('フィルタ解除: 全てのドリンクを表示');
      } else {
        _selectedSubcategory = subcategory;
        // サブカテゴリでフィルタリング
        _filteredDrinks = _drinks.where((drink) => drink.type == subcategory).toList();
        // print('フィルタ適用: $subcategory のドリンクのみ表示');
      }
      
      // print('フィルタリング後のドリンク数: ${_filteredDrinks.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            // お店一覧画面に遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopListScreen(
                  categoryId: widget.category.id,
                  title: '${widget.category.name}のお店',
                ),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('お酒を表示', style: TextStyle(fontSize: 16)),
              SizedBox(width: 4),
              Icon(Icons.refresh, size: 16),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリ名
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              widget.category.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // サブカテゴリチップ
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: widget.category.subcategories.map((subcategory) {
                final isSelected = _selectedSubcategory == subcategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_formatSubcategoryName(subcategory)),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) => _selectSubcategory(subcategory),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // エリア選択と並び替え
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // エリア選択
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        const Text('エリア 全国'),
                      ],
                    ),
                  ),
                ),
                
                // 並び替え
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 16),
                      const SizedBox(width: 4),
                      const Text('並び替え 標準'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // ドリンクリスト - 1行3列のグリッドレイアウト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDrinks.isEmpty
                    ? const Center(child: Text('お酒が見つかりませんでした'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 1行に3アイテム表示
                          childAspectRatio: 0.55, // カードの高さを調整
                          crossAxisSpacing: 10, // 水平方向の間隔
                          mainAxisSpacing: 16, // 垂直方向の間隔
                        ),
                        itemCount: _filteredDrinks.length,
                        itemBuilder: (context, index) {
                          final drink = _filteredDrinks[index];
                          return _buildDrinkItem(context, drink);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkItem(BuildContext context, Drink drink) {
    // 表示する価格を決定
    final displayPrice = drink.originalPrice > 0 ? drink.originalPrice : drink.price;
    
    // 価格をフォーマットする関数
    String formatPrice(double price) {
      if (price <= 0) return '';
      final formatter = NumberFormat('#,###');
      return '¥${formatter.format(price)}~';
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(2),
      child: InkWell(
        onTap: () {
          // ドリンク詳細画面に遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DrinkDetailScreen(drinkId: drink.id),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ドリンク画像のコンテナ
            SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ドリンク画像（2:3の縦横比）
                  AspectRatio(
                    aspectRatio: 2/3, // 仕様通りの縦横比
                    child: Image.network(
                      drink.imageUrl, // drinksコレクションのimageURLフィールドを参照
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // print('画像読み込みエラー: $error');
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  
                  // お気に入りアイコン
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((255 * 0.1).round()),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.bookmark_border,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  
                  // PRラベル
                  if (drink.isPR)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black,
                        child: const Text(
                          'PR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // ドリンク名と価格のコンテナ
            SizedBox(
              width: double.infinity,
              height: 30, // 高さをさらに小さく調整
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ドリンク名（1行で省略、最大25文字）
                    Text(
                      drink.name.length > 25 ? '${drink.name.substring(0, 25)}...' : drink.name,
                      style: const TextStyle(
                        fontSize: 10, // フォントサイズを小さく設定
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2), // 間隔を小さく
                    
                    // 価格表示（中央揃え）
                    if (displayPrice > 0)
                      Text(
                        formatPrice(displayPrice),
                        style: const TextStyle(
                          fontSize: 10, // フォントサイズをさらに小さく
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // サブカテゴリ名を日本語に変換
  String _formatSubcategoryName(String name) {
    switch (name) {
      case 'islay':
        return 'アイラ';
      case 'single_malt':
        return 'シングルモルト';
      case 'japanese':
        return 'ジャパニーズ';
      case 'bourbon':
        return 'バーボン';
      case 'scotch':
        return 'スコッチ';
      default:
        return name;
    }
  }
}
