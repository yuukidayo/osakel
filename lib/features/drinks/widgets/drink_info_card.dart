import 'package:flutter/material.dart';
import '../../../../models/drink.dart';
import '../../../core/utils/safe_data_utils.dart';

/// お酒の詳細情報カード
class DrinkInfoCard extends StatelessWidget {
  final Drink drink;
  final String? countryName;
  final Map<String, dynamic>? drinkData;

  const DrinkInfoCard({
    super.key,
    required this.drink,
    this.countryName,
    this.drinkData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                const Text(
                  'お酒の情報',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 情報リスト
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _buildDrinkInfoItems(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrinkInfoItems() {
    if (drinkData == null) return [];
    
    final List<Widget> infoItems = [];
    
    // Firestoreのデータを取得
    final String name = SafeDataUtils.safeGetString(drinkData, 'name');
    final String nameEn = SafeDataUtils.safeGetString(drinkData, 'name_en');
    final String brand = SafeDataUtils.safeGetString(drinkData, 'brand');
    final String area = SafeDataUtils.safeGetString(drinkData, 'area');
    final double abv = SafeDataUtils.safeGetDouble(drinkData, 'abv');
    final String country = countryName ?? '不明';
    
    // アイコン付き情報項目を追加
    infoItems.add(_buildInfoItem('名称', name, icon: Icons.local_bar));
    infoItems.add(_buildInfoItem('名称（英語）', nameEn, icon: Icons.translate));
    infoItems.add(_buildInfoItem('生産国', country, icon: Icons.public));
    infoItems.add(_buildInfoItem('生産エリア', area, icon: Icons.location_on));
    infoItems.add(_buildInfoItem('お酒カテゴリ', drink.type, icon: Icons.category));
    infoItems.add(_buildInfoItem('アルコール度数', '${abv}%', icon: Icons.percent));
    infoItems.add(_buildInfoItem('シリーズ', brand, icon: Icons.business));
    
    return infoItems;
  }

  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    if (value.isEmpty || value == '不明' || value == '0.0%') {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 100 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
