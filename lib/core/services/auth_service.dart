import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー権限の列挙型
enum UserRole {
  admin('admin', '管理者'),
  user('user', '一般ユーザー'),
  shopOwner('shop_owner', '店舗ユーザー'),
  unknown('unknown', '不明');

  const UserRole(this.value, this.displayName);
  final String value;
  final String displayName;

  static UserRole fromString(String? role) {
    switch (role) {
      case 'admin':
      case '管理者':
        return UserRole.admin;
      case 'user':
      case '一般ユーザー':
        return UserRole.user;
      case 'shop_owner':
      case '店舗ユーザー':
        return UserRole.shopOwner;
      default:
        return UserRole.unknown;
    }
  }
}

/// ユーザー権限管理サービス
/// 3つの権限レベル（admin, user, shop_owner）に対応
class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザー情報を取得
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('🚫 ユーザーがログインしていません');
        return null;
      }

      print('👤 現在のユーザー: ${user.uid}');
      
      // ユーザードキュメントを取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        print('🚫 ユーザードキュメントが見つかりません: ${user.uid}');
        return null;
      }

      final userData = userDoc.data();
      print('📊 ユーザーデータ: $userData');
      return userData;
    } catch (e) {
      print('❌ ユーザーデータ取得エラー: $e');
      return null;
    }
  }

  /// 現在のユーザーの権限を取得
  static Future<UserRole> getCurrentUserRole() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return UserRole.unknown;

      final roleString = userData['role'] as String?;
      final role = UserRole.fromString(roleString);
      
      print('🔑 ユーザーロール: ${role.displayName} (${role.value})');
      return role;
    } catch (e) {
      print('❌ ユーザーロール取得エラー: $e');
      return UserRole.unknown;
    }
  }

  /// 管理者権限チェック
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    final isAdminUser = role == UserRole.admin;
    print('👑 管理者権限: $isAdminUser');
    return isAdminUser;
  }

  /// 一般ユーザー権限チェック
  static Future<bool> isUser() async {
    final role = await getCurrentUserRole();
    final isRegularUser = role == UserRole.user;
    print('👤 一般ユーザー権限: $isRegularUser');
    return isRegularUser;
  }

  /// 店舗ユーザー権限チェック
  static Future<bool> isShopOwner() async {
    final role = await getCurrentUserRole();
    final isShopOwnerUser = role == UserRole.shopOwner;
    print('🏪 店舗ユーザー権限: $isShopOwnerUser');
    return isShopOwnerUser;
  }

  /// 認証済みユーザーかチェック（ログイン済み）
  static Future<bool> isAuthenticated() async {
    final user = _auth.currentUser;
    final role = await getCurrentUserRole();
    final isAuth = user != null && role != UserRole.unknown;
    print('🔐 認証済み: $isAuth');
    return isAuth;
  }

  /// 特定の店舗の所有者かチェック
  static Future<bool> isOwnerOfShop(String shopId) async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      final role = UserRole.fromString(userData['role'] as String?);
      if (role != UserRole.shopOwner) return false;

      final userShopId = userData['shopId'] as String?;
      final isOwner = userShopId == shopId;
      print('🏪 店舗所有者チェック: $isOwner (shopId: $shopId)');
      return isOwner;
    } catch (e) {
      print('❌ 店舗所有者チェックエラー: $e');
      return false;
    }
  }

  /// 現在のユーザーの店舗IDを取得（店舗ユーザーの場合）
  static Future<String?> getCurrentUserShopId() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return null;

      final role = UserRole.fromString(userData['role'] as String?);
      if (role != UserRole.shopOwner) return null;

      final shopId = userData['shopId'] as String?;
      print('🏪 ユーザーの店舗ID: $shopId');
      return shopId;
    } catch (e) {
      print('❌ 店舗ID取得エラー: $e');
      return null;
    }
  }

  /// 権限に応じた操作可能性をチェック
  static Future<Map<String, bool>> getPermissions() async {
    final role = await getCurrentUserRole();
    
    final permissions = {
      'canViewShops': true, // 誰でも店舗閲覧可能
      'canViewDrinks': true, // 誰でもお酒閲覧可能
      'canCreateShops': role == UserRole.admin,
      'canCreateDrinks': role == UserRole.admin,
      'canEditAllShops': role == UserRole.admin,
      'canEditOwnShop': role == UserRole.admin || role == UserRole.shopOwner,
      'canDeleteShops': role == UserRole.admin,
      'canDeleteDrinks': role == UserRole.admin,
      'canPostComments': role != UserRole.unknown,
      'canManageUsers': role == UserRole.admin,
      'canUploadShopImages': role == UserRole.admin || role == UserRole.shopOwner,
      'canUploadDrinkImages': role == UserRole.admin,
    };

    print('🔑 ユーザー権限一覧: $permissions');
    return permissions;
  }

  /// ログアウト
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('👋 ログアウト完了');
    } catch (e) {
      print('❌ ログアウトエラー: $e');
      rethrow;
    }
  }

  /// ユーザー登録時の権限設定（管理者用）
  static Future<void> setUserRole(String userId, UserRole role, {String? shopId}) async {
    try {
      final userData = {
        'uid': userId,
        'role': role.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 店舗ユーザーの場合はshopIdも設定
      if (role == UserRole.shopOwner && shopId != null) {
        userData['shopId'] = shopId;
      }

      await _firestore.collection('users').doc(userId).update(userData);
      print('✅ ユーザー権限設定完了: ${role.displayName}');
    } catch (e) {
      print('❌ ユーザー権限設定エラー: $e');
      rethrow;
    }
  }

  /// 新規ユーザー作成時のデフォルト権限設定
  static Future<void> createUserWithRole(
    String userId, 
    String email, 
    String displayName, 
    {UserRole role = UserRole.user, String? shopId}
  ) async {
    try {
      final userData = {
        'uid': userId,
        'email': email,
        'displayName': displayName,
        'role': role.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 店舗ユーザーの場合はshopIdも設定
      if (role == UserRole.shopOwner && shopId != null) {
        userData['shopId'] = shopId;
      }

      await _firestore.collection('users').doc(userId).set(userData);
      print('✅ 新規ユーザー作成完了: ${role.displayName}');
    } catch (e) {
      print('❌ 新規ユーザー作成エラー: $e');
      rethrow;
    }
  }
}
