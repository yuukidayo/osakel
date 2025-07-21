import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../widgets/auth_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // Basic email validation with regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    // 簡略化したバリデーション
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('メールアドレスとパスワードを入力してください', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // デバッグログ
      developer.log('サインアップ処理を開始します: ${_emailController.text.trim()}');
      
      // 処理の各ステップを細かくログ出力
      developer.log('FirebaseAuth.instance取得済み');
      
      // Create user with email and password - シンプルに実行
      developer.log('createUserWithEmailAndPassword呼び出し前');
      
      try {
        // エラーが発生する部分を特定するため、個別のtryブロックで囲む
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        developer.log('ユーザー作成成功: ${userCredential.user?.uid}');
        
        // メール認証送信もtryで囲む
        try {
          await userCredential.user?.sendEmailVerification();
          developer.log('認証メール送信成功');
        } catch (verifyError) {
          developer.log('認証メール送信エラー: $verifyError');
        }
        
        // 成功メッセージとナビゲーション
        if (!mounted) return;
        _showSnackBar('アカウント登録成功', Colors.green);
        Navigator.pop(context);
      } catch (authError) {
        developer.log('createUserWithEmailAndPassword呼び出しエラー: $authError');
        throw authError; // 外側のcatchで処理するためrethrow
      }
      
    } on FirebaseAuthException catch (e) {
      developer.log('FirebaseAuthException: ${e.code} - ${e.message}');
      _showSnackBar('認証エラー: ${e.code}', Colors.red);
    } catch (e) {
      developer.log('未処理の例外: $e');
      _showSnackBar('エラーが発生しました: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
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
                        hintText: 'パスワード(確認',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google認証は今後実装予定です'),
                              backgroundColor: Color(0xFF666666),
                            ),
                          );
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
