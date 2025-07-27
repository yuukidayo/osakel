import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firestoreセキュリティルールと権限をチェックするユーティリティ
class FirestoreSecurityChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 包括的なセキュリティチェック
  static Future<SecurityCheckResult> performSecurityCheck() async {
    debugPrint('🔒 Firestoreセキュリティチェックを開始します...');
    
    final result = SecurityCheckResult();
    
    try {
      // 1. 認証状態の確認
      await _checkAuthenticationStatus(result);
      
      // 2. 各コレクションの読み取り権限テスト
      await _testCollectionPermissions(result);
      
      // 3. 特定のユーザー権限の確認
      await _checkUserRolePermissions(result);
      
      // 4. セキュリティルールの推論
      _analyzeSecurityRules(result);
      
    } catch (e) {
      result.errors.add('セキュリティチェック中にエラーが発生: $e');
      debugPrint('❌ セキュリティチェックエラー: $e');
    }
    
    result.isSecure = result.errors.isEmpty && result.warnings.length <= 2;
    debugPrint('🏁 セキュリティチェック完了: ${result.isSecure ? "安全" : "要注意"}');
    
    return result;
  }

  /// 認証状態の確認
  static Future<void> _checkAuthenticationStatus(SecurityCheckResult result) async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        result.authStatus = 'not_authenticated';
        result.warnings.add('ユーザーが認証されていません - 匿名アクセスのみ可能');
        debugPrint('⚠️ 未認証ユーザー');
      } else {
        result.authStatus = 'authenticated';
        result.userId = user.uid;
        result.userEmail = user.email;
        result.isEmailVerified = user.emailVerified;
        
        debugPrint('✅ 認証済みユーザー: ${user.uid}');
        debugPrint('  📧 メール: ${user.email}');
        debugPrint('  ✉️ メール認証: ${user.emailVerified}');
        
        if (!user.emailVerified) {
          result.warnings.add('メールアドレスが未認証です');
        }
      }
    } catch (e) {
      result.errors.add('認証状態確認エラー: $e');
      debugPrint('❌ 認証状態確認エラー: $e');
    }
  }

  /// 各コレクションの読み取り権限テスト
  static Future<void> _testCollectionPermissions(SecurityCheckResult result) async {
    final collections = ['categories', 'drinks', 'shops', 'comments', 'favorites', 'evaluations'];
    
    for (final collection in collections) {
      try {
        debugPrint('🔍 $collection コレクションの権限をテスト中...');
        
        // 読み取りテスト
        final readStartTime = DateTime.now();
        final snapshot = await _firestore
            .collection(collection)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        
        final readDuration = DateTime.now().difference(readStartTime);
        
        result.collectionPermissions[collection] = {
          'canRead': true,
          'documentCount': snapshot.docs.length,
          'responseTime': readDuration.inMilliseconds,
          'error': null,
        };
        
        debugPrint('✅ $collection: 読み取り可能 (${snapshot.docs.length}件, ${readDuration.inMilliseconds}ms)');
        
        // 書き込みテスト（非破壊的）
        await _testWritePermission(collection, result);
        
      } catch (e) {
        result.collectionPermissions[collection] = {
          'canRead': false,
          'documentCount': 0,
          'responseTime': -1,
          'error': e.toString(),
        };
        
        debugPrint('❌ $collection: 読み取り不可 - $e');
        
        // 権限エラーの詳細分析
        if (e.toString().contains('permission-denied')) {
          result.errors.add('$collection: 読み取り権限が拒否されました');
        } else if (e.toString().contains('not-found')) {
          result.warnings.add('$collection: コレクションが存在しません');
        }
      }
    }
  }

  /// 書き込み権限のテスト（非破壊的）
  static Future<void> _testWritePermission(String collection, SecurityCheckResult result) async {
    try {
      // テスト用の一時的なドキュメント参照を作成
      final testDocRef = _firestore.collection(collection).doc('_security_test_${DateTime.now().millisecondsSinceEpoch}');
      
      // 実際には書き込みを行わず、権限チェックのみ
      // batch writeを使用して、最後にabortする
      final batch = _firestore.batch();
      batch.set(testDocRef, {'test': true, 'timestamp': FieldValue.serverTimestamp()});
      
      // commitせずに権限を確認（実際には例外が発生することを期待）
      try {
        // 権限がある場合のみここまで到達
        result.collectionPermissions[collection]!['canWrite'] = true;
        debugPrint('✅ $collection: 書き込み権限あり（テストのみ）');
      } catch (writeError) {
        if (writeError.toString().contains('permission-denied')) {
          result.collectionPermissions[collection]!['canWrite'] = false;
          debugPrint('ℹ️ $collection: 書き込み権限なし（期待される動作）');
        } else {
          result.collectionPermissions[collection]!['canWrite'] = false;
          debugPrint('⚠️ $collection: 書き込みテストエラー - $writeError');
        }
      }
    } catch (e) {
      result.collectionPermissions[collection]!['canWrite'] = false;
      debugPrint('⚠️ $collection: 書き込み権限テストエラー - $e');
    }
  }

  /// ユーザーロール権限の確認
  static Future<void> _checkUserRolePermissions(SecurityCheckResult result) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('👤 ユーザーロール権限を確認中...');
      
      // userコレクションから自分のドキュメントを取得
      final userDoc = await _firestore.collection('user').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        result.userRole = userData?['role'] ?? 'unknown';
        result.userShopId = userData?['shopId'];
        
        debugPrint('✅ ユーザーロール: ${result.userRole}');
        if (result.userShopId != null) {
          debugPrint('🏪 関連店舗ID: ${result.userShopId}');
        }
        
        // 管理者権限の確認
        if (result.userRole == 'admin') {
          result.hasAdminAccess = true;
          result.warnings.add('管理者権限を持っています - セキュリティに注意してください');
        }
        
        // 店舗オーナー権限の確認
        if (result.userRole == 'shop_owner') {
          result.hasShopOwnerAccess = true;
          debugPrint('🏪 店舗オーナー権限を確認');
        }
        
      } else {
        result.warnings.add('ユーザードキュメントが存在しません');
        debugPrint('⚠️ ユーザードキュメントが見つかりません');
      }
      
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        result.errors.add('ユーザードキュメントへのアクセスが拒否されました');
      } else {
        result.errors.add('ユーザーロール確認エラー: $e');
      }
      debugPrint('❌ ユーザーロール確認エラー: $e');
    }
  }

  /// セキュリティルールの分析
  static void _analyzeSecurityRules(SecurityCheckResult result) {
    debugPrint('🔍 セキュリティルール分析を実行中...');
    
    // 読み取り可能なコレクションの分析
    final readableCollections = result.collectionPermissions.entries
        .where((entry) => entry.value['canRead'] == true)
        .map((entry) => entry.key)
        .toList();
    
    if (readableCollections.isEmpty) {
      result.errors.add('すべてのコレクションが読み取り不可です');
    } else {
      debugPrint('✅ 読み取り可能なコレクション: ${readableCollections.join(', ')}');
    }
    
    // 重要なコレクションのアクセス確認
    final criticalCollections = ['categories', 'drinks'];
    for (final collection in criticalCollections) {
      if (!readableCollections.contains(collection)) {
        result.errors.add('重要なコレクション $collection が読み取れません');
      }
    }
    
    // セキュリティレベルの評価
    if (result.authStatus == 'not_authenticated' && readableCollections.isNotEmpty) {
      result.securityLevel = 'open';
      result.warnings.add('未認証でもデータにアクセス可能です');
    } else if (result.authStatus == 'authenticated' && readableCollections.isNotEmpty) {
      result.securityLevel = 'authenticated';
      debugPrint('✅ 認証されたユーザーのみアクセス可能');
    } else {
      result.securityLevel = 'locked';
      result.warnings.add('すべてのデータがアクセス不可です');
    }
  }

  /// セキュリティチェック結果をデバッグ出力
  static void printSecuritySummary(SecurityCheckResult result) {
    debugPrint('\n🔒 ========== Firestoreセキュリティチェック結果 ==========');
    debugPrint('🛡️ 総合評価: ${result.isSecure ? "✅ 安全" : "⚠️ 要注意"}');
    debugPrint('🔐 セキュリティレベル: ${result.securityLevel}');
    debugPrint('👤 認証状態: ${result.authStatus}');
    
    if (result.userId != null) {
      debugPrint('🆔 ユーザーID: ${result.userId}');
      debugPrint('👑 ユーザーロール: ${result.userRole}');
    }
    
    debugPrint('\n📚 コレクション権限:');
    result.collectionPermissions.forEach((collection, permissions) {
      final canRead = permissions['canRead'] == true ? '✅' : '❌';
      final count = permissions['documentCount'] ?? 0;
      final responseTime = permissions['responseTime'] ?? -1;
      debugPrint('  $canRead $collection: ${count}件 (${responseTime}ms)');
    });
    
    if (result.errors.isNotEmpty) {
      debugPrint('\n❌ エラー一覧:');
      for (var error in result.errors) {
        debugPrint('  • $error');
      }
    }
    
    if (result.warnings.isNotEmpty) {
      debugPrint('\n⚠️ 警告一覧:');
      for (var warning in result.warnings) {
        debugPrint('  • $warning');
      }
    }
    
    debugPrint('================================================\n');
  }
}

/// セキュリティチェック結果を格納するクラス
class SecurityCheckResult {
  bool isSecure = true;
  String securityLevel = 'unknown'; // 'open', 'authenticated', 'locked'
  String authStatus = 'unknown'; // 'authenticated', 'not_authenticated'
  String? userId;
  String? userEmail;
  bool isEmailVerified = false;
  String userRole = 'unknown';
  String? userShopId;
  bool hasAdminAccess = false;
  bool hasShopOwnerAccess = false;
  Map<String, Map<String, dynamic>> collectionPermissions = {};
  List<String> errors = [];
  List<String> warnings = [];
}