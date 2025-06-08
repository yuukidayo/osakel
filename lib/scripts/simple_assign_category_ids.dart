import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// drinksコレクションに対して適当にカテゴリIDを割り当てる簡易スクリプト
void main() async {
  // Flutterの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  print('ドリンクコレクションに簡易カテゴリID割り当てスクリプトを開始します...');
  
  try {
    // Firebaseの初期化
    await Firebase.initializeApp();
    print('Firebase初期化成功');
    
    // Firestoreインスタンスの取得
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // カテゴリIDのマッピング（指定されたID）
    final Map<String, String> categoryMap = {
      'ワイン': '27jxO6AazENRcxylZ2JP',
      'ビール': '8bXjiNMhwduF1pJv5Q8D',
      'ウイスキー': 'WpPcoKe8ZtHDFeV6obSx',
    };
    
    // カテゴリIDのリスト化
    final List<String> categoryIds = categoryMap.values.toList();
    
    // ドリンクコレクションの取得
    print('ドリンクコレクションからデータを取得中...');
    final QuerySnapshot drinksSnapshot = await firestore.collection('drinks').get();
    print('取得したドリンク数: ${drinksSnapshot.docs.length}');
    
    // カウンター初期化
    int updatedCount = 0;
    Map<String, int> categoryUpdateCounts = {};
    for (var id in categoryIds) {
      categoryUpdateCounts[id] = 0;
    }
    
    // バッチ処理の準備
    List<WriteBatch> batches = [firestore.batch()];
    int operationCount = 0;
    int currentBatchIndex = 0;
    
    // ドリンクの処理
    for (var drinkDoc in drinksSnapshot.docs) {
      try {
        final drinkData = drinkDoc.data() as Map<String, dynamic>?;
        final String? drinkName = drinkData?['name'] as String?;
        
        // ランダムにカテゴリIDを選択 (インデックスを計算)
        int categoryIndex = updatedCount % categoryIds.length;
        String selectedCategoryId = categoryIds[categoryIndex];
        
        // バッチ制限チェック
        if (operationCount >= 499) {
          batches.add(firestore.batch());
          currentBatchIndex++;
          operationCount = 0;
        }
        
        // バッチ更新
        batches[currentBatchIndex].update(
          firestore.collection('drinks').doc(drinkDoc.id), 
          {
            'categoryId': selectedCategoryId,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        );
        
        print('${drinkName ?? drinkDoc.id}: カテゴリID割り当て -> $selectedCategoryId');
        updatedCount++;
        operationCount++;
        categoryUpdateCounts[selectedCategoryId] = (categoryUpdateCounts[selectedCategoryId] ?? 0) + 1;
      } catch (e) {
        print('エラー: ${drinkDoc.id} の処理中にエラーが発生しました - ${e.toString()}');
      }
    }
    
    // バッチ処理の実行
    print('ドリンクのカテゴリID更新を実行中...');
    for (int i = 0; i < batches.length; i++) {
      if (i == batches.length - 1 && operationCount == 0) {
        // 最後のバッチが空の場合はスキップ
        break;
      }
      
      print('バッチ ${i+1}/${batches.length} を実行中...');
      await batches[i].commit();
      print('バッチ ${i+1}/${batches.length} 完了');
    }
    
    // 処理結果の表示
    print('=== 処理完了 ===');
    print('総ドリンク数: ${drinksSnapshot.docs.length}');
    print('更新したドリンク数: $updatedCount');
    print('カテゴリ別更新数:');
    for (var entry in categoryMap.entries) {
      final categoryId = entry.value;
      final categoryName = entry.key;
      final count = categoryUpdateCounts[categoryId] ?? 0;
      print('  $categoryName: $count件 (ID: $categoryId)');
    }
    print('==================');
    
  } catch (e) {
    print('スクリプト実行中にエラーが発生しました: ${e.toString()}');
  }
}
