// Userモデルクラス

class User {
  final String id;
  final String name;
  final String role; // "プロ" or other roles
  final String? shopId; // Optional, may be null for regular users

  User({
    required this.id,
    required this.name,
    required this.role,
    this.shopId,
  });

  factory User.fromMap(String docId, Map<String, dynamic> data) {
    return User(
      id: docId,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      shopId: data['shopId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      if (shopId != null) 'shopId': shopId,
    };
  }

  bool isPro() {
    return role == 'プロ';
  }
}
