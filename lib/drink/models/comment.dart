import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String comment;
  final String drinkId;
  final String userId;
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.comment,
    required this.drinkId,
    required this.userId,
    this.createdAt,
  });

  factory Comment.fromMap(String docId, Map<String, dynamic> data) {
    // createdAtフィールドがTimestampの場合はDateTime型に変換
    DateTime? createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        createdAt = data['createdAt'];
      }
    }

    return Comment(
      id: docId,
      comment: data['comment'] ?? '',
      drinkId: data['drinkId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment': comment,
      'drinkId': drinkId,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
