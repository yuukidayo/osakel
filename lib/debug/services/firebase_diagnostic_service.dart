import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Firebase接続とデータ取得のエラー診断サービス
class FirebaseDiagnosticService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firebase接続状態の総合診断
  static Future<FirebaseDiagnosticResult> performComprehensiveDiagnosis() async {
    debugPrint('🔍 Firebase診断を開始します...');
    
    final result = FirebaseDiagnosticResult();
    
    try {
      // 1. Firebase Core初期化状態の確認
      result.isCoreInitialized = Firebase.apps.isNotEmpty;
      debugPrint('✅ Firebase Core初期化状態: ${result.isCoreInitialized}');
      
      if (!result.isCoreInitialized) {
        result.errors.add('Firebase Coreが初期化されていません');
        return result;
      }

      // 2. Firestore接続テスト
      await _testFirestoreConnection(result);
      
      // 3. 認証状態の確認
      await _checkAuthenticationStatus(result);
      
      // 4. categoriesコレクションの存在確認
      await _checkCategoriesCollection(result);
      
      // 5. セキュリティルールの権限テスト
      await _testSecurityRulesPermissions(result);
      
      // 6. ネットワーク接続状態の確認
      await _checkNetworkConnectivity(result);
      
    } catch (e) {
      result.errors.add('診断中にエラーが発生しました: $e');
      debugPrint('❌ 診断エラー: $e');
    }
    
    result.isSuccess = result.errors.isEmpty;
    debugPrint('🏁 Firebase診断完了: ${result.isSuccess ? "成功" : "失敗"}');
    
    return result;
  }

  /// Firestore接続テスト
  static Future<void> _testFirestoreConnection(FirebaseDiagnosticResult result) async {
    try {
      debugPrint('🔗 Firestore接続テストを実行中...');
      
      // シンプルな接続テスト: settings取得
      final settings = _firestore.settings;
      result.firestoreConnectionStatus = 'Connected';
      debugPrint('✅ Firestore接続成功 - Host: ${settings.host}');
      
      // 基本的な読み取りテスト
      await _firestore.collection('_test_connection').limit(1).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Firestore接続タイムアウト', const Duration(seconds: 10)),
      );
      
      result.canReadFromFirestore = true;
      debugPrint('✅ Firestore読み取りテスト成功');
      
    } catch (e) {
      result.firestoreConnectionStatus = 'Failed: $e';
      result.canReadFromFirestore = false;
      result.errors.add('Firestore接続エラー: $e');
      debugPrint('❌ Firestore接続テスト失敗: $e');
    }
  }

  /// 認証状態の確認
  static Future<void> _checkAuthenticationStatus(FirebaseDiagnosticResult result) async {
    try {
      final user = _auth.currentUser;
      result.isUserAuthenticated = user != null;
      result.userId = user?.uid;
      
      if (user != null) {
        debugPrint('✅ ユーザー認証済み - UID: ${user.uid}');
        debugPrint('📧 メールアドレス: ${user.email}');
        debugPrint('✉️ メール認証状態: ${user.emailVerified}');
      } else {
        debugPrint('ℹ️ ユーザー未認証（匿名アクセス）');
      }
      
    } catch (e) {
      result.errors.add('認証状態確認エラー: $e');
      debugPrint('❌ 認証状態確認エラー: $e');
    }
  }

  /// categoriesコレクションの存在と構造確認
  static Future<void> _checkCategoriesCollection(FirebaseDiagnosticResult result) async {
    try {
      debugPrint('📁 categoriesコレクションの確認を開始...');
      
      final snapshot = await _firestore.collection('categories').limit(5).get().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('categories取得タイムアウト', const Duration(seconds: 15)),
      );
      
      result.categoriesCollectionExists = true;
      result.categoriesCount = snapshot.docs.length;
      
      debugPrint('✅ categoriesコレクション存在確認: ${snapshot.docs.length}件のドキュメント');
      
      // データ構造の詳細チェック
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs.take(3)) {
          final data = doc.data();
          debugPrint('📄 カテゴリ ${doc.id}: $data');
          
          // 必須フィールドの存在確認
          final hasName = data.containsKey('name');
          final hasOrder = data.containsKey('order');
          final hasSubcategories = data.containsKey('subcategories');
          
          result.categoryFieldsStatus.add({
            'id': doc.id,
            'hasName': hasName,
            'hasOrder': hasOrder,
            'hasSubcategories': hasSubcategories,
            'subcategoriesType': data['subcategories']?.runtimeType.toString(),
            'subcategoriesCount': data['subcategories'] is List ? data['subcategories'].length : 0,
          });
          
          if (!hasName || !hasOrder) {
            result.warnings.add('カテゴリ ${doc.id}: 必須フィールドが不足 (name: $hasName, order: $hasOrder)');
          }
        }
      } else {
        result.warnings.add('categoriesコレクションにドキュメントが存在しません');
      }
      
    } catch (e) {
      result.categoriesCollectionExists = false;
      result.errors.add('categoriesコレクション確認エラー: $e');
      debugPrint('❌ categoriesコレクション確認エラー: $e');
    }
  }

  /// セキュリティルールの権限テスト
  static Future<void> _testSecurityRulesPermissions(FirebaseDiagnosticResult result) async {
    try {
      debugPrint('🔒 セキュリティルール権限テストを実行中...');
      
      // categoriesコレクションの読み取り権限テスト
      try {
        await _firestore.collection('categories').limit(1).get();
        result.categoriesReadPermission = true;
        debugPrint('✅ categories読み取り権限: OK');
      } catch (e) {
        result.categoriesReadPermission = false;
        result.errors.add('categories読み取り権限エラー: $e');
        debugPrint('❌ categories読み取り権限: NG - $e');
      }
      
      // drinksコレクションの読み取り権限テスト
      try {
        await _firestore.collection('drinks').limit(1).get();
        result.drinksReadPermission = true;
        debugPrint('✅ drinks読み取り権限: OK');
      } catch (e) {
        result.drinksReadPermission = false;
        result.errors.add('drinks読み取り権限エラー: $e');
        debugPrint('❌ drinks読み取り権限: NG - $e');
      }
      
    } catch (e) {
      result.errors.add('セキュリティルールテストエラー: $e');
      debugPrint('❌ セキュリティルールテストエラー: $e');
    }
  }

  /// ネットワーク接続状態の確認
  static Future<void> _checkNetworkConnectivity(FirebaseDiagnosticResult result) async {
    try {
      debugPrint('🌐 ネットワーク接続状態の確認中...');
      
      // Firestoreのネットワーク状態を確認
      await _firestore.enableNetwork();
      result.networkConnected = true;
      debugPrint('✅ ネットワーク接続: OK');
      
    } catch (e) {
      result.networkConnected = false;
      result.errors.add('ネットワーク接続エラー: $e');
      debugPrint('❌ ネットワーク接続: NG - $e');
    }
  }

  /// モックデータを生成
  static List<Map<String, dynamic>> generateMockCategories() {
    return [
      {
        'id': 'mock_beer',
        'name': 'ビール',
        'order': 1,
        'subcategories': ['ラガー', 'エール', 'ピルスナー'],
        'imageUrl': null,
      },
      {
        'id': 'mock_wine',
        'name': 'ワイン',
        'order': 2,
        'subcategories': ['赤ワイン', '白ワイン', 'ロゼ', 'スパークリング'],
        'imageUrl': null,
      },
      {
        'id': 'mock_sake',
        'name': '日本酒',
        'order': 3,
        'subcategories': ['純米酒', '本醸造', '吟醸酒', '大吟醸'],
        'imageUrl': null,
      },
      {
        'id': 'mock_whiskey',
        'name': 'ウィスキー',
        'order': 4,
        'subcategories': ['スコッチ', 'バーボン', 'ジャパニーズ', 'アイリッシュ'],
        'imageUrl': null,
      },
    ];
  }

  /// 診断結果をデバッグ出力
  static void printDiagnosticSummary(FirebaseDiagnosticResult result) {
    debugPrint('\n📊 ========== Firebase診断結果サマリー ==========');
    debugPrint('🎯 総合結果: ${result.isSuccess ? "✅ 成功" : "❌ 失敗"}');
    debugPrint('🔧 Core初期化: ${result.isCoreInitialized ? "✅" : "❌"}');
    debugPrint('🔗 Firestore接続: ${result.firestoreConnectionStatus}');
    debugPrint('👤 認証状態: ${result.isUserAuthenticated ? "認証済み" : "未認証"}');
    debugPrint('📁 categoriesコレクション: ${result.categoriesCollectionExists ? "存在" : "不存在"}');
    debugPrint('📊 categoriesドキュメント数: ${result.categoriesCount}');
    debugPrint('🔒 categories読み取り権限: ${result.categoriesReadPermission ? "✅" : "❌"}');
    debugPrint('🔒 drinks読み取り権限: ${result.drinksReadPermission ? "✅" : "❌"}');
    debugPrint('🌐 ネットワーク接続: ${result.networkConnected ? "✅" : "❌"}');
    
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
    
    debugPrint('===============================================\n');
  }
}

/// Firebase診断結果を格納するクラス
class FirebaseDiagnosticResult {
  bool isSuccess = false;
  bool isCoreInitialized = false;
  String firestoreConnectionStatus = 'Unknown';
  bool canReadFromFirestore = false;
  bool isUserAuthenticated = false;
  String? userId;
  bool categoriesCollectionExists = false;
  int categoriesCount = 0;
  bool categoriesReadPermission = false;
  bool drinksReadPermission = false;
  bool networkConnected = false;
  List<String> errors = [];
  List<String> warnings = [];
  List<Map<String, dynamic>> categoryFieldsStatus = [];
}

/// TimeoutException クラスの定義
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}