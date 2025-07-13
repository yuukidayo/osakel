/// ドリンクカテゴリのモデルクラス
class DrinkCategory {
  /// カテゴリID
  final String id;
  
  /// カテゴリ名
  final String name;
  
  /// 表示順序
  final int order;
  
  /// サブカテゴリリスト
  final List<String> subcategories;
  
  /// カテゴリ画像URL
  final String? imageUrl;

  DrinkCategory({
    required this.id,
    required this.name,
    required this.order,
    required this.subcategories,
    this.imageUrl,
  });
  
  /// Firestoreドキュメントからのファクトリコンストラクタ
  factory DrinkCategory.fromFirestore(Map<String, dynamic> doc, String id) {
    // orderフィールドが文字列型やnullの場合に対応
    int order = 0;
    if (doc['order'] != null) {
      if (doc['order'] is int) {
        order = doc['order'];
      } else if (doc['order'] is String) {
        order = int.tryParse(doc['order']) ?? 0;
      }
    }
    
    // サブカテゴリリストの処理
    List<String> subcategories = [];
    if (doc['subcategories'] != null && doc['subcategories'] is List) {
      subcategories = List<String>.from(
        doc['subcategories'].map((item) => item.toString())
      );
    }
    
    return DrinkCategory(
      id: id,
      name: doc['name'] ?? '',
      order: order,
      subcategories: subcategories,
      imageUrl: doc['imageUrl'],
    );
  }
  
  /// 新しいインスタンスを生成（ディープコピー）
  DrinkCategory copyWith({
    String? id,
    String? name,
    int? order,
    List<String>? subcategories,
    String? imageUrl,
  }) {
    return DrinkCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      subcategories: subcategories ?? List<String>.from(this.subcategories),
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
  
  @override
  String toString() {
    return 'DrinkCategory(id: $id, name: $name, order: $order, subcategories: $subcategories)';
  }
}
