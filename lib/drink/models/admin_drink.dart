import 'package:cloud_firestore/cloud_firestore.dart';

/// 管理者用お酒登録モデル
class AdminDrink {
  final String? id;
  final String nameJapanese;
  final String nameEnglish;
  final String country;
  final String? region;
  final String category;
  final double alcoholPercentage;
  final String? series;
  final String? manufacturer;
  final String? proComment;
  final List<String> shopIds;
  final Map<String, int> shopPrices; // shopId -> price
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminDrink({
    this.id,
    required this.nameJapanese,
    required this.nameEnglish,
    required this.country,
    this.region,
    required this.category,
    required this.alcoholPercentage,
    this.series,
    this.manufacturer,
    this.proComment,
    required this.shopIds,
    required this.shopPrices,
    this.createdAt,
    this.updatedAt,
  });

  /// Firestoreドキュメントから作成
  factory AdminDrink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AdminDrink(
      id: doc.id,
      nameJapanese: data['nameJapanese'] ?? '',
      nameEnglish: data['nameEnglish'] ?? '',
      country: data['country'] ?? '',
      region: data['region'],
      category: data['category'] ?? '',
      alcoholPercentage: (data['alcoholPercentage'] ?? 0.0).toDouble(),
      series: data['series'],
      manufacturer: data['manufacturer'],
      proComment: data['proComment'],
      shopIds: List<String>.from(data['shopIds'] ?? []),
      shopPrices: Map<String, int>.from(data['shopPrices'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestoreドキュメント用のマップに変換
  Map<String, dynamic> toFirestore() {
    return {
      'nameJapanese': nameJapanese,
      'nameEnglish': nameEnglish,
      'country': country,
      if (region != null) 'region': region,
      'category': category,
      'alcoholPercentage': alcoholPercentage,
      if (series != null) 'series': series,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (proComment != null) 'proComment': proComment,
      'shopIds': shopIds,
      'shopPrices': shopPrices,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// バリデーション
  String? validate() {
    if (nameJapanese.trim().isEmpty) {
      return '日本語名称は必須です';
    }
    if (nameEnglish.trim().isEmpty) {
      return '英語名称は必須です';
    }
    if (country.trim().isEmpty) {
      return '生産国は必須です';
    }
    if (category.trim().isEmpty) {
      return 'カテゴリは必須です';
    }
    if (alcoholPercentage < 0 || alcoholPercentage > 100) {
      return 'アルコール度数は0〜100の範囲で入力してください';
    }
    if (shopIds.isEmpty) {
      return '少なくとも1つの店舗を選択してください';
    }
    
    // 選択された店舗すべてに価格が設定されているかチェック
    for (final shopId in shopIds) {
      final price = shopPrices[shopId];
      if (price == null || price <= 0) {
        return '選択された店舗すべてに有効な価格を設定してください';
      }
    }
    
    return null; // バリデーション成功
  }

  /// コピーを作成（一部フィールドを更新）
  AdminDrink copyWith({
    String? id,
    String? nameJapanese,
    String? nameEnglish,
    String? country,
    String? region,
    String? category,
    double? alcoholPercentage,
    String? series,
    String? manufacturer,
    String? proComment,
    List<String>? shopIds,
    Map<String, int>? shopPrices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminDrink(
      id: id ?? this.id,
      nameJapanese: nameJapanese ?? this.nameJapanese,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      country: country ?? this.country,
      region: region ?? this.region,
      category: category ?? this.category,
      alcoholPercentage: alcoholPercentage ?? this.alcoholPercentage,
      series: series ?? this.series,
      manufacturer: manufacturer ?? this.manufacturer,
      proComment: proComment ?? this.proComment,
      shopIds: shopIds ?? this.shopIds,
      shopPrices: shopPrices ?? this.shopPrices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
