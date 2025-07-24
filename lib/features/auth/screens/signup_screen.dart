import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'dart:async'; // StreamSubscription用
import '../widgets/auth_widgets.dart';
import '../../../core/services/firestore_service.dart';
import 'signup_complete_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;
  
  // デバッグ情報用
  String _debugInfo = '待機中';
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    
    // Firebase Auth認証状態監視を追加
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null && user.emailVerified) {
        developer.log('✅ SignUpScreenで認証完了を検知 - MainScreenへ遷移: ${user.email}');
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveUserToFirestore(User user, Map<String, dynamic> userData) async {
    try {
      debugPrint('📟 Firestoreにユーザーデータ保存開始...');
      final String uid = user.uid;
      final String name = userData['name'] as String;
      final String email = userData['email'] as String;
      final String? fcmToken = userData['fcmToken'] as String?;
      
      // メール認証送信は最初の認証状態確認時に実行済みなので、ここでは行わない
      // 直接Firestore保存を実行
      debugPrint('📟 FirestoreService().saveUser() 呼び出し...');
      final result = await FirestoreService().saveUser(
        uid: uid,
        name: name,
        email: email,
        fcmToken: fcmToken,
        role: '一般', // 明示的にroleを指定
      );
      debugPrint('📟 FirestoreService().saveUser() 呼び出し完了 - 結果: $result');
      
      if (result) {
        debugPrint('✅ Firestoreへのユーザー保存成功');
        
        // 画面遷移
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpCompleteScreen(
                email: email,
              ),
            ),
          );
        }
      } else {
        debugPrint('❌ Firestoreへのユーザー保存失敗');
      }
    } catch (e) {
      debugPrint('❌ Firestoreへの保存中にエラー発生: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('🚫 権限エラー: Firestoreセキュリティルールでアクセスが拒否されました');
      }
    } finally {
      // ローディング状態のリセットは不要、_signUpメソッドのfinalブロックで処理済み
    }
  }

  bool _isValidEmail(String email) {
    // Basic email validation with regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    debugPrint('🚀 _signUp()メソッド開始');
    
    // フォームバリデーションを正しく実行
    debugPrint('📝 フォームバリデーション開始');
    setState(() {
      _debugInfo = '📝 フォームバリデーション中...';
      _lastError = '';
    });
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ バリデーションエラー: フォーム入力が無効です');
      setState(() {
        _debugInfo = '❌ バリデーションエラー';
        _lastError = 'フォーム入力が無効です';
      });
      return;
    }
    debugPrint('✅ フォームバリデーション成功');

    debugPrint('🔄 setState開始: _isLoading = true');
    setState(() {
      _isLoading = true;
      _debugInfo = '🔄 アカウント作成中...';
    });
    debugPrint('✅ setState完了: _isLoading = true');

    debugPrint('🎯 tryブロック開始');
    try {
      // デバッグログ
      debugPrint('サインアップ処理を開始します: ${_emailController.text.trim()}');
      
      // 処理の各ステップを細かくログ出力
      debugPrint('FirebaseAuth.instance取得済み');
      
      // Create user with email and password
      debugPrint('createUserWithEmailAndPassword呼び出し前');
      setState(() {
        _debugInfo = '🔐 Firebase認証アカウント作成中...';
      });
      
      // 1. Firebase Auth でアカウント作成
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (userCredential.user == null) {
        debugPrint('❌ ユーザー作成失敗: userCredential.userがnullです');
        setState(() {
          _debugInfo = '❌ ユーザー作成失敗';
          _lastError = 'userCredential.userがnullです';
        });
        return;
      }
      
      final uid = userCredential.user!.uid;
      debugPrint('✅ ユーザー作成成功: $uid');
      setState(() {
        _debugInfo = '✅ アカウント作成成功 - FCMトークン取得中...';
      });
      
      // 2. userCredentialから直接ユーザー情報を取得
      final user = userCredential.user!;
      debugPrint('✅ 認証状態確認完了: UID=${user.uid}');
      
      // 3. FCMトークン取得
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('✅ FCMトークン取得成功: ${fcmToken != null ? fcmToken.substring(0, 20) + '...' : 'null'}');
        setState(() {
          _debugInfo = '✅ FCMトークン取得成功 - メール認証送信中...';
        });
      } catch (e) {
        debugPrint('❌ FCMトークン取得エラー: $e');
        setState(() {
          _debugInfo = '⚠️ FCMトークン取得エラー - メール認証送信中...';
        });
      }
      
      // 4. メール認証送信（Firestore保存より前に実行）
      try {
        debugPrint('📧 メール認証送信開始: ${user.email}');
        debugPrint('🔍 ユーザー作成直後にメール送信（セッション安定状態）');
        
        await user.sendEmailVerification();
        debugPrint('✅ メール認証送信成功: ${user.email}');
        setState(() {
          _debugInfo = '✅ メール認証送信成功 - Firestore保存中...';
        });
      } catch (e) {
        debugPrint('❌ メール認証送信エラー: $e');
        debugPrint('🔍 エラー詳細: ${e.runtimeType}');
        setState(() {
          _debugInfo = '⚠️ メール認証送信エラー - Firestore保存中...';
          _lastError = 'メール送信エラー: $e';
        });
        // メール送信失敗でも処理は継続
      }
      
      // 5. Firestoreへのユーザー情報保存（メール送信後に実行）
      debugPrint('💾 Firestoreへのユーザー保存開始');
      debugPrint('💾 保存対象UID: ${user.uid}');
      debugPrint('👤 保存対象名前: ${_nameController.text.trim()}');
      debugPrint('📧 保存対象メール: ${_emailController.text.trim()}');
      debugPrint('⏱️ SignUpScreen側タイムアウト設定: 10秒');
      
      final result = await FirestoreService().saveUser(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        fcmToken: fcmToken,
        role: '一般',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ SignUpScreen: Firestore保存がタイムアウトしました (10秒)');
          throw Exception('Firestoreへのユーザー保存に失敗しました: タイムアウト');
        },
      );
      
      if (!result) {
        debugPrint('❌ Firestoreへのユーザー保存失敗');
        setState(() {
          _debugInfo = '❌ Firestore保存失敗';
          _lastError = 'Firestoreへのユーザー保存に失敗しました';
        });
        throw Exception('Firestoreへのユーザー保存に失敗しました');
      }
      
      debugPrint('✅ Firestoreへのユーザー保存成功');
      setState(() {
        _debugInfo = '✅ Firestore保存成功 - 完了画面へ遷移中...';
      });
      
      // 6. 完了画面へ遷移
      if (!mounted) return;
      debugPrint('🎉 アカウント登録完了 - 完了画面へ遷移');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpCompleteScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _debugInfo = '❌ Firebase認証エラー';
        _lastError = '${e.code}: ${e.message}';
      });
    } catch (e) {
      debugPrint('❌ 未処理の例外: $e');
      setState(() {
        _debugInfo = '❌ 未処理エラー';
        _lastError = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // #FFFFFF
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _debugInfo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_lastError.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _lastError,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF5722),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0), // 16px safe-area padding
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60), // Generous spacing
                      
                      const OSAKELLogo(),
                      const SizedBox(height: 60),
                      const SectionTitle(title: 'アカウント登録'),
                      
                      const SizedBox(height: 16),
                      
                      CustomInputField(
                        controller: _nameController,
                        hintText: '名前',
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '名前を入力してください';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12), // 12 px vertical gap
                      
                      CustomInputField(
                        controller: _emailController,
                        hintText: 'メールアドレス',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          if (!_isValidEmail(value)) {
                            return '有効なメールアドレスを入力してください';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12), // 12 px vertical gap
                      
                      CustomInputField(
                        controller: _passwordController,
                        hintText: 'パスワード',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF666666),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          if (value.length < 8) {
                            return 'パスワードは8文字以上で入力してください';
                          }
                          if (!value.contains(RegExp(r'[A-Za-z]')) ||
                              !value.contains(RegExp(r'[0-9]'))) {
                            return 'パスワードは英字と数字を含める必要があります';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12), // 12 px vertical gap
                      
                      CustomInputField(
                        controller: _confirmPasswordController,
                        hintText: 'パスワード(確認)',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF666666),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを再入力してください';
                          }
                          if (value != _passwordController.text) {
                            return 'パスワードが一致しません';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32), // Generous spacing
                      
                      PrimaryButton(
                        text: 'アカウント登録',
                        onPressed: _signUp,
                      ),
                      
                      const SizedBox(height: 32), // 16 px vertical padding above and below
                      
                      const OrDivider(),
                      
                      const SizedBox(height: 32), // 16 px vertical padding above and below
                      
                      GoogleButton(
                        text: 'Continue with Google',
                        onPressed: () {
                          // TODO: Implement Google Sign-Up
                          developer.log('🚧 Google認証は今後実装予定');
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '既にアカウントをお持ちですか？ ',
                            style: TextStyle(
                              color: Color(0xFF666666), // #666
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'ログイン',
                              style: TextStyle(
                                color: Colors.black, // black
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32), // Bottom spacing
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
