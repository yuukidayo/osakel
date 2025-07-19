class Drink {
  final String id;
  final String name;
  final String categoryId;
  final List<String> subcategories; // サブカテゴリIDの配列
  final String type;
  final String imageUrl;
  final double price;
  final double originalPrice;
  final bool isPR;

  Drink({
    required this.id,
    required this.name,
    required this.categoryId,
    this.subcategories = const [], // 空配列をデフォルト値として設定
    required this.type,
    required this.imageUrl,
    required this.price,
    this.originalPrice = 0.0,
    this.isPR = false,
  });

  /// Firestoreのドキュメントからインスタンスを生成
  factory Drink.fromMap(String docId, Map<String, dynamic> data) {
    // 1. 価格の処理
    double price = _parseNumericValue(data['price']);
    double originalPrice = _parseNumericValue(data['original_price']);
    
    // 2. 画像URLの処理
    String imageUrl = _extractImageUrl(data);
    
    // 3. サブカテゴリ配列の処理
    List<String> subcategories = [];
    if (data['subcategories'] != null) {
      subcategories = List<String>.from(data['subcategories']);
    } else if (data['subcategoryId'] != null && data['subcategoryId'].toString().isNotEmpty) {
      // 後方互換性のため、古い形式のsubcategoryIdを配列の要素として使用
      subcategories = [data['subcategoryId'].toString()];
    }
    
    return Drink(
      id: docId,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategories: subcategories,
      type: data['type'] ?? '',
      imageUrl: imageUrl,
      price: price,
      originalPrice: originalPrice,
      isPR: data['isPR'] ?? false,
    );
  }

  /// Firestoreに保存するためのマップに変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'subcategories': subcategories,
      'type': type,
      'imageUrl': imageUrl,
      'price': price,
      'original_price': originalPrice,
      'isPR': isPR,
    };
  }
  
  // 数値型データを適切にDoubleに変換するヘルパーメソッド
  static double _parseNumericValue(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    
    return 0.0;
  }
  
  // 画像URLを適切に抽出・処理するヘルパーメソッド
  static String _extractImageUrl(Map<String, dynamic> data) {
    String imageUrl = '';
    
    // 大文字のURLフィールドを優先
    if (data['imageURL'] != null) {
      imageUrl = data['imageURL'].toString();
    } else if (data['imageUrl'] != null) {
      imageUrl = data['imageUrl'].toString();
    }
    
    // URLの検証と修正
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      // デフォルト画像
      return 'https://images.unsplash.com/photo-1527281400683-1aae777175f8';
    }
    
    try {
      // URLをパースして有効なURIに変換
      final uri = Uri.parse(imageUrl);
      return uri.toString();
    } catch (e) {
      return 'https://images.unsplash.com/photo-1527281400683-1aae777175f8';
    }
  }
  
  // サブカテゴリIDに基づいてフィルタリングするヘルパーメソッド
  bool hasSubcategory(String subcategoryId) {
    return subcategories.contains(subcategoryId);
  }
}