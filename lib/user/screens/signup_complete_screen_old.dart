import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'dart:async';

import '../../shared/screens/main_screen.dart';

class SignUpCompleteScreen extends StatefulWidget {
  final String email;
  
  const SignUpCompleteScreen({
    super.key,
    required this.email,
  });

  @override
  State<SignUpCompleteScreen> createState() => _SignUpCompleteScreenState();
}

class _SignUpCompleteScreenState extends State<SignUpCompleteScreen> {


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 包括的な認証状態監視の設定
  void _setupComprehensiveAuthMonitoring() {
    developer.log('🔄 包括的な認証状態監視を開始');
    
    // 1. リアルタイム認証状態監視
    _setupRealtimeAuthMonitoring();
    
    // 2. 定期的な認証状態チェック
    _setupPeriodicAuthCheck();
    
    // 3. 初回状態確認
    _performInitialAuthCheck();
  }

  /// リアルタイム認証状態監視
  void _setupRealtimeAuthMonitoring() {
    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) {
        developer.log('🔄 認証状態変更を検知: user=${user?.email}, emailVerified=${user?.emailVerified}');
        
        if (user != null && user.emailVerified) {
          developer.log('✅ メール認証完了を検知 - MainScreenへ遷移');
          _updateDebugInfo('✅ メール認証完了検知 - 遷移中...');
          _navigateToMainScreen();
        } else if (user != null) {
          _updateDebugInfo('👤 ユーザー存在、認証待ち: ${user.email}');
        } else {
          _updateDebugInfo('❌ ユーザーなし');
        }
      },
      onError: (error) {
        developer.log('❌ 認証状態監視エラー: $error');
        _updateDebugInfo('❌ 認証状態監視エラー: $error');
      },
    );
  }

  /// 定期的な認証状態チェック（通常モード）
  void _setupPeriodicAuthCheck() {
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isIntensiveMode) {
        _performAuthStateCheck('定期チェック');
      }
    });
  }

  /// 集中的な認証状態チェック開始（アプリ復帰時）
  void _startIntensiveAuthCheck() {
    _isIntensiveMode = true;
    _intensiveCheckCount = 0;
    
    // 1秒間隔で30回（30秒間）集中チェック
    _intensiveCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _intensiveCheckCount++;
      _performAuthStateCheck('集中チェック($_intensiveCheckCount/30)');
      
      if (_intensiveCheckCount >= 30) {
        _stopIntensiveAuthCheck();
      }
    });
  }

  /// 集中的な認証状態チェック停止
  void _stopIntensiveAuthCheck() {
    _isIntensiveMode = false;
    _intensiveCheckTimer?.cancel();
    _intensiveCheckTimer = null;
    developer.log('🔄 集中的な認証状態チェック終了');
  }

  /// 初回認証状態確認
  void _performInitialAuthCheck() {
    developer.log('🔄 初回認証状態確認');
    _performAuthStateCheck('初回確認');
  }

  /// デバッグ情報を更新
  void _updateDebugInfo(String info) {
    if (mounted) {
      setState(() {
        _debugInfo = info;
        _lastCheckTime = DateTime.now();
      });
      developer.log('🔍 デバッグ: $info');
    }
  }

  /// 認証状態チェック実行
  Future<void> _performAuthStateCheck(String checkType) async {
    try {
      _lastCheckTime = DateTime.now();
      _periodicCheckCount++;
      
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('❌ [$checkType] currentUserがnull');
        return;
      }
      
      developer.log('🔄 [$checkType] 認証状態確認: ${user.email}');
      
      // ユーザー情報を強制的に最新化
      await user.reload();
      final refreshedUser = _auth.currentUser;
      
      if (refreshedUser != null && refreshedUser.emailVerified) {
        developer.log('✅ [$checkType] メール認証完了を検知 - MainScreenへ遷移');
        _updateDebugInfo('✅ [$checkType] メール認証完了 - 遷移中...');
        _navigateToMainScreen();
        return;
      }
      
      // 認証トークンも強制更新
      try {
        await refreshedUser?.getIdToken(true);
        final tokenRefreshedUser = _auth.currentUser;
        
        if (tokenRefreshedUser != null && tokenRefreshedUser.emailVerified) {
          developer.log('✅ [$checkType] トークン更新後にメール認証完了を検知');
          _updateDebugInfo('✅ [$checkType] トークン更新後認証完了');
          _navigateToMainScreen();
          return;
        }
      } catch (e) {
        developer.log('⚠️ [$checkType] トークン更新エラー: $e');
      }
      
      _updateDebugInfo('🔄 [$checkType] 認証待ち (${_periodicCheckCount}回目)');
      
    } catch (e) {
      developer.log('❌ [$checkType] 認証状態チェックエラー: $e');
      _updateDebugInfo('❌ [$checkType] チェックエラー: $e');
    }
  }

  /// Firebase Console状態確認
  Future<void> _checkFirebaseConsoleStatus() async {
    developer.log('🔍 Firebase Console状態確認開始');
    _updateDebugInfo('🔍 Firebase Console状態確認中...');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('❌ currentUserがnull - Firebase Console確認不可');
        _updateDebugInfo('❌ currentUserがnull - 確認不可');
        return;
      }
      
      developer.log('🔍 === Firebase Console状態詳細情報 ===');
      developer.log('📧 Email: ${user.email}');
      developer.log('🆔 UID: ${user.uid}');
      developer.log('✅ EmailVerified: ${user.emailVerified}');
      developer.log('🔑 IsAnonymous: ${user.isAnonymous}');
      developer.log('📱 PhoneNumber: ${user.phoneNumber ?? "なし"}');
      developer.log('👤 DisplayName: ${user.displayName ?? "なし"}');
      developer.log('🖼️ PhotoURL: ${user.photoURL ?? "なし"}');
      
      // メタデータ情報
      developer.log('🕰️ CreationTime: ${user.metadata.creationTime}');
      developer.log('🕰️ LastSignInTime: ${user.metadata.lastSignInTime}');
      
      // プロバイダー情報
      developer.log('🔗 ProviderData:');
      for (var provider in user.providerData) {
        developer.log('  - ProviderId: ${provider.providerId}');
        developer.log('  - UID: ${provider.uid}');
        developer.log('  - Email: ${provider.email}');
      }
      
      // 認証トークン情報
      try {
        developer.log('🔑 認証トークン取得中...');
        final idToken = await user.getIdToken(false); // キャッシュされたトークン
        final freshToken = await user.getIdToken(true); // 新しいトークン
        
        developer.log('🔑 キャッシュトークン: ${idToken?.substring(0, 50)}...');
        developer.log('🔑 新しいトークン: ${freshToken?.substring(0, 50)}...');
        developer.log('🔄 トークン同一性: ${idToken == freshToken}');
      } catch (e) {
        developer.log('❌ トークン取得エラー: $e');
      }
      
      // Firebase Authインスタンス情報
      developer.log('🔥 Firebase Authインスタンス: ${_auth.toString()}');
      developer.log('🔥 App: ${_auth.app.name}');
      developer.log('🔥 App Options: ${_auth.app.options.toString()}');
      
      // メール認証状態の詳細確認
      developer.log('🔍 === メール認証状態詳細 ===');
      developer.log('✅ EmailVerified (現在): ${user.emailVerified}');
      
      // ユーザー情報をリロードして再確認
      developer.log('🔄 ユーザー情報リロード中...');
      await user.reload();
      final reloadedUser = _auth.currentUser;
      
      if (reloadedUser != null) {
        developer.log('✅ EmailVerified (リロード後): ${reloadedUser.emailVerified}');
        developer.log('🔄 状態変化: ${user.emailVerified} → ${reloadedUser.emailVerified}');
      }
      
      // デバッグ情報更新
      _updateDebugInfo('🔍 Console確認完了: EmailVerified=${reloadedUser?.emailVerified}');
      
      // Firebase Consoleで確認すべき項目をログ出力
      developer.log('🔍 === Firebase Consoleで確認すべき項目 ===');
      developer.log('1. Authentication > Users でユーザーが存在するか');
      developer.log('2. ユーザーのEmail verifiedステータスがtrueになっているか');
      developer.log('3. Authentication > Templates でメールテンプレートが設定されているか');
      developer.log('4. Authentication > Settings でメール認証が有効になっているか');
      developer.log('5. メールアドレス: ${user.email}');
      developer.log('6. UID: ${user.uid}');
      
    } catch (e) {
      developer.log('❌ Firebase Console状態確認エラー: $e');
      _updateDebugInfo('❌ Console確認エラー: $e');
    }
  }

  /// MainScreenへの遷移
  void _navigateToMainScreen() {
    if (mounted) {
      // タイマーとリスナーを停止
      _periodicCheckTimer?.cancel();
      _intensiveCheckTimer?.cancel();
      _authStateSubscription?.cancel();
      
      // MainScreenに遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // #FFFFFF
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12), // 12px rounded corners effect
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // 16px safe-area padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success Icon - 80×80 px circle with light green background
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), // Very light green background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Color(0xFF388E3C), // Medium green check mark
                  ),
                ),
                
                const SizedBox(height: 24), // 24px vertical gap below icon
                
                // Title - 「登録が完了しました！」
                const Text(
                  '登録が完了しました！',
                  style: TextStyle(
                    fontSize: 24, // 24sp
                    fontWeight: FontWeight.w600, // Semi-bold
                    color: Color(0xFF000000), // #000
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12), // 12px gap between title and first line
                
                // Body Message - First line
                const Text(
                  '登録したメールアドレス宛に確認メールを送信しました。',
                  style: TextStyle(
                    fontSize: 16, // 16sp
                    fontWeight: FontWeight.normal, // Regular
                    color: Color(0xFF333333), // #333
                    height: 1.5, // line-height 24px (24/16 = 1.5)
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12), // 12px gap between the two lines
                
                // Body Message - Second line
                const Text(
                  'メール内のリンクをクリックして認証を完了してから、アプリをお楽しみください。',
                  style: TextStyle(
                    fontSize: 16, // 16sp
                    fontWeight: FontWeight.normal, // Regular
                    color: Color(0xFF333333), // #333
                    height: 1.5, // line-height 24px (24/16 = 1.5)
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40), // Extra spacing for better visual balance
                
                // Email confirmation display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // Light gray background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFCCCCCC), // #CCC border
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: Color(0xFF666666), // #666
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666), // #666
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40), // Extra spacing for better visual balance
                
                // デバッグ情報セクション
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔍 デバッグ情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        '状態: $_debugInfo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      Text(
                        '現在のユーザー: ${widget.email}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      Text(
                        'チェック回数: ${_periodicCheckCount}回',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      Text(
                        '集中モード: ${_isIntensiveMode ? "有効" : "無効"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      Text(
                        '最終チェック: ${_lastCheckTime?.toString().substring(11, 19) ?? "なし"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 手動チェックボタン
                ElevatedButton(
                  onPressed: () {
                    _performAuthStateCheck('手動チェック');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('手動で認証状態をチェック'),
                ),
                
                const SizedBox(height: 12),
                
                // 集中チェックボタン
                ElevatedButton(
                  onPressed: () {
                    _startIntensiveAuthCheck();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🔄 集中チェック開始'),
                ),
                
                const SizedBox(height: 12),
                
                // Firebase Console確認ボタン
                ElevatedButton(
                  onPressed: () {
                    _checkFirebaseConsoleStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🔍 Firebase Console状態確認'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
