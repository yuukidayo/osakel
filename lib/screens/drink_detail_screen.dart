import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drink.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../models/shop.dart';
import '../services/firestore_service.dart';

import 'pro_comments_screen.dart';

class DrinkDetailScreen extends StatefulWidget {
  final String drinkId;

  const DrinkDetailScreen({super.key, required this.drinkId});

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  Drink? _drink;
  List<Map<String, dynamic>> _proCommentsWithUserData = [];
  int _totalProComments = 0;
  String? _countryName; // 国名を保存するフィールドを追加
  Map<String, dynamic>? _drinkData; // 元のFirestoreデータを保存

  @override
  void initState() {
    super.initState();
    _loadDrinkDetails();
  }

  Future<void> _loadDrinkDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ドリンク情報を取得
      final drinkDoc = await FirebaseFirestore.instance
          .collection('drinks')
          .doc(widget.drinkId)
          .get();

      if (drinkDoc.exists) {
        final drinkData = drinkDoc.data() as Map<String, dynamic>;
        setState(() {
          _drink = Drink.fromMap(widget.drinkId, drinkData);
          _drinkData = drinkData;
        });

        // 国名を取得（countryRefが存在する場合は優先、なければcountryフィールドを使用）
        final countryRef = drinkData['countryRef'];
        if (countryRef != null) {
          // countryRefが存在する場合は参照先から国名を取得
          final countryDoc = await countryRef.get();
          if (countryDoc.exists) {
            setState(() {
              _countryName = countryDoc.data()!['name'] as String?;
            });
          }
        } else {
          // countryRefが存在しない場合は既存のcountryフィールドを使用
          final countryString = drinkData['country'] as String?;
          if (countryString != null && countryString.isNotEmpty) {
            setState(() {
              _countryName = countryString;
            });
          }
        }

        // プロユーザーのコメントを取得
        await _loadProComments();
      } else {
        print('ドリンクが見つかりません: ${widget.drinkId}');
      }
    } catch (e) {
      print('ドリンク詳細の取得中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadProComments() async {
    try {
      // プロユーザーのコメントを取得
      final comments = await _firestoreService.getProCommentsForDrink(widget.drinkId);
      _totalProComments = comments.length;
      
      // 最大5件のコメントを表示
      final limitedComments = comments.take(5).toList();
      
      // コメントごとにユーザー情報と店舗情報を取得
      final commentsWithUserData = <Map<String, dynamic>>[];
      
      for (var comment in limitedComments) {
        final user = await _firestoreService.getUserById(comment.userId);
        Shop? shop;
        
        // ユーザーが店舗と関連付けられている場合、店舗情報も取得
        if (user != null && user.shopId != null) {
          final shopDoc = await FirebaseFirestore.instance
              .collection('shops')
              .doc(user.shopId)
              .get();
          
          if (shopDoc.exists) {
            shop = Shop.fromMap(
              shopDoc.id, 
              shopDoc.data() as Map<String, dynamic>
            );
          }
        }
        
        commentsWithUserData.add({
          'comment': comment,
          'user': user,
          'shop': shop,
        });
      }
      
      setState(() {
        _proCommentsWithUserData = commentsWithUserData;
      });
    } catch (e) {
      print('プロコメントの取得中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('戻る', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {
              // お気に入り機能
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drink == null
              ? const Center(child: Text('ドリンク情報が見つかりませんでした'))
              : _buildDrinkDetails(),
    );
  }

  Widget _buildDrinkDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ドリンク画像
          Center(
            child: Image.network(
              _drink!.imageUrl,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          
          // ドリンク名（日本語・英語）
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _drink!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _drink!.type, // 英語名の代わりにタイプを表示
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 「飲めるお店を探す」ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50, // ボタンの高さを固定
              child: Stack(
                children: [
                  // 背景画像
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/map_background.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 画像が読み込めない場合のフォールバック
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[200],
                        );
                      },
                    ),
                  ),
                  // 半透明のオーバーレイ
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // ボタン
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/map',
                          arguments: {'drinkId': _drink!.id},
                        );
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '飲めるお店を探す',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // プロのコメントセクション
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROのコメント',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_totalProComments > 0)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProCommentsScreen(
                            drinkId: widget.drinkId,
                            drinkName: _drink?.name ?? '',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'すべて見る',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // プロコメントの水平スクロールリスト
          _proCommentsWithUserData.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('プロのコメントはまだありません', style: TextStyle(color: Colors.grey)),
                )
              : SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: _proCommentsWithUserData.length,
                    itemBuilder: (context, index) {
                      return _buildProCommentItem(_proCommentsWithUserData[index]);
                    },
                  ),
                ),

          const SizedBox(height: 16),

          // すべてのプロコメントを見るボタン
          if (_totalProComments > 0)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProCommentsScreen(
                        drinkId: widget.drinkId,
                        drinkName: _drink?.name ?? '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'すべてのコメント ($_totalProComments)',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // お酒の情報セクション
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'お酒の情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // お酒の情報リスト
          ..._buildDrinkInfoItems(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }



  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // お酒の種類に応じた情報項目を構築する
  List<Widget> _buildDrinkInfoItems() {
    if (_drink == null || _drinkData == null) return [];
    
    final List<Widget> infoItems = [];
    
    // Firestoreのデータを取得
    final String name = _drinkData!['name'] as String; // ドリンク名（日本語）
    final String nameEn = _drinkData!['name_en'] as String; // ドリンク名（英語）
    final String brand = _drinkData!['brand'] as String; // ブランド名
    final String area = _drinkData!['area'] as String; // 生産地域
    final double abv = _drinkData!['abv'] as double; // アルコール度数
    final String country = _countryName ?? '不明'; // 国名を表示
    
    // 基本情報を表示
    infoItems.add(_buildInfoItem('名称', name));
    infoItems.add(_buildInfoItem('名称（英語）', nameEn));
    infoItems.add(_buildInfoItem('生産国', country));
    infoItems.add(_buildInfoItem('生産エリア', area));
    infoItems.add(_buildInfoItem('お酒カテゴリ', _drink!.type));
    infoItems.add(_buildInfoItem('アルコール度数', '${abv}%'));
    infoItems.add(_buildInfoItem('シリーズ', brand));
    
    return infoItems;
  }
  
  Widget _buildProCommentItem(Map<String, dynamic> commentData) {
    final comment = commentData['comment'] as Comment;
    final user = commentData['user'] as User?;
    final shop = commentData['shop'] as Shop?;
    
    final userName = user?.name ?? '不明なユーザー';
    final shopName = shop?.name ?? '';
    final displayName = shopName.isNotEmpty 
        ? '$userName（$shopName）' 
        : userName;
    
    // StatefulWidgetを使用して、コメントの展開状態を管理
    return _ProCommentItem(comment: comment, displayName: displayName);
  }
}

// プロコメント用のStatefulWidgetを作成
class _ProCommentItem extends StatefulWidget {
  final Comment comment;
  final String displayName;
  
  const _ProCommentItem({required this.comment, required this.displayName});
  
  @override
  State<_ProCommentItem> createState() => _ProCommentItemState();
}

class _ProCommentItemState extends State<_ProCommentItem> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報
            Row(
              children: [
                // アバター
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                
                // ユーザー名と店舗名
                Expanded(
                  child: Text(
                    widget.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // コメント内容 - 展開時は縦スクロール可能に
            _isExpanded
                ? Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.comment.comment,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          // 「折りたたむ」ボタン
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isExpanded = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '折りたたむ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.comment.comment,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // 「すべて表示」ボタン
                        if (widget.comment.comment.length > 100) // 長いコメントの場合のみ表示
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isExpanded = true;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'すべて表示',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
