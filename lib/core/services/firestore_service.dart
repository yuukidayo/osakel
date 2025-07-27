import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../store/models/shop.dart';
import '../../drink/models/drink_shop_link.dart';
import '../../store/models/shop_with_price.dart';
import '../../user/models/user.dart';
import '../../drink/models/comment.dart';

class FirestoreService {
  // Lazy initialization of Firestore to avoid issues during app startup
  FirebaseFirestore? _firestoreInstance;
  
  // Getter for Firestore instance with error handling
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }
  
  // Collection references with error handling
  CollectionReference get shopsRef => _firestore.collection('shops');
  CollectionReference get drinkShopLinksRef => _firestore.collection('drink_shop_links');
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get commentsRef => _firestore.collection('comments');
  
  // Get a specific shop by ID
  Future<Shop?> getShop(String shopId) async {
    try {
      final docSnapshot = await shopsRef.doc(shopId).get();
      if (docSnapshot.exists) {
        return Shop.fromMap(docSnapshot.id, docSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching shop: $e');
      return null;
    }
  }
  
  // Get drink-shop links for a specific drink
  Future<List<DrinkShopLink>> getDrinkShopLinks(String drinkId) async {
    try {
      final querySnapshot = await drinkShopLinksRef
          .where('drinkId', isEqualTo: drinkId)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return DrinkShopLink.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching drink-shop links: $e');
      return [];
    }
  }
  
  // Get shops with prices for a specific drink (alias for compatibility)
  Future<List<ShopWithPrice>> getShopsWithPrice(String? drinkId) async {
    return getShopsWithPricesForDrink(drinkId ?? '');
  }

  // Get shops with prices for a specific drink
  Future<List<ShopWithPrice>> getShopsWithPricesForDrink(String drinkId) async {
    debugPrint('Fetching shops with prices for drink: $drinkId');
    
    try {
      // Get all drink-shop links for the specified drink where isAvailable is true
      final linksSnapshot = await drinkShopLinksRef
          .where('drinkId', isEqualTo: drinkId)
          .where('isAvailable', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            debugPrint('Firestore query timed out');
            throw TimeoutException('Firestore query timed out');
          });
      
      if (linksSnapshot.docs.isEmpty) {
        debugPrint('No available drink-shop links found for drink: $drinkId');
        return [];
      }
      
      debugPrint('Found ${linksSnapshot.docs.length} available drink-shop links');
      
      // ドキュメントIDを表示
      for (var doc in linksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('ドキュメントID: ${doc.id}, drinkId: ${data['drinkId'] ?? 'null'}, shopId: ${data['shopId'] ?? 'null'}');
      }
      
      // Create a list to store the results
      List<ShopWithPrice> shopsWithPrices = [];
      
      // For each link, get the corresponding shop
      for (var linkDoc in linksSnapshot.docs) {
        try {
          final link = DrinkShopLink.fromMap(
            linkDoc.id, 
            linkDoc.data() as Map<String, dynamic>
          );
          
          // Get the shop document
          final shopDoc = await shopsRef.doc(link.shopId).get();
          
          if (shopDoc.exists) {
            final shop = Shop.fromMap(
              shopDoc.id, 
              shopDoc.data() as Map<String, dynamic>
            );
            
            // Add to the result list
            shopsWithPrices.add(ShopWithPrice(
              shop: shop,
              drinkShopLink: link
            ));
          }
        } catch (e) {
          debugPrint('Error processing shop link: $e');
          // Continue with next link even if one fails
          continue;
        }
      }
      
      debugPrint('Returning ${shopsWithPrices.length} shops with prices');
      return shopsWithPrices;
    } catch (e) {
      debugPrint('Error fetching shops with prices: $e');
      // Return empty list on error
      return [];
    }
  }
  
  // ユーザー関連のメソッド
  
  // ユーザー情報を取得
  Future<User?> getUserById(String userId) async {
    try {
      final docSnapshot = await usersRef.doc(userId).get();
      if (docSnapshot.exists) {
        return User.fromMap(docSnapshot.id, docSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }
  
  // プロユーザーのリストを取得
  Future<List<User>> getProUsers() async {
    try {
      final querySnapshot = await usersRef
          .where('role', isEqualTo: 'プロ')
          .get();
      
      return querySnapshot.docs.map((doc) {
        return User.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching pro users: $e');
      return [];
    }
  }
  
  // コメント関連のメソッド
  
  // 特定のドリンクに対するコメントを取得
  Future<List<Comment>> getCommentsForDrink(String drinkId) async {
    try {
      final querySnapshot = await commentsRef
          .where('drinkId', isEqualTo: drinkId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return Comment.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching comments for drink: $e');
      return [];
    }
  }
  
  // プロユーザーによるコメントのみを取得
  Future<List<Comment>> getProCommentsForDrink(String drinkId) async {
    try {
      // まずプロユーザーのIDリストを取得
      final proUsers = await getProUsers();
      final proUserIds = proUsers.map((user) => user.id).toList();
      
      if (proUserIds.isEmpty) {
        return [];
      }
      
      // インデックスエラーを回避するために、まずドリンクに関連するコメントを取得
      final querySnapshot = await commentsRef
          .where('drinkId', isEqualTo: drinkId)
          .get();
      
      // メモリ上でプロユーザーのコメントをフィルタリング
      final proComments = querySnapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return proUserIds.contains(data['userId']);
          })
          .map((doc) => Comment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // 作成日時でソート
      proComments.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!); // 降順
      });
      
      return proComments;
    } catch (e) {
      debugPrint('Error fetching pro comments for drink: $e');
      return [];
    }
  }
  
  // コメントを追加
  Future<String?> addComment(Comment comment) async {
    try {
      final docRef = await commentsRef.add(comment.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }
  
  // コメントを削除
  Future<bool> deleteComment(String commentId) async {
    try {
      await commentsRef.doc(commentId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }
  
  // ユーザー情報をFirestoreに保存
  Future<bool> saveUser({
    required String uid,
    required String name,
    required String email,
    String? fcmToken,
    String role = '一般', // デフォルトで一般ユーザー
  }) async {
    debugPrint('🚀 FirestoreService.saveUser() メソッド開始');
    debugPrint('📝 保存対象データ:');
    debugPrint('  - UID: $uid');
    debugPrint('  - Name: $name');
    debugPrint('  - Email: $email');
    debugPrint('  - FCMToken: ${fcmToken ?? "なし"}');
    debugPrint('  - Role: $role');
    
    try {
      debugPrint('📡 Firestore接続状態確認中...');
      
      // Firestore接続状態を確認
      debugPrint('🔍 Firestore instance: ${_firestore.toString()}');
      debugPrint('🔍 usersRef: ${usersRef.toString()}');
      
      debugPrint('📡 Firestore usersRef.doc($uid).set() 呼び出し開始');
      debugPrint('⏱️ タイムアウト設定: 30秒');
      
      final userData = {
        'uid': uid, // ユーザーのUID
        'name': name, // 名前
        'email': email, // メールアドレス（既存）
        'role': role, // role: 一般
        'fcmToken': fcmToken, // FCMトークン
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      debugPrint('📄 保存データ構築完了: $userData');
      debugPrint('🚀 Firestore書き込み開始...');
      
      // タイムアウト付きFirestore書き込みを実行
      await usersRef.doc(uid).set(userData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ Firestore書き込みがタイムアウトしました (30秒)');
          throw TimeoutException('Firestore書き込みがタイムアウトしました', const Duration(seconds: 30));
        },
      );
      
      debugPrint('✅ Firestore書き込み成功: usersコレクションにUID=$uid で保存完了');
      debugPrint('🎉 saveUser処理完了 - trueを返します');
      return true;
    } catch (e) {
      debugPrint('❌ FirestoreService.saveUser() エラー発生:');
      debugPrint('  - エラー内容: $e');
      debugPrint('  - エラータイプ: ${e.runtimeType}');
      
      if (e is TimeoutException) {
        debugPrint('⏰ タイムアウトエラー: Firestore接続またはネットワークの問題');
      } else if (e.toString().contains('permission-denied')) {
        debugPrint('🚫 権限エラー: Firestoreセキュリティルールでアクセスが拒否されました');
        debugPrint('  - コレクション: users');
        debugPrint('  - ドキュメントID: $uid');
      } else if (e.toString().contains('network')) {
        debugPrint('🌐 ネットワークエラー: インターネット接続を確認してください');
      }
      
      debugPrint('💥 saveUser処理失敗 - falseを返します');
      return false;
    }
  }
}
