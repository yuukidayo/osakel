import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ドリンクコレクションのカテゴリIDを、正しいカテゴリドキュメントIDに更新するスクリプト
void main() async {
  // Flutterの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('ドリンクコレクションのカテゴリID更新スクリプトを開始します...');
  
  try {
    // Firebaseの初期化
    await Firebase.initializeApp();
    debugPrint('Firebase初期化成功');
    
    // Firestoreインスタンスの取得
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // カテゴリコレクションの取得
    debugPrint('カテゴリコレクションからデータを取得中...');
    final QuerySnapshot categoriesSnapshot = await firestore.collection('categories').get();
    debugPrint('取得したカテゴリ数: ${categoriesSnapshot.docs.length}');
    
    // カテゴリ名とIDのマッピングを作成
    Map<String, String> categoryNameToIdMap = {};
    Map<String, String> categoryDisplayNameToIdMap = {};
    
    for (var categoryDoc in categoriesSnapshot.docs) {
      final categoryData = categoryDoc.data() as Map<String, dynamic>?;
      final String? categoryName = categoryData?['name'] as String?;
      final String? displayName = categoryData?['displayName'] as String?;
      
      if (categoryName != null) {
        categoryNameToIdMap[categoryName.toLowerCase()] = categoryDoc.id;
        debugPrint('カテゴリマップ追加: ${categoryName.toLowerCase()} -> ${categoryDoc.id}');
      }
      
      if (displayName != null) {
        categoryDisplayNameToIdMap[displayName.toLowerCase()] = categoryDoc.id;
        debugPrint('表示名マップ追加: ${displayName.toLowerCase()} -> ${categoryDoc.id}');
      }
    }
    
    // 一般的なカテゴリ名の別名マップを追加（必要に応じて拡張）
    Map<String, String> categoryAliases = {
      'whisky': 'ウイスキー',
      'whiskey': 'ウイスキー',
      'beer': 'ビール',
      'wine': 'ワイン',
      'sake': '日本酒',
      'shochu': '焼酎',
      'cocktail': 'カクテル',
      'liqueur': 'リキュール',
      'gin': 'ジン',
      'vodka': 'ウォッカ',
      'rum': 'ラム',
      'tequila': 'テキーラ',
      'brandy': 'ブランデー',
    };
    
    // カテゴリIDマップを拡張（英語名→日本語名→カテゴリID）
    Map<String, String> expandedCategoryMap = Map.from(categoryNameToIdMap);
    categoryAliases.forEach((alias, name) {
      final japName = name.toLowerCase();
      if (categoryNameToIdMap.containsKey(japName) && !expandedCategoryMap.containsKey(alias)) {
        expandedCategoryMap[alias] = categoryNameToIdMap[japName]!;
        debugPrint('別名マップ追加: $alias -> ${categoryNameToIdMap[japName]}');
      }
    });
    
    // ドリンクコレクションの取得
    debugPrint('ドリンクコレクションからデータを取得中...');
    final QuerySnapshot drinksSnapshot = await firestore.collection('drinks').get();
    debugPrint('取得したドリンク数: ${drinksSnapshot.docs.length}');
    
    // 更新カウンター
    int updatedCount = 0;
    int errorCount = 0;
    int noChangeCount = 0;
    
    // バッチ処理の準備
    List<WriteBatch> batches = [firestore.batch()];
    int operationCount = 0;
    int currentBatchIndex = 0;
    
    // ドリンクの処理
    for (var drinkDoc in drinksSnapshot.docs) {
      try {
        final drinkData = drinkDoc.data() as Map<String, dynamic>?;
        final String? currentCategoryId = drinkData?['categoryId'] as String?;
        final String? drinkName = drinkData?['name'] as String?;
        final String? drinkType = drinkData?['type'] as String?;
        
        // ドリンクの種類またはタイプから正しいカテゴリIDを推測
        String? newCategoryId;
        
        // 1. まず現在のcategoryIdがカテゴリコレクションに実際に存在するか確認
        if (currentCategoryId != null) {
          bool categoryExists = categoriesSnapshot.docs.any((doc) => doc.id == currentCategoryId);
          if (categoryExists) {
            // もし存在するなら、それは既に正しいので変更しない
            debugPrint('$drinkName: カテゴリID $currentCategoryId は既に正しいです');
            noChangeCount++;
            continue;
          }
        }
        
        // 2. drinkTypeからカテゴリを推測
        if (drinkType != null) {
          String normalizedType = drinkType.toLowerCase().trim();
          
          // 拡張されたマップから検索
          if (expandedCategoryMap.containsKey(normalizedType)) {
            newCategoryId = expandedCategoryMap[normalizedType];
          } 
          // 表示名からも検索
          else if (categoryDisplayNameToIdMap.containsKey(normalizedType)) {
            newCategoryId = categoryDisplayNameToIdMap[normalizedType];
          }
        }
        
        // 3. ドリンク名に含まれるキーワードからカテゴリを推測（最後の手段）
        if (newCategoryId == null && drinkName != null) {
          String normalizedName = drinkName.toLowerCase();
          
          // 各カテゴリ名/別名でチェック
          for (var entry in expandedCategoryMap.entries) {
            if (normalizedName.contains(entry.key)) {
              newCategoryId = entry.value;
              break;
            }
          }
          
          // 表示名でもチェック
          if (newCategoryId == null) {
            for (var entry in categoryDisplayNameToIdMap.entries) {
              if (normalizedName.contains(entry.key)) {
                newCategoryId = entry.value;
                break;
              }
            }
          }
        }
        
        // カテゴリIDが特定できた場合、更新
        if (newCategoryId != null && (currentCategoryId == null || currentCategoryId != newCategoryId)) {
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
          
          debugPrint('$drinkName: カテゴリID更新 ${currentCategoryId ?? "なし"} -> $newCategoryId');
          updatedCount++;
          operationCount++;
        } else {
          if (newCategoryId == null) {
            debugPrint('警告: $drinkName のカテゴリを特定できません');
            errorCount++;
          } else {
            noChangeCount++;
          }
        }
      } catch (e) {
        debugPrint('エラー: ${drinkDoc.id} の処理中にエラーが発生しました - ${e.toString()}');
        errorCount++;
      }
    }
    
    // バッチ処理の実行
    debugPrint('ドリンクのカテゴリID更新を実行中...');
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
    debugPrint('総ドリンク数: ${drinksSnapshot.docs.length}');
    debugPrint('更新したドリンク数: $updatedCount');
    debugPrint('変更なしドリンク数: $noChangeCount');
    debugPrint('エラー数: $errorCount');
    debugPrint('==================');
    
  } catch (e) {
    debugPrint('スクリプト実行中にエラーが発生しました: ${e.toString()}');
  }
}
