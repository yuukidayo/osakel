import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/category.dart' as model;

class CategoryService {
  final CollectionReference categoriesRef = 
      FirebaseFirestore.instance.collection('categories');
  
  // すべてのカテゴリを取得（order順にソート）
  Future<List<model.Category>> getCategories() async {
    try {
      final QuerySnapshot snapshot = 
          await categoriesRef.orderBy('order').get();
      
      return snapshot.docs.map((doc) {
        return model.Category.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }
  
  // 特定のカテゴリを取得
  Future<model.Category?> getCategory(String categoryId) async {
    try {
      final DocumentSnapshot doc = await categoriesRef.doc(categoryId).get();
      
      if (doc.exists) {
        return model.Category.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching category $categoryId: $e');
      return null;
    }
  }

  // 開発用のモックデータを作成
  List<model.Category> getMockCategories() {
    return [
      model.Category(
        id: 'beer',
        name: 'ビール',
        order: 1,
        imageUrl: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        subcategories: ['craft', 'lager', 'pilsner'],
      ),
      model.Category(
        id: 'sake',
        name: '日本酒',
        order: 2,
        imageUrl: 'https://images.unsplash.com/photo-1579619168343-e9633bad7e74?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        subcategories: ['junmai', 'daiginjo', 'nigori'],
      ),
      model.Category(
        id: 'wine',
        name: 'ワイン',
        order: 3,
        imageUrl: 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        subcategories: ['red', 'white', 'rose', 'sparkling'],
      ),
      model.Category(
        id: 'whisky',
        name: 'ウイスキー',
        order: 4,
        imageUrl: 'https://images.unsplash.com/photo-1527281400683-1aae777175f8?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        subcategories: ['scotch', 'bourbon', 'japanese', 'islay', 'single_malt'],
      ),
      model.Category(
        id: 'cocktails',
        name: 'カクテル',
        order: 5,
        imageUrl: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        subcategories: ['gin', 'vodka', 'rum', 'tequila'],
      ),
    ];
  }
}
