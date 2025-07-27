import 'package:flutter/material.dart';

class DrinkSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String searchKeyword;
  final bool isEnabled;

  const DrinkSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.searchKeyword,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'ドリンク名で検索',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: const Color(0xFFFAFAFA), // 薄いグレー背景
        ),
        onChanged: onChanged,
        enabled: isEnabled,
      ),
    );
  }
}
