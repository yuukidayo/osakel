import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 管理者権限チェックサービス
class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーが管理者かどうかをチェック
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      print('👤 現在のユーザー: ${user?.uid}');
      if (user == null) {
        print('🚫 ユーザーがログインしていません');
        return false;
      }

      // 正しい管理者権限確認方法: idフィールドと現在のUIDを照合
      print('🔎 userコレクションからidフィールドが現在のUIDと一致するドキュメントを検索: ${user.uid}');
      final querySnapshot = await _firestore
          .collection('user')
          .where('id', isEqualTo: user.uid)
          .limit(1)
          .get();

      print('📃 一致するドキュメント数: ${querySnapshot.docs.length}');
      if (querySnapshot.docs.isEmpty) {
        print('🚫 idフィールドが一致するドキュメントが見つかりません');
        return false;
      }

      // 最初の一致するドキュメントを使用
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      print('📊 ユーザーデータ: $userData');
      final role = userData['role'] as String?;
      print('🔑 ユーザーロール: $role');
      
      // 管理者ロールをチェック（"管理者" または "admin"）
      print('🔍 ロール比較: "$role" == "管理者" => ${role == '管理者'}');
      print('🔍 ロール比較: "$role" == "admin" => ${role == 'admin'}');
      final isAdminUser = role == '管理者' || role == 'admin';
      print('👑 管理者権限: $isAdminUser');
      return isAdminUser;
    } catch (e) {
      print('❌ 管理者権限チェックエラー: $e');
      return false;
    }
  }

  /// 現在のユーザーのロールを取得
  static Future<String?> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('user').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      return userData?['role'] as String?;
    } catch (e) {
      print('ユーザーロール取得エラー: $e');
      return null;
    }
  }
}
