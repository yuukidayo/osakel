import 'package:flutter/material.dart';

class CategoryModal extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final Function(String, String) onCategorySelected;

  const CategoryModal({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // ハンドルバー
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // モーダルタイトル
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'カテゴリを選択',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          // カテゴリリスト（スクロール可能）
          Expanded(
            child: ListView(
              children: [
                // 「すべてのカテゴリ」オプション
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('すべてのカテゴリ'),
                  selected: selectedCategory == 'すべてのカテゴリ',
                  onTap: () {
                    onCategorySelected('すべてのカテゴリ', 'すべてのカテゴリ');
                    Navigator.pop(context);
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  trailing: selectedCategory == 'すべてのカテゴリ'
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                ),
                
                const Divider(),
                
                // その他のカテゴリオプション
                ...categories.map((category) {
                  final String id = category['id'] ?? '';
                  final String name = category['name'] ?? 'Unknown';
                  final String? icon = category['icon'];
                  
                  return ListTile(
                    leading: Icon(_getIconData(icon)),
                    title: Text(name),
                    selected: selectedCategory == id,
                    onTap: () {
                      onCategorySelected(id, name);
                      Navigator.pop(context);
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    trailing: selectedCategory == id
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                        : null,
                  );
                }).toList(),
              ],
            ),
          ),
          
          // キャンセルボタン
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? icon) {
    switch (icon) {
      case 'local_drink':
        return Icons.local_drink;
      case 'local_bar':
        return Icons.local_bar;
      case 'wine_bar':
        return Icons.wine_bar;
      case 'liquor':
        return Icons.liquor;
      case 'coffee':
        return Icons.coffee;
      default:
        return Icons.category;
    }
  }
}
