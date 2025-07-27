class Category {
  final String id;
  final String name;
  final int order;
  final String imageUrl;
  final List<String> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.order,
    required this.imageUrl,
    required this.subcategories,
  });

  factory Category.fromMap(String docId, Map<String, dynamic> data) {
    // orderフィールドの型変換を適切に処理
    int order;
    if (data['order'] is int) {
      order = data['order'];
    } else if (data['order'] is String) {
      // 文字列の場合は整数に変換を試みる
      order = int.tryParse(data['order']) ?? 0;
    } else {
      order = 0;
    }
    
    return Category(
      id: docId,
      name: data['name'] ?? '',
      order: order,
      imageUrl: data['imageUrl'] ?? '',
      subcategories: List<String>.from(data['subcategories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
      'imageUrl': imageUrl,
      'subcategories': subcategories,
    };
  }
}
