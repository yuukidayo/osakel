import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

/// 権限ベースのルート保護ガードウィジェット
/// 3つの権限レベル（admin, user, shop_owner）に対応
class PermissionGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final List<UserRole> allowedRoles;
  final String? requiredShopId; // 店舗オーナーの場合の特定店舗ID

  const PermissionGuard({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.fallbackWidget,
    this.requiredShopId,
  }) : super(key: key);

  /// 管理者専用ガード（既存のAdminGuardと互換性維持）
  PermissionGuard.adminOnly({
    Key? key,
    required this.child,
    this.fallbackWidget,
  }) : allowedRoles = [UserRole.admin],
       requiredShopId = null,
       super(key: key);

  /// 認証ユーザー専用ガード
  PermissionGuard.authenticatedOnly({
    Key? key,
    required this.child,
    this.fallbackWidget,
  }) : allowedRoles = [
         UserRole.admin,
         UserRole.user,
         UserRole.shopOwner
       ],
       requiredShopId = null,
       super(key: key);

  /// 店舗オーナー専用ガード（特定店舗）
  PermissionGuard.shopOwnerOnly({
    Key? key,
    required this.child,
    required this.requiredShopId,
    this.fallbackWidget,
  }) : allowedRoles = [
         UserRole.admin,
         UserRole.shopOwner
       ],
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermission(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラーが発生しました: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            ),
          );
        }

        final hasPermission = snapshot.data ?? false;
        
        if (hasPermission) {
          return child;
        } else {
          return fallbackWidget ?? _buildAccessDeniedScreen(context);
        }
      },
    );
  }

  /// 権限チェックロジック
  Future<bool> _checkPermission() async {
    try {
      final currentRole = await AuthService.getCurrentUserRole();
      
      // 許可された権限リストに含まれているかチェック
      if (!allowedRoles.contains(currentRole)) {
        debugPrint('🚫 権限不足: 現在の権限=${currentRole.name}, 必要な権限=${allowedRoles.map((r) => r.name).join(', ')}');
        return false;
      }

      // 店舗オーナーの場合、特定店舗の所有者かチェック
      if (requiredShopId != null && currentRole == UserRole.shopOwner) {
        final isOwner = await AuthService.isOwnerOfShop(requiredShopId!);
        if (!isOwner) {
          debugPrint('🚫 店舗所有者権限不足: shopId=$requiredShopId');
          return false;
        }
      }

      debugPrint('✅ 権限チェック通過: ${currentRole.name}');
      return true;
    } catch (e) {
      debugPrint('❌ 権限チェックエラー: $e');
      return false;
    }
  }

  /// アクセス拒否画面
  Widget _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アクセス拒否'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'アクセス権限がありません',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'この機能を利用するには適切な権限が必要です。\n必要な権限: ${allowedRoles.map((r) => r.name).join('、')}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('戻る'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showContactInfo(context),
                    icon: const Icon(Icons.contact_support),
                    label: const Text('お問い合わせ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// お問い合わせ情報表示
  void _showContactInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お問い合わせ'),
        content: const Text(
          '権限に関するお問い合わせは、\nアプリ管理者までご連絡ください。\n\nメール: admin@osakel.app\n電話: 03-1234-5678',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// 権限チェック用のヘルパークラス
class PermissionChecker {
  /// 管理者権限チェック（既存のAdminService.isAdmin()と互換性維持）
  static Future<bool> isAdmin() => AuthService.isAdmin();

  /// 認証済みユーザーチェック
  static Future<bool> isAuthenticated() => AuthService.isAuthenticated();

  /// 店舗オーナーチェック
  static Future<bool> isShopOwner() => AuthService.isShopOwner();

  /// 特定店舗の所有者チェック
  static Future<bool> isOwnerOfShop(String shopId) => AuthService.isOwnerOfShop(shopId);

  /// 権限に応じたUI表示制御用
  static Future<Map<String, bool>> getPermissions() => AuthService.getPermissions();
}
