import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// drink_shop_linksコレクションに関連するドリンクのカテゴリIDを追加するスクリプト
void main() async {
  // Flutter初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('drink_shop_linksコレクション更新スクリプトを開始します...');
  
  try {
    // Firebaseの初期化
    await Firebase.initializeApp();
    debugPrint('Firebase初期化成功');
    
    // Firestoreインスタンスの取得
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // カウンター初期化
    int totalLinks = 0;
    int updatedLinks = 0;
    int errorLinks = 0;
    
    // drink_shop_linksコレクションから全てのドキュメントを取得
    debugPrint('drink_shop_linksコレクションのドキュメントを取得中...');
    final QuerySnapshot linksSnapshot = await firestore.collection('drink_shop_links').get();
    totalLinks = linksSnapshot.docs.length;
    debugPrint('取得したリンク数: $totalLinks');
    
    // バッチ処理の準備
    // Firestoreのバッチ処理は最大500件までなので、必要に応じて複数のバッチを作成
    List<WriteBatch> batches = [firestore.batch()];
    int operationCount = 0;
    int currentBatchIndex = 0;
    
    // 各リンクドキュメントについて処理
    for (var linkDoc in linksSnapshot.docs) {
      try {
        Map<String, dynamic>? linkData = linkDoc.data() as Map<String, dynamic>?;
        String? drinkId = linkData?['drinkId'] as String?;
        
        if (drinkId != null) {
          // ドリンクドキュメントを取得して、カテゴリIDを取得
          DocumentSnapshot drinkDoc = await firestore.collection('drinks').doc(drinkId).get();
          
          if (drinkDoc.exists) {
            Map<String, dynamic>? drinkData = drinkDoc.data() as Map<String, dynamic>?;
            String? categoryId = drinkData?['categoryId'] as String?;
            
            if (categoryId != null) {
              // バッチ処理に追加
              if (operationCount >= 499) {
                // 新しいバッチを作成
                batches.add(firestore.batch());
                currentBatchIndex++;
                operationCount = 0;
              }
              
              // カテゴリIDとタイムスタンプを更新
              batches[currentBatchIndex].update(
                firestore.collection('drink_shop_links').doc(linkDoc.id), 
                {
                  'categoryId': categoryId,
                  'updatedAt': FieldValue.serverTimestamp(),
                }
              );
              
              operationCount++;
              updatedLinks++;
              
              if (updatedLinks % 100 == 0) {
                debugPrint('$updatedLinks 件のリンクを処理しました...');
              }
            } else {
              debugPrint('警告: ドリンク $drinkId にカテゴリIDがありません');
              errorLinks++;
            }
          } else {
            debugPrint('警告: ドリンク $drinkId が存在しません');
            errorLinks++;
          }
        } else {
          debugPrint('警告: リンク ${linkDoc.id} にdrinkIdがありません');
          errorLinks++;
        }
      } catch (e) {
        debugPrint('エラー: リンク処理中にエラーが発生しました - ${e.toString()}');
        errorLinks++;
      }
    }
    
    // バッチ処理の実行
    debugPrint('リンクの更新を実行中...');
    int batchIndex = 1;
    for (var batch in batches) {
      if (operationCount > 0) {
        debugPrint('バッチ $batchIndex/${batches.length} を実行中...');
        await batch.commit();
        debugPrint('バッチ $batchIndex/${batches.length} 完了');
        batchIndex++;
      }
    }
    
    // 処理結果の表示
    debugPrint('=== 処理完了 ===');
    debugPrint('総リンク数: $totalLinks');
    debugPrint('更新したリンク数: $updatedLinks');
    debugPrint('エラー数: $errorLinks');
    debugPrint('==================');
    
  } catch (e) {
    debugPrint('スクリプト実行中にエラーが発生しました: ${e.toString()}');
  }
}
