class Drink {
  final String id;
  final String name;
  final String categoryId;
  final String subcategoryId;
  final String type; // サブカテゴリと同じ値を持つことが多いが、より詳細な種類を表す
  final String imageUrl;
  final double price;
  final double originalPrice; // 元の価格
  final bool isPR;

  Drink({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.subcategoryId,
    required this.type,
    required this.imageUrl,
    required this.price,
    this.originalPrice = 0.0,
    this.isPR = false,
  });

  factory Drink.fromMap(String docId, Map<String, dynamic> data) {
    // デバッグ出力
    print('ドリンクデータ: $docId');
    print('データ全体: $data');
    print('imageUrlフィールド: ${data['imageUrl']}');
    print('imageURLフィールド: ${data['imageURL']}');
    // priceフィールドの型変換を適切に処理
    double price;
    if (data['price'] is double) {
      price = data['price'];
    } else if (data['price'] is int) {
      price = (data['price'] as int).toDouble();
    } else if (data['price'] is String) {
      price = double.tryParse(data['price']) ?? 0.0;
    } else {
      price = 0.0;
    }
    
    // original_priceフィールドの型変換を適切に処理
    double originalPrice;
    if (data['original_price'] is double) {
      originalPrice = data['original_price'];
    } else if (data['original_price'] is int) {
      originalPrice = (data['original_price'] as int).toDouble();
    } else if (data['original_price'] is String) {
      originalPrice = double.tryParse(data['original_price']) ?? 0.0;
    } else {
      originalPrice = 0.0;
    }
    
    // imageUrlを取得し、必要に応じてエンコード
    String imageUrl = '';
    // imageUrlとimageURLの両方のフィールドをチェック
    if (data['imageURL'] != null) {
      // 大文字のURLフィールドを優先
      imageUrl = data['imageURL'].toString();
      print('大文字のimageURLフィールドから画像を取得: $imageUrl');
    } else if (data['imageUrl'] != null) {
      // 小文字のurlフィールドを次にチェック
      imageUrl = data['imageUrl'].toString();
      print('小文字のimageUrlフィールドから画像を取得: $imageUrl');
    }
    
    // URLが空または不正な場合の処理
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      // 画像データが存在しないか、無効なURLの場合はデフォルト画像を使用
      print('無効な画像URL、デフォルト画像を使用: $imageUrl');
      imageUrl = 'https://images.unsplash.com/photo-1527281400683-1aae777175f8';
    } else {
      try {
        // URLをデコードしてから再エンコード（特殊文字の処理）
        final uri = Uri.parse(imageUrl);
        imageUrl = uri.toString();
        print('エンコード後のURL: $imageUrl');
      } catch (e) {
        print('画像URLのパースエラー: $e');
        imageUrl = 'https://images.unsplash.com/photo-1527281400683-1aae777175f8';
      }
    }
    
    return Drink(
      id: docId,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      type: data['type'] ?? '',
      imageUrl: imageUrl,
      price: price,
      originalPrice: originalPrice,
      isPR: data['isPR'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'type': type,
      'imageUrl': imageUrl,
      'price': price,
      'original_price': originalPrice,
      'isPR': isPR,
    };
  }
}
