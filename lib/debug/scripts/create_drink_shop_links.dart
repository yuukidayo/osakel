import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

// Firebaseの初期化とdrink_shop_linksコレクションの作成を行うスクリプト
void main() async {
  debugPrint('drink_shop_links作成スクリプトを開始します...');
  
  // Firebaseの初期化
  await Firebase.initializeApp();
  debugPrint('Firebase初期化成功');
  
  // Firestoreインスタンスの取得
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  try {
    // 既存のshopsコレクションからデータを取得
    QuerySnapshot shopsSnapshot = await firestore.collection('shops').get();
    debugPrint('取得した店舗数: ${shopsSnapshot.docs.length}');
    
    // 既存のdrinksコレクションからデータを取得
    QuerySnapshot drinksSnapshot = await firestore.collection('drinks').get();
    debugPrint('取得したドリンク数: ${drinksSnapshot.docs.length}');
    
    if (shopsSnapshot.docs.isEmpty || drinksSnapshot.docs.isEmpty) {
      debugPrint('店舗またはドリンクのデータがありません。先にサンプルデータを作成してください。');
      exit(1);
    }
    
    // バッチ処理でdrink_shop_linksを作成
    WriteBatch batch = firestore.batch();
    int linkCount = 0;
    
    // 各店舗に対して、関連するドリンクとのリンクを作成
    for (var shopDoc in shopsSnapshot.docs) {
      Map<String, dynamic> shopData = shopDoc.data() as Map<String, dynamic>;
      String shopId = shopDoc.id;
      String shopName = shopData['name'] ?? 'Unknown Shop';
      List<dynamic> drinkIds = shopData['drinkIds'] ?? [];
      
      debugPrint('店舗 "$shopName" の処理中...');
      
      // drinkIdsフィールドがある場合、それを使用してリンクを作成
      if (drinkIds.isNotEmpty) {
        for (var drinkId in drinkIds) {
          // ドリンクが実際に存在するか確認
          DocumentSnapshot drinkDoc = await firestore.collection('drinks').doc(drinkId.toString()).get();
          if (drinkDoc.exists) {
            Map<String, dynamic> drinkData = drinkDoc.data() as Map<String, dynamic>;
            String drinkName = drinkData['name'] ?? 'Unknown Drink';
            
            // リンクドキュメントのIDを生成
            String linkId = '${shopId}_${drinkId}';
            
            // リンクデータを作成
            Map<String, dynamic> linkData = {
              'shopId': shopId,
              'shopName': shopName,
              'drinkId': drinkId,
              'drinkName': drinkName,
              'price': drinkData['price'] ?? 0.0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            
            // バッチにリンクを追加
            DocumentReference linkRef = firestore.collection('drink_shop_links').doc(linkId);
            batch.set(linkRef, linkData);
            linkCount++;
            
            debugPrint('リンク作成: $shopName - $drinkName');
          }
        }
      } else {
        // drinkIdsフィールドがない場合、カテゴリに基づいてランダムにリンク
        String shopCategory = shopData['category'] ?? '';
        
        if (shopCategory.isNotEmpty) {
          // カテゴリに基づいてドリンクをフィルタリング
          List<DocumentSnapshot> matchingDrinks = [];
          
          if (shopCategory.contains('バー') || shopCategory == 'バー') {
            // バーカテゴリの店舗には、ウイスキーとビールを関連付け
            for (var drinkDoc in drinksSnapshot.docs) {
              Map<String, dynamic> drinkData = drinkDoc.data() as Map<String, dynamic>;
              String drinkCategory = drinkData['categoryId'] ?? '';
              if (drinkCategory == 'cat_whisky' || drinkCategory == 'cat_beer') {
                matchingDrinks.add(drinkDoc);
              }
            }
          } else if (shopCategory.contains('ビール') || shopCategory == 'ビアバー') {
            // ビール系の店舗にはビールを関連付け
            for (var drinkDoc in drinksSnapshot.docs) {
              Map<String, dynamic> drinkData = drinkDoc.data() as Map<String, dynamic>;
              String drinkCategory = drinkData['categoryId'] ?? '';
              if (drinkCategory == 'cat_beer') {
                matchingDrinks.add(drinkDoc);
              }
            }
          } else if (shopCategory.contains('日本酒') || shopCategory == '居酒屋') {
            // 日本酒系の店舗には日本酒を関連付け
            for (var drinkDoc in drinksSnapshot.docs) {
              Map<String, dynamic> drinkData = drinkDoc.data() as Map<String, dynamic>;
              String drinkCategory = drinkData['categoryId'] ?? '';
              if (drinkCategory == 'cat_sake') {
                matchingDrinks.add(drinkDoc);
              }
            }
          } else if (shopCategory.contains('ウイスキー')) {
            // ウイスキー系の店舗にはウイスキーを関連付け
            for (var drinkDoc in drinksSnapshot.docs) {
              Map<String, dynamic> drinkData = drinkDoc.data() as Map<String, dynamic>;
              String drinkCategory = drinkData['categoryId'] ?? '';
              if (drinkCategory == 'cat_whisky') {
                matchingDrinks.add(drinkDoc);
              }
            }
          } else {
            // その他の店舗には全てのドリンクをランダムに関連付け
            matchingDrinks = drinksSnapshot.docs;
          }
          
          // マッチしたドリンクとリンクを作成
          if (matchingDrinks.isNotEmpty) {
            for (var drinkDoc in matchingDrinks) {
              String drinkId = drinkDoc.id;
              Map<String, dynamic> drinkData = drinkDoc.data() as Map<String, dynamic>;
              String drinkName = drinkData['name'] ?? 'Unknown Drink';
              
              // リンクドキュメントのIDを生成
              String linkId = '${shopId}_${drinkId}';
              
              // リンクデータを作成
              Map<String, dynamic> linkData = {
                'shopId': shopId,
                'shopName': shopName,
                'drinkId': drinkId,
                'drinkName': drinkName,
                'price': drinkData['price'] ?? 0.0,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              
              // バッチにリンクを追加
              DocumentReference linkRef = firestore.collection('drink_shop_links').doc(linkId);
              batch.set(linkRef, linkData);
              linkCount++;
              
              debugPrint('リンク作成: $shopName - $drinkName');
            }
          }
        }
      }
    }
    
    // バッチ処理を実行
    if (linkCount > 0) {
      await batch.commit();
      debugPrint('$linkCount 件のdrink_shop_linksがFirestoreに追加されました');
    } else {
      debugPrint('作成するリンクがありませんでした');
    }
    
  } catch (e) {
    debugPrint('エラーが発生しました: $e');
    exit(1);
  }
  
  debugPrint('drink_shop_links作成が完了しました！');
  exit(0); // スクリプト終了
}
