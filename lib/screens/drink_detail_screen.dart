import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drink.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../models/shop.dart';
import '../services/firestore_service.dart';
import '../utils/safe_data_utils.dart';

import 'pro_comments_screen.dart';
import 'components/drink_info_card.dart';

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
              _countryName = SafeDataUtils.safeGetString(countryDoc.data() as Map<String, dynamic>?, 'name');
            });
          }
        } else {
          // countryRefが存在しない場合は既存のcountryフィールドを使用
          setState(() {
            _countryName = SafeDataUtils.safeGetString(drinkData, 'country');
          });
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
      backgroundColor: const Color(0xFFFFFFFF), // 純白背景(#FFFFFF)に統一
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        //title: const Text('戻る', style: TextStyle(color: Colors.black, fontSize: 16)),
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
                  _drink!.type,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildShopSearchButton(),
          _buildProCommentsSection(),
          Column(
            children: [
              const SizedBox(height: 24),
              DrinkInfoCard(
                drink: _drink!,
                countryName: _countryName,
                drinkData: _drinkData,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopSearchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
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
    );
  }

  Widget _buildProCommentsSection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        // プロのコメントヘッダー
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
        // プロコメントリスト
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
      ],
    );
  }

  Widget _buildProCommentItem(Map<String, dynamic> commentData) {
    final comment = commentData['comment'] as Comment;
    final user = commentData['user'] as User?;
    final shop = commentData['shop'] as Shop?;
    
    return _ProCommentCard(
      comment: comment,
      user: user,
      shop: shop,
    );
  }
}

class _ProCommentCard extends StatelessWidget {
  final Comment comment;
  final User? user;
  final Shop? shop;
  
  const _ProCommentCard({
    required this.comment,
    required this.user,
    required this.shop,
  });
  
  @override
  Widget build(BuildContext context) {
    final commentText = comment.comment;
    final userName = user?.name ?? '不明なユーザー';
    final shopName = shop?.name ?? '';
    final displayName = shopName.isNotEmpty ? '$userName（$shopName）' : userName;
    
    return Container(
      width: 280,
      height: 180,
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
            _buildUserHeader(displayName),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                commentText,
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (comment.comment.length > 80)
                  Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserHeader(String displayName) {
    return Row(
      children: [
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
        Expanded(
          child: Text(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
