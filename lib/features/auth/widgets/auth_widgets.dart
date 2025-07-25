import 'package:flutter/material.dart';

/// OSAKELブランドロゴウィジェット
class OSAKELLogo extends StatelessWidget {
  const OSAKELLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'OSAKEL',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24, // 24 sp
        fontWeight: FontWeight.w600, // semi-bold
        color: Colors.black, // #000
        letterSpacing: 1.2,
      ),
    );
  }
}

/// セクションタイトルウィジェット
class SectionTitle extends StatelessWidget {
  final String title;
  
  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, // 16 sp
          fontWeight: FontWeight.w600, // semi-bold
          color: Color(0xFF333333), // #333
        ),
      ),
    );
  }
}

/// カスタム入力フィールドウィジェット
class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56, // ≈ 56 px height
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // #F5F5F5 background
        borderRadius: BorderRadius.circular(12), // 12 px border radius
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16, // 16 sp
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16, // 16 sp regular
            color: Color(0xFF666666), // #666
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}

/// プライマリボタンウィジェット
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56, // ≈ 56 px height
      decoration: BoxDecoration(
        color: Colors.black, // #000 background
        borderRadius: BorderRadius.circular(12), // 12 px border radius
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2), // Y-offset 2 px
            blurRadius: 8, // blur 8 px
            color: Colors.black.withValues(alpha: 0.1), // rgba(0,0,0,10%)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white, // white text
                fontSize: 16, // 16 sp
                fontWeight: FontWeight.w500, // medium
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Googleボタンウィジェット
class GoogleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GoogleButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56, // ≈ 56 px height
      decoration: BoxDecoration(
        color: Colors.white, // white background
        border: Border.all(
          color: Colors.black, // 2 px black border
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12), // 12 px border radius
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2), // Y-offset 2 px
            blurRadius: 8, // blur 8 px
            color: Colors.black.withValues(alpha: 0.1), // rgba(0,0,0,10%)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" icon placeholder (24×24 px) - Black tone
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.black, // Changed to black for monochrome design
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black, // black text
                  fontSize: 16, // 16 sp
                  fontWeight: FontWeight.w500, // medium
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 区切り線ウィジェット
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFCCCCCC), // 1 px #CCC
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 14, // 14 sp regular
              color: Color(0xFF666666), // #666
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFCCCCCC), // 1 px #CCC
          ),
        ),
      ],
    );
  }
}
