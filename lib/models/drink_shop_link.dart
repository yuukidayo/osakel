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
}
