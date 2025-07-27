import 'package:flutter/material.dart';
import '../store/models/shop_with_price.dart';

class ClusteredPriceMarkerWidget extends StatelessWidget {
  final List<ShopWithPrice> shops;
  final bool isSelected;

  const ClusteredPriceMarkerWidget({
    super.key,
    required this.shops,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort shops by price
    final sortedShops = List<ShopWithPrice>.from(shops)
      ..sort((a, b) => a.drinkShopLink.price.compareTo(b.drinkShopLink.price));
    
    // Get lowest price
    final lowestPrice = sortedShops.first.drinkShopLink.price;
    
    // Get number of shops
    final count = shops.length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue.shade800 : Colors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¥${lowestPrice.toInt()}~',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            '$count店',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
