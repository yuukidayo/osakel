import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/comment.dart';
import '../../../../models/user.dart';
import '../../../../models/shop.dart';
import '../../../core/services/firestore_service.dart';

class ProCommentsScreen extends StatefulWidget {
  final String drinkId;
  final String drinkName;

  const ProCommentsScreen({
    super.key,
    required this.drinkId,
    required this.drinkName,
  });

  @override
  State<ProCommentsScreen> createState() => _ProCommentsScreenState();
}

class _ProCommentsScreenState extends State<ProCommentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _commentsWithUserData = [];

  @override
  void initState() {
    super.initState();
    _loadProComments();
  }

  Future<void> _loadProComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // プロユーザーのコメントを取得
      final comments = await _firestoreService.getProCommentsForDrink(widget.drinkId);
      
      // コメントごとにユーザー情報を取得
      final commentsWithUserData = <Map<String, dynamic>>[];
      
      for (var comment in comments) {
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
          'isExpanded': false,
        });
      }
      
      setState(() {
        _commentsWithUserData = commentsWithUserData;
        _isLoading = false;
      });
    } catch (e) {
      print('プロコメントの取得中にエラーが発生しました: $e');
      setState(() {
        _isLoading = false;
      });
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
        title: Text(
          '${widget.drinkName}のプロコメント',
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _commentsWithUserData.isEmpty
              ? const Center(child: Text('プロのコメントはまだありません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _commentsWithUserData.length,
                  itemBuilder: (context, index) {
                    final item = _commentsWithUserData[index];
                    final comment = item['comment'] as Comment;
                    final user = item['user'] as User?;
                    final shop = item['shop'] as Shop?;
                    
                    return _buildCommentItem(comment, user, shop, index);
                  },
                ),
    );
  }

  Widget _buildCommentItem(Comment comment, User? user, Shop? shop, int index) {
    final userName = user?.name ?? '不明なユーザー';
    final shopName = shop?.name ?? '';
    final displayName = shopName.isNotEmpty 
        ? '$userName（$shopName）' 
        : userName;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アバター
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                
                // ユーザー情報とコメント
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comment.comment,
                        style: const TextStyle(fontSize: 15),
                        maxLines: _commentsWithUserData[index]['isExpanded'] ? null : 3,
                        overflow: _commentsWithUserData[index]['isExpanded'] 
                            ? null 
                            : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // もっと見るボタン
            if (!_commentsWithUserData[index]['isExpanded'] && 
                comment.comment.length > 100)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _commentsWithUserData[index]['isExpanded'] = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'もっと見る',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            
            // 日付表示
            if (comment.createdAt != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '${comment.createdAt!.year}/${comment.createdAt!.month}/${comment.createdAt!.day}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
