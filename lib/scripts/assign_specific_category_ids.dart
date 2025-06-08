import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 特定のカテゴリIDをdrinksコレクションに割り当てるスクリプト
void main() async {
  // Flutterの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  print('ドリンクコレクションに特定のカテゴリIDを割り当てるスクリプトを開始します...');
  
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
    
    // 英語表記や別名のマッピング
    final Map<String, String> typeToCategory = {
      'wine': 'ワイン',
      'beer': 'ビール',
      'whisky': 'ウイスキー',
      'whiskey': 'ウイスキー',
    };
    
    // ドリンクコレクションの取得
    print('ドリンクコレクションからデータを取得中...');
    final QuerySnapshot drinksSnapshot = await firestore.collection('drinks').get();
    print('取得したドリンク数: ${drinksSnapshot.docs.length}');
    
    // カウンター初期化
    int updatedCount = 0;
    int noMatchCount = 0;
    int skippedCount = 0;
    Map<String, int> categoryUpdateCounts = {};
    
    // バッチ処理の準備
    List<WriteBatch> batches = [firestore.batch()];
    int operationCount = 0;
    int currentBatchIndex = 0;
    
    // ドリンクの処理
    for (var drinkDoc in drinksSnapshot.docs) {
      try {
        final drinkData = drinkDoc.data() as Map<String, dynamic>?;
        final String? drinkName = drinkData?['name'] as String?;
        final String? drinkType = drinkData?['type'] as String?;
        
        String? matchedCategory;
        
        // 1. タイプから直接カテゴリを判別
        if (drinkType != null) {
          String normalizedType = drinkType.toLowerCase().trim();
          if (typeToCategory.containsKey(normalizedType)) {
            matchedCategory = typeToCategory[normalizedType];
          } else {
            // カテゴリ名と直接一致するかチェック
            for (var category in categoryMap.keys) {
              if (normalizedType == category.toLowerCase()) {
                matchedCategory = category;
                break;
              }
            }
          }
        }
        
        // 2. ドリンク名から判別（タイプで特定できなかった場合）
        if (matchedCategory == null && drinkName != null) {
          String normalizedName = drinkName.toLowerCase();
          
          for (var entry in typeToCategory.entries) {
            if (normalizedName.contains(entry.key)) {
              matchedCategory = entry.value;
              break;
            }
          }
          
          if (matchedCategory == null) {
            for (var category in categoryMap.keys) {
              if (normalizedName.contains(category.toLowerCase())) {
                matchedCategory = category;
                break;
              }
            }
          }
        }
        
        // カテゴリが特定できた場合、更新
        if (matchedCategory != null && categoryMap.containsKey(matchedCategory)) {
          String newCategoryId = categoryMap[matchedCategory]!;
          
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
              'categoryId': newCategoryId,
              'updatedAt': FieldValue.serverTimestamp(),
            }
          );
          
          print('$drinkName: カテゴリID割り当て -> $matchedCategory (ID: $newCategoryId)');
          updatedCount++;
          operationCount++;
          
          // カテゴリごとの更新カウントを増やす
          categoryUpdateCounts[matchedCategory] = (categoryUpdateCounts[matchedCategory] ?? 0) + 1;
        } else {
          if (drinkName != null) {
            print('警告: $drinkName のカテゴリを特定できませんでした');
          } else {
            print('警告: 名前のないドリンク(ID: ${drinkDoc.id})のカテゴリを特定できませんでした');
          }
          noMatchCount++;
        }
      } catch (e) {
        print('エラー: ${drinkDoc.id} の処理中にエラーが発生しました - ${e.toString()}');
        skippedCount++;
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
    categoryUpdateCounts.forEach((category, count) {
      print('  $category: $count件 (ID: ${categoryMap[category]})');
    });
    print('カテゴリ不明のドリンク: $noMatchCount件');
    print('エラーでスキップしたドリンク: $skippedCount件');
    print('==================');
    
  } catch (e) {
    print('スクリプト実行中にエラーが発生しました: ${e.toString()}');
  }
}
