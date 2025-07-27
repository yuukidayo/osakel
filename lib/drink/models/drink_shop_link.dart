class DrinkShopLink {
  final String id;
  final String drinkId;
  final String shopId;
  final double price;
  final bool isAvailable;
  final String? note;

  DrinkShopLink({
    required this.id,
    required this.drinkId,
    required this.shopId,
    required this.price,
    required this.isAvailable,
    this.note,
  });

  factory DrinkShopLink.fromMap(String id, Map<String, dynamic> data) {
    return DrinkShopLink(
      id: id,
      drinkId: data['drinkId'] ?? '',
      shopId: data['shopId'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? false,
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drinkId': drinkId,
      'shopId': shopId,
      'price': price,
      'isAvailable': isAvailable,
      'note': note,
    };
  }
  
  /// FirestoreのDocumentSnapshotからDrinkShopLinkオブジェクトを作成
  factory DrinkShopLink.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DrinkShopLink.fromMap(doc.id, data);
  }
  
  /// JSONへ変換（toMapと同じだがidを含む）
  Map<String, dynamic> toJson() {
    final map = toMap();
    map['id'] = id;
    return map;
  }
  
  /// JSONからDrinkShopLinkオブジェクトを生成
  factory DrinkShopLink.fromJson(Map<String, dynamic> json) {
    return DrinkShopLink(
      id: json['id'] ?? '',
      drinkId: json['drinkId'] ?? '',
      shopId: json['shopId'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      isAvailable: json['isAvailable'] ?? false,
      note: json['note'],
    );
  }
}
