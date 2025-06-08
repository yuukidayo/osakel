import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// drink_shop_linksコレクションにカテゴリIDを追加するスクリプト
void main() async {
  print('drink_shop_linksにカテゴリID追加スクリプトを開始します...');
  
  // Firebaseの初期化
  await Firebase.initializeApp();
  print('Firebase初期化成功');
  
  // Firestoreインスタンスの取得
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  try {
    // drink_shop_linksコレクションから全てのドキュメントを取得
    QuerySnapshot linksSnapshot = await firestore.collection('drink_shop_links').get();
    print('取得したリンク数: ${linksSnapshot.docs.length}');
    
    // カテゴリIDの更新を行うカウンター
    int updatedCount = 0;
    int errorCount = 0;
    
    // 各リンクドキュメントに対して処理
    for (var linkDoc in linksSnapshot.docs) {
      try {
        // リンクからドリンクIDを取得
        final data = linkDoc.data() as Map<String, dynamic>?;
        final String? drinkId = data?['drinkId'] as String?;
        
        if (drinkId != null) {
          // ドリンクIDに対応するドリンクドキュメントを取得
          DocumentSnapshot drinkDoc = await firestore.collection('drinks').doc(drinkId).get();
          
          if (drinkDoc.exists) {
            // ドリンクからカテゴリIDを取得
            final drinkData = drinkDoc.data() as Map<String, dynamic>?;
            final String? categoryId = drinkData?['categoryId'] as String?;
            
            if (categoryId != null) {
              // drink_shop_linksドキュメントにカテゴリIDを追加
              await firestore.collection('drink_shop_links').doc(linkDoc.id).update({
                'categoryId': categoryId,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              print('更新成功: LinkID=${linkDoc.id}, DrinkID=${drinkId}, CategoryID=${categoryId}');
              updatedCount++;
            } else {
              print('エラー: ドリンク${drinkId}にカテゴリIDが設定されていません');
              errorCount++;
            }
          } else {
            print('エラー: ドリンク${drinkId}が存在しません');
            errorCount++;
          }
        } else {
          print('エラー: リンク${linkDoc.id}にドリンクIDが設定されていません');
          errorCount++;
        }
      } catch (e) {
        print('処理エラー: ${e.toString()}');
        errorCount++;
      }
    }
    
    print('処理完了！');
    print('更新したリンク数: $updatedCount');
    print('エラー数: $errorCount');
    
  } catch (e) {
    print('スクリプト実行エラー: ${e.toString()}');
  }
}
