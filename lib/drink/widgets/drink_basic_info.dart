import 'package:flutter/material.dart';
import '../../../../models/drink.dart';

/// お酒基本情報表示コンポーネント
class DrinkBasicInfo extends StatelessWidget {
  final Drink drink;

  const DrinkBasicInfo({
    super.key,
    required this.drink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            drink.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            drink.type,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
