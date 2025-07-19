import 'package:flutter/material.dart';

/// お酒画像表示セクション
class DrinkImageSection extends StatelessWidget {
  final String imageUrl;
  final double height;

  const DrinkImageSection({
    super.key,
    required this.imageUrl,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.network(
        imageUrl,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
