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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUserToFirestore(User user, Map<String, dynamic> userData) async {
    try {
      print('📟 Firestoreにユーザーデータ保存開始...');
      final String uid = user.uid;
      final String name = userData['name'] as String;
      final String email = userData['email'] as String;
      final String? fcmToken = userData['fcmToken'] as String?;
      
      // メール認証送信は最初の認証状態確認時に実行済みなので、ここでは行わない
      // 直接Firestore保存を実行
      print('📟 FirestoreService().saveUser() 呼び出し...');
      final result = await FirestoreService().saveUser(
        uid: uid,
        name: name,
        email: email,
        fcmToken: fcmToken,
        role: '一般', // 明示的にroleを指定
      );
      print('📟 FirestoreService().saveUser() 呼び出し完了 - 結果: $result');
      
      if (result) {
        print('✅ Firestoreへのユーザー保存成功');
        
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
        print('❌ Firestoreへのユーザー保存失敗');
      }
    } catch (e) {
      print('❌ Firestoreへの保存中にエラー発生: $e');
      if (e.toString().contains('permission-denied')) {
        print('🚫 権限エラー: Firestoreセキュリティルールでアクセスが拒否されました');
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
    print('🚀 _signUp()メソッド開始');
    
    // フォームバリデーションを正しく実行
    print('📝 フォームバリデーション開始');
    if (!_formKey.currentState!.validate()) {
      print('❌ バリデーションエラー: フォーム入力が無効です');
      return;
    }
    print('✅ フォームバリデーション成功');

    print('🔄 setState開始: _isLoading = true');
    setState(() {
      _isLoading = true;
    });
    print('✅ setState完了: _isLoading = true');

    print('🎯 tryブロック開始');
    try {
      // デバッグログ
      print('サインアップ処理を開始します: ${_emailController.text.trim()}');
      
      // 処理の各ステップを細かくログ出力
      print('FirebaseAuth.instance取得済み');
      
      // Create user with email and password
      print('createUserWithEmailAndPassword呼び出し前');
      
      // 1. Firebase Auth でアカウント作成
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (userCredential.user == null) {
        print('❌ ユーザー作成失敗: userCredential.userがnullです');
        return;
      }
      
      final uid = userCredential.user!.uid;
      print('✅ ユーザー作成成功: $uid');
      
      // 2. userCredentialから直接ユーザー情報を取得
      final user = userCredential.user!;
      print('✅ 認証状態確認完了: UID=${user.uid}');
      
      // 3. FCMトークン取得
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print('✅ FCMトークン取得成功: ${fcmToken != null ? fcmToken.substring(0, 20) + '...' : 'null'}');
      } catch (e) {
        print('❌ FCMトークン取得エラー: $e');
      }
      
      // 4. メール認証送信（Firestore保存より前に実行）
      try {
        print('📧 メール認証送信開始: ${user.email}');
        print('🔍 ユーザー作成直後にメール送信（セッション安定状態）');
        
        await user.sendEmailVerification();
        print('✅ メール認証送信成功: ${user.email}');
      } catch (e) {
        print('❌ メール認証送信エラー: $e');
        print('🔍 エラー詳細: ${e.runtimeType}');
        // メール送信失敗でも処理は継続
      }
      
      // 5. Firestoreへのユーザー情報保存（メール送信後に実行）
      print('💾 Firestoreへのユーザー保存開始');
      print('💾 保存対象UID: ${user.uid}');
      print('👤 保存対象名前: ${_nameController.text.trim()}');
      print('📧 保存対象メール: ${_emailController.text.trim()}');
      
      final result = await FirestoreService().saveUser(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        fcmToken: fcmToken,
        role: '一般',
      );
      
      if (!result) {
        print('❌ Firestoreへのユーザー保存失敗');
        throw Exception('Firestoreへのユーザー保存に失敗しました');
      }
      
      print('✅ Firestoreへのユーザー保存成功');
      
      // 6. 完了画面へ遷移
      if (!mounted) return;
      print('🎉 アカウント登録完了 - 完了画面へ遷移');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpCompleteScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      print('❌ 未処理の例外: $e');
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
