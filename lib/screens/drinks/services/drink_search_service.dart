import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/drink_category.dart';
import '../models/drink_search_criteria.dart';

/// ドリンク検索サービスクラス
class DrinkSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// カテゴリを読み込む
  Future<List<DrinkCategory>> loadCategories() async {
    try {
      debugPrint('カテゴリ読み込み開始'); // デバッグ用
      final snap = await _firestore.collection('categories').get();
      debugPrint('カテゴリ取得成功: ${snap.docs.length}件'); // デバッグ用
      
      // ドキュメントの内容をマップに変換し、orderフィールドを追加
      final data = snap.docs.map((doc) {
        final docData = doc.data();
        debugPrint('処理中のカテゴリ: ${doc.id}, データ: $docData'); // デバッグ用
        
        final Map<String, dynamic> item = {
          'id': doc.id,
          ...docData,
        };
        
        // orderフィールドを適切な型に変換
        dynamic orderValue = item['order'];
        if (orderValue == null) {
          item['order'] = 99;
        } else if (orderValue is String) {
          // 文字列の場合は数値に変換を試みる
          item['order'] = int.tryParse(orderValue) ?? 99;
        }
        // それ以外の場合は既存の値を維持（numberのまま）
        
        return item;
      }).toList();
      
      // orderフィールドでソート（安全に型変換）
      data.sort((a, b) {
        int orderA = _parseOrder(a['order']);
        int orderB = _parseOrder(b['order']);
        return orderA.compareTo(orderB);
      });
      
      // DrinkCategoryオブジェクトに変換
      return data.map((item) => DrinkCategory.fromFirestore(item, item['id'])).toList();
    } catch (e) {
      debugPrint('カテゴリ読み込みエラー: $e');
      return [];
    }
  }
  
  /// orderフィールドの値を安全にint型に変換するヘルパーメソッド
  int _parseOrder(dynamic value) {
    if (value == null) return 99;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 99;
    }
    return 99; // デフォルト値
  }

  /// カテゴリに応じたサブカテゴリを取得
  Future<List<dynamic>> getSubcategoriesForCategory(String categoryId) async {
    try {
      if (categoryId == 'すべてのカテゴリ') {
        // すべてのカテゴリの場合は空のサブカテゴリリストを返す
        return [];
      }

      // カテゴリドキュメントを取得
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      
      if (!doc.exists) {
        return [];
      }
      
      final data = doc.data();
      if (data == null) {
        return [];
      }
      
      final subcategories = data['subcategories'];
      if (subcategories == null || subcategories is! List) {
        return [];
      }
      
      return subcategories;
    } catch (e) {
      debugPrint('サブカテゴリ取得エラー: $e');
      return [];
    }
  }

  /// 検索クエリを構築（DrinkSearchCriteriaを使用）
  Query<Map<String, dynamic>> buildQuery(DrinkSearchCriteria criteria) {
    return _buildQueryFromCriteria(criteria);
  }

  /// 検索条件に基づいてクエリを構築
  Query<Map<String, dynamic>> _buildQueryFromCriteria(DrinkSearchCriteria criteria) {
    Query<Map<String, dynamic>> query = _firestore.collection('drinks');
    
    // 🔍 デバッグ: 検索条件を出力
    debugPrint('\n🔍 === SEARCH DEBUG INFO ===');
    debugPrint('📋 Selected Category: "${criteria.selectedCategory}"');
    debugPrint('🆔 Selected Category ID: "${criteria.selectedCategoryId}"');
    debugPrint('🏷️  Selected Subcategory: "${criteria.selectedSubcategory}"');
    debugPrint('🆔 Selected Subcategory ID: "${criteria.selectedSubcategoryId}"');
    debugPrint('🔤 Search Keyword: "${criteria.searchKeyword}"');
    debugPrint('🎛️  Filters Applied: ${criteria.isFiltersApplied}');
    
    // 「すべてのカテゴリ」選択時の処理
    if (criteria.selectedCategory == 'すべてのカテゴリ') {
      debugPrint('🌍 Query Mode: ALL CATEGORIES');
      if (criteria.selectedSubcategoryId != null && criteria.selectedSubcategoryId!.isNotEmpty) {
        // サブカテゴリＩＤが選択されている場合は、配列にそのＩＤを含むドリンクを検索
        query = query.where('subcategories', arrayContains: criteria.selectedSubcategoryId);
        debugPrint('🔎 Adding subcategory filter: subcategories arrayContains "${criteria.selectedSubcategoryId}"');
      } else {
        debugPrint('🔎 No subcategory filter - showing all drinks');
      }
      // サブカテゴリが選択されていない場合はすべてのお酒を表示（フィルタリングなし）
    }
    // 特定のカテゴリが選択されている場合
    else {
      debugPrint('🏷️ Query Mode: SPECIFIC CATEGORY');
      // カテゴリＩＤで検索
      query = query.where('categoryId', isEqualTo: criteria.selectedCategoryId);
      debugPrint('🔎 Adding category filter: categoryId == "${criteria.selectedCategoryId}"');
      
      // サブカテゴリＩＤでさらにフィルタリング
      if (criteria.selectedSubcategoryId != null && criteria.selectedSubcategoryId!.isNotEmpty) {
        query = query.where('subcategories', arrayContains: criteria.selectedSubcategoryId);
        debugPrint('🔎 Adding subcategory filter: subcategories arrayContains "${criteria.selectedSubcategoryId}"');
      } else {
        debugPrint('🔎 No subcategory filter for this category');
      }
    }
    
    // キーワード検索のフィルタリングを適用
    query = _applyKeywordFilter(query, criteria.searchKeyword);
    
    // 詳細フィルターの適用
    if (criteria.isFiltersApplied && criteria.filterValues.isNotEmpty) {
      query = _applyDetailedFilters(query, criteria.filterValues);
    }
    
    // デフォルトのソート順を適用
    query = query.orderBy('name');
    
    // 結果数の制限
    return query.limit(50);
  }

  /// キーワード検索フィルターを適用
  Query<Map<String, dynamic>> _applyKeywordFilter(Query<Map<String, dynamic>> query, String searchKeyword) {
    if (searchKeyword.isEmpty) return query;
    
    // 検索キーワードをトリム
    final String trimmedKeyword = searchKeyword.trim();
    
    // キーワードがある場合は name フィールドで前方一致検索
    // Firebase では完全な部分一致検索ができないため、前方一致検索を行う
    final String endKeyword = trimmedKeyword + '\uf8ff'; // Unicode の最大値を追加
    
    return query.where('name', isGreaterThanOrEqualTo: trimmedKeyword)
               .where('name', isLessThan: endKeyword);
  }

  /// 詳細フィルターを適用
  Query<Map<String, dynamic>> _applyDetailedFilters(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    // 国フィルター
    query = _applyCountryFilter(query, filterValues);
    
    // 地域フィルター
    query = _applyRegionFilter(query, filterValues);
    
    // タイプフィルター
    query = _applyTypeFilter(query, filterValues);
    
    // ぶどう品種フィルター（ワイン用）
    query = _applyGrapeFilter(query, filterValues);
    
    // 味わいフィルター
    query = _applyTasteFilter(query, filterValues);
    
    // ヴィンテージフィルター（ワイン用）
    query = _applyVintageFilter(query, filterValues);
    
    // 熟成年数フィルター
    query = _applyAgingFilter(query, filterValues);
    
    // アルコール度数フィルター
    query = _applyAlcoholRangeFilter(query, filterValues);
    
    // 価格帯フィルター
    query = _applyPriceRangeFilter(query, filterValues);
    
    // 在庫ありフィルター
    query = _applyInStockFilter(query, filterValues);
    
    return query;
  }
  
  /// 国フィルターを適用
  Query<Map<String, dynamic>> _applyCountryFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('country') || 
        (filterValues['country'] as List<String>?)?.isEmpty == true) {
      return query;
    }
    
    final countries = filterValues['country'] as List<String>;
    if (countries.length == 1) {
      return query.where('country', isEqualTo: countries.first);
    } else {
      return query.where('country', arrayContainsAny: countries);
    }
  }
  
  /// 地域フィルターを適用
  Query<Map<String, dynamic>> _applyRegionFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('region') || 
        (filterValues['region'] as List<String>?)?.isEmpty == true) {
      return query;
    }
    
    final regions = filterValues['region'] as List<String>;
    if (regions.length == 1) {
      return query.where('region', isEqualTo: regions.first);
    } else {
      return query.where('region', arrayContainsAny: regions);
    }
  }
  
  /// タイプフィルターを適用
  Query<Map<String, dynamic>> _applyTypeFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('type') || 
        (filterValues['type'] as List<String>?)?.isEmpty == true) {
      return query;
    }
    
    final types = filterValues['type'] as List<String>;
    if (types.length == 1) {
      return query.where('type', isEqualTo: types.first);
    } else {
      return query.where('type', arrayContainsAny: types);
    }
  }
  
  /// ぶどう品種フィルターを適用（ワイン用）
  Query<Map<String, dynamic>> _applyGrapeFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('grape') || 
        (filterValues['grape'] as List<String>?)?.isEmpty == true) {
      return query;
    }
    
    final grapes = filterValues['grape'] as List<String>;
    if (grapes.length == 1) {
      return query.where('grape', isEqualTo: grapes.first);
    } else {
      return query.where('grape', arrayContainsAny: grapes);
    }
  }
  
  /// 味わいフィルターを適用
  Query<Map<String, dynamic>> _applyTasteFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('taste') || 
        (filterValues['taste'] as List<String>?)?.isEmpty == true) {
      return query;
    }
    
    final tastes = filterValues['taste'] as List<String>;
    if (tastes.length == 1) {
      return query.where('taste', isEqualTo: tastes.first);
    } else {
      return query.where('taste', arrayContainsAny: tastes);
    }
  }
  
  /// ヴィンテージフィルターを適用（ワイン用）
  Query<Map<String, dynamic>> _applyVintageFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('vintage') || 
        (filterValues['vintage'] as int?) == null || 
        (filterValues['vintage'] as int) <= 0) {
      return query;
    }
    
    final vintage = filterValues['vintage'] as int;
    return query.where('vintage', isEqualTo: vintage);
  }
  
  /// 熟成年数フィルターを適用
  Query<Map<String, dynamic>> _applyAgingFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('aging') || 
        (filterValues['aging'] as String?) == null || 
        (filterValues['aging'] as String) == 'すべて') {
      return query;
    }
    
    final aging = filterValues['aging'] as String;
    return query.where('aging', isEqualTo: aging);
  }
  
  /// アルコール度数フィルターを適用
  Query<Map<String, dynamic>> _applyAlcoholRangeFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('alcoholRange')) {
      return query;
    }
    
    final alcoholRange = filterValues['alcoholRange'] as RangeValues;
    return query.where('alcoholPercentage', isGreaterThanOrEqualTo: alcoholRange.start)
               .where('alcoholPercentage', isLessThanOrEqualTo: alcoholRange.end);
  }
  
  /// 価格帯フィルターを適用
  Query<Map<String, dynamic>> _applyPriceRangeFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('priceRange')) {
      return query;
    }
    
    final priceRange = filterValues['priceRange'] as RangeValues;
    return query.where('price', isGreaterThanOrEqualTo: priceRange.start.round())
               .where('price', isLessThanOrEqualTo: priceRange.end.round());
  }
  
  /// 在庫ありフィルターを適用
  Query<Map<String, dynamic>> _applyInStockFilter(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    if (!filterValues.containsKey('inStock') || 
        filterValues['inStock'] != true) {
      return query;
    }
    
    return query.where('inStock', isEqualTo: true);
  }
  
  /// デバッグ用: 既存のdrinksコレクションを複製し、subcategories配列を追加する
  Future<String> migrateAndDuplicateDrinksForTesting() async {
    try {
      // カテゴリとサブカテゴリの情報を取得
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final categoryMap = <String, List<dynamic>>{};
      
      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        categoryMap[doc.id] = data['subcategories'] ?? [];
      }
      
      // 既存のドリンクを取得
      final drinksSnapshot = await _firestore.collection('drinks').get();
      var batch = _firestore.batch(); // finalではなくvarに変更
      int count = 0;
      
      for (var doc in drinksSnapshot.docs) {
        final drink = doc.data();
        final categoryId = drink['categoryId'] ?? drink['category'] ?? '';
        
        final availableSubcategories = categoryMap[categoryId] ?? [];
        List<String> selectedSubcategories = [];
        
        if (availableSubcategories.length >= 2) {
          // ランダムに2つ選択
          final shuffled = List.from(availableSubcategories)..shuffle();
          selectedSubcategories = shuffled.take(2).map<String>((sub) {
            return sub is Map ? sub['id'] ?? '' : sub.toString();
          }).toList();
        } else if (availableSubcategories.isNotEmpty) {
          selectedSubcategories = availableSubcategories.map<String>((sub) {
            return sub is Map ? sub['id'] ?? '' : sub.toString();
          }).toList();
        }
        
        // 既存のsubcategoryIdがあれば配列に追加（重複しないように）
        if (drink['subcategoryId'] != null && 
            !selectedSubcategories.contains(drink['subcategoryId'])) {
          selectedSubcategories.add(drink['subcategoryId'].toString());
        }
        
        // 新しいドキュメントIDを生成
        final newDocId = '${doc.id}_duplicated';
        final newDocRef = _firestore.collection('drinks').doc(newDocId);
        
        // 複製したドキュメントを作成
        final Map<String, dynamic> newDrink = Map.from(drink);
        newDrink['subcategories'] = selectedSubcategories;
        
        // バッチに追加
        batch.set(newDocRef, newDrink);
        
        count++;
        
        // Firestoreのバッチ制限（500）に達したらコミット
        if (count % 400 == 0) {
          await batch.commit();
          debugPrint('Committed batch of $count documents.');
          batch = _firestore.batch(); // 新しいバッチを作成
        }
      }
      
      // 残りをコミット
      if (count % 400 != 0) {
        await batch.commit();
      }
      
      return 'Successfully migrated and duplicated $count drinks.';
    } catch (error) {
      debugPrint('Error during migration: $error');
      return 'Migration failed: ${error.toString()}';
    }
  }
}
