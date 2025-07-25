import 'package:flutter/material.dart';

/// Widget for displaying a single price marker in Airbnb style
class PriceMarkerWidget extends StatelessWidget {
  final String price;
  final bool isSelected;
  
  const PriceMarkerWidget({
    super.key,
    required this.price,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected ? Border.all(color: Colors.blue.shade800, width: 2) : null,
      ),
      child: Text(
        price,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
