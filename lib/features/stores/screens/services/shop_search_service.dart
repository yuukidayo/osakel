import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/shop_search_criteria.dart';
import '../../../../screens/drinks/models/drink_category.dart';
import '../../../../models/shop.dart';

/// お店検索サービスクラス
class ShopSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// カテゴリを読み込む（ドリンク検索と共通）
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

  /// 検索クエリを構築（ShopSearchCriteriaを使用）
  Query<Map<String, dynamic>> buildQuery(ShopSearchCriteria criteria) {
    return _buildQueryFromCriteria(criteria);
  }

  /// 検索条件に基づいてクエリを構築
  Query<Map<String, dynamic>> _buildQueryFromCriteria(ShopSearchCriteria criteria) {
    Query<Map<String, dynamic>> query = _firestore.collection('shops');
    
    // 🔍 デバッグ: 検索条件を出力
    debugPrint('\n🔍 === SHOP SEARCH DEBUG INFO ===');
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
        // サブカテゴリIDが選択されている場合は、配列にそのIDを含むお店を検索
        query = query.where('drink_categories', arrayContains: criteria.selectedSubcategoryId);
        debugPrint('🔎 Adding subcategory filter: drink_categories arrayContains "${criteria.selectedSubcategoryId}"');
      } else {
        debugPrint('🔎 No subcategory filter - showing all shops');
      }
      // サブカテゴリが選択されていない場合はすべてのお店を表示（フィルタリングなし）
    }
    // 特定のカテゴリが選択されている場合
    else {
      debugPrint('🏷️ Query Mode: SPECIFIC CATEGORY');
      // カテゴリIDで検索（drink_categoriesフィールドに対してarray-contains）
      query = query.where('drink_categories', arrayContains: criteria.selectedCategoryId);
      debugPrint('🔎 Adding category filter: drink_categories arrayContains "${criteria.selectedCategoryId}"');
      
      // サブカテゴリIDでさらにフィルタリング（現在は実装しない）
      if (criteria.selectedSubcategoryId != null && criteria.selectedSubcategoryId!.isNotEmpty) {
        // 注意: Firestoreでは同じフィールドに対して複数のarray-containsは使用できない
        // 将来的にはクライアントサイドフィルタリングまたは複合クエリが必要
        debugPrint('🔎 Subcategory filter skipped (Firestore limitation with multiple array-contains)');
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
    if (searchKeyword.isEmpty) {
      return query;
    }
    
    // 店名での部分一致検索（簡易実装）
    // 注意: Firestoreでは完全な部分一致検索は制限があるため、
    // 実際のアプリでは Algolia などの検索サービスを使用することを推奨
    debugPrint('🔎 Adding keyword filter: name >= "$searchKeyword"');
    return query
        .where('name', isGreaterThanOrEqualTo: searchKeyword)
        .where('name', isLessThan: searchKeyword + '\uf8ff');
  }
  
  /// 詳細フィルターを適用（将来の拡張用）
  Query<Map<String, dynamic>> _applyDetailedFilters(
    Query<Map<String, dynamic>> query, 
    Map<String, dynamic> filterValues
  ) {
    // 将来的に地域フィルター、営業時間フィルターなどを実装
    debugPrint('🔎 Detailed filters not implemented yet');
    return query;
  }

  /// 検索を実行してお店リストを取得
  Future<List<Shop>> searchShops(ShopSearchCriteria criteria) async {
    try {
      debugPrint('\n🔍 === SHOP SEARCH EXECUTION ===');
      debugPrint('📋 Executing search with criteria: $criteria');
      
      // クエリを構築
      final query = buildQuery(criteria);
      
      // Firestoreから検索実行
      final querySnapshot = await query.get();
      
      debugPrint('📊 Found ${querySnapshot.docs.length} shops');
      
      // Shopオブジェクトに変換
      final shops = querySnapshot.docs.map((doc) {
        try {
          final shop = Shop.fromMap(doc.id, doc.data());
          debugPrint('✅ Converted shop: ${shop.name}');
          return shop;
        } catch (e) {
          debugPrint('❌ Error converting shop ${doc.id}: $e');
          return null;
        }
      }).where((shop) => shop != null).cast<Shop>().toList();
      
      debugPrint('🎯 Successfully converted ${shops.length} shops');
      return shops;
      
    } catch (e) {
      debugPrint('❌ Shop search error: $e');
      
      // Firestoreインデックスエラーの場合、インデックス作成リンクを表示
      if (e.toString().contains('index')) {
        debugPrint('\n🔗 === FIRESTORE INDEX CREATION REQUIRED ===');
        debugPrint('Please create the required Firestore index by visiting:');
        
        // エラーメッセージからインデックス作成リンクを抽出
        final errorMessage = e.toString();
        final linkMatch = RegExp(r'https://[^\s]+').firstMatch(errorMessage);
        if (linkMatch != null) {
          debugPrint('🔗 Index Creation Link: ${linkMatch.group(0)}');
        } else {
          debugPrint('🔗 Check Firebase Console for index creation requirements');
        }
        debugPrint('=== END INDEX CREATION INFO ===\n');
      }
      
      return [];
    }
  }
}
