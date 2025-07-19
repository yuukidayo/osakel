import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shop.dart';
import '../../models/drink_shop_link.dart';
import '../../models/shop_with_price.dart';
import '../../models/user.dart';
import '../../models/comment.dart';

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
  CollectionReference get usersRef => _firestore.collection('user');
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
      print('Error fetching shop: $e');
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
      print('Error fetching drink-shop links: $e');
      return [];
    }
  }
  
  // Get shops with prices for a specific drink (alias for compatibility)
  Future<List<ShopWithPrice>> getShopsWithPrice(String? drinkId) async {
    return getShopsWithPricesForDrink(drinkId ?? '');
  }

  // Get shops with prices for a specific drink
  Future<List<ShopWithPrice>> getShopsWithPricesForDrink(String drinkId) async {
    print('Fetching shops with prices for drink: $drinkId');
    
    try {
      // Get all drink-shop links for the specified drink where isAvailable is true
      final linksSnapshot = await drinkShopLinksRef
          .where('drinkId', isEqualTo: drinkId)
          .where('isAvailable', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            print('Firestore query timed out');
            throw TimeoutException('Firestore query timed out');
          });
      
      if (linksSnapshot.docs.isEmpty) {
        print('No available drink-shop links found for drink: $drinkId');
        return [];
      }
      
      print('Found ${linksSnapshot.docs.length} available drink-shop links');
      
      // ドキュメントIDを表示
      for (var doc in linksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('ドキュメントID: ${doc.id}, drinkId: ${data['drinkId'] ?? 'null'}, shopId: ${data['shopId'] ?? 'null'}');
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
          print('Error processing shop link: $e');
          // Continue with next link even if one fails
          continue;
        }
      }
      
      print('Returning ${shopsWithPrices.length} shops with prices');
      return shopsWithPrices;
    } catch (e) {
      print('Error fetching shops with prices: $e');
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
      print('Error fetching user: $e');
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
      print('Error fetching pro users: $e');
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
      print('Error fetching comments for drink: $e');
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
      print('Error fetching pro comments for drink: $e');
      return [];
    }
  }
  
  // コメントを追加
  Future<String?> addComment(Comment comment) async {
    try {
      final docRef = await commentsRef.add(comment.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }
  
  // コメントを削除
  Future<bool> deleteComment(String commentId) async {
    try {
      await commentsRef.doc(commentId).delete();
      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
}
