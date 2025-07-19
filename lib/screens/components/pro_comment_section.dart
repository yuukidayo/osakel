import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../models/user.dart';
import '../pro_comments_screen.dart';

/// プロコメントセクション
class ProCommentSection extends StatelessWidget {
  final List<Map<String, dynamic>> proCommentsWithUserData;
  final int totalProComments;
  final String drinkId;

  const ProCommentSection({
    super.key,
    required this.proCommentsWithUserData,
    required this.totalProComments,
    required this.drinkId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'プロのコメント',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalProComments > 0)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProCommentsScreen(drinkId: drinkId),
                        ),
                      );
                    },
                    child: Text('全て見る ($totalProComments)'),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // コメント表示
            if (proCommentsWithUserData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'まだプロのコメントがありません',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...proCommentsWithUserData.take(2).map((commentData) {
                final comment = commentData['comment'] as Comment;
                final user = commentData['user'] as User;
                return ProCommentItem(
                  comment: comment,
                  user: user,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

/// プロコメント項目
class ProCommentItem extends StatelessWidget {
  final Comment comment;
  final User user;

  const ProCommentItem({
    super.key,
    required this.comment,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: user.profileImageUrl.isNotEmpty
                    ? NetworkImage(user.profileImageUrl)
                    : null,
                child: user.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // コメント内容
          Text(
            comment.content,
            style: const TextStyle(fontSize: 14, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // 日付
          Text(
            _formatDate(comment.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
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
