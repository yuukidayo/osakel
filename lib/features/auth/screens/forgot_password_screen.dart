import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // Basic email validation with regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> _resetPassword() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Send password reset email
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      // Show success message
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('パスワードリセットメールを送信しました'),
          content: const Text('メールに記載されているリンクからパスワードをリセットしてください。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to login screen
              },
              child: const Text('ログイン画面に戻る'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'このメールアドレスに登録されているアカウントが見つかりません。';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません。';
          break;
        default:
          errorMessage = 'パスワードリセットに失敗しました: ${e.message}';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('パスワードリセットに失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                      
                      // Brand Header - Centered OSAKEL logo text
                      const Text(
                        'OSAKEL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24, // 24 sp
                          fontWeight: FontWeight.w600, // semi-bold
                          color: Colors.black, // #000
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 60), // Generous 16px+ gaps
                      
                      // Reset Password Section
                      
                      const SizedBox(height: 16),
                      
                      // Description text
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '登録したメールアドレスを入力してください。\nパスワードリセット用のリンクをお送りします。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14, // 14 sp
                            color: Color(0xFF666666), // #666
                            height: 1.5, // Line height
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Email Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'メールアドレス',
                          style: TextStyle(
                            fontSize: 16, // 16 sp
                            fontWeight: FontWeight.w600, // semi-bold
                            color: Color(0xFF333333), // #333
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email field
                      Container(
                        height: 56, // ≈ 56 px height
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5), // #F5F5F5 background
                          borderRadius: BorderRadius.circular(12), // 12 px border radius
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 16, // 16 sp
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'メールアドレス', // Placeholder text
                            hintStyle: TextStyle(
                              fontSize: 16, // 16 sp regular
                              color: Color(0xFF666666), // #666
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
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
                      ),
                      
                      const SizedBox(height: 32), // Generous spacing
                      
                      // Primary Action Button - "Send Reset Email" button
                      Container(
                        height: 56, // ≈ 56 px height
                        decoration: BoxDecoration(
                          color: Colors.black, // #000 background
                          borderRadius: BorderRadius.circular(12), // 12 px border radius
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 2), // Y-offset 2 px
                              blurRadius: 8, // blur 8 px
                              color: Colors.black.withOpacity(0.1), // rgba(0,0,0,10%)
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _resetPassword,
                            child: const Center(
                              child: Text(
                                '送信',
                                style: TextStyle(
                                  color: Colors.white, // white text
                                  fontSize: 16, // 16 sp
                                  fontWeight: FontWeight.w500, // medium
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Back to login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              '戻る',
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
