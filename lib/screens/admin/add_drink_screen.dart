import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/permission_guard.dart';
import '../models/admin_drink.dart';
import '../models/shop.dart';

/// 管理者用お酒登録画面
class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameJapaneseController = TextEditingController();
  final _nameEnglishController = TextEditingController();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _alcoholPercentageController = TextEditingController();
  final _seriesController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _proCommentController = TextEditingController();

  String _selectedCategory = '';
  List<Shop> _availableShops = [];
  Map<String, bool> _selectedShops = {};
  Map<String, TextEditingController> _priceControllers = {};
  bool _isLoading = false;

  // カテゴリ選択肢
  final List<String> _categories = [
    'ビール',
    '日本酒',
    'ワイン',
    'ウイスキー',
    '焼酎',
    'カクテル',
    'ノンアルコール',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _nameJapaneseController.dispose();
    _nameEnglishController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _alcoholPercentageController.dispose();
    _seriesController.dispose();
    _manufacturerController.dispose();
    _proCommentController.dispose();
    
    // 価格コントローラーも破棄
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  /// 店舗一覧を読み込み
  Future<void> _loadShops() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .orderBy('name')
          .get();

      final shops = querySnapshot.docs
          .map((doc) => Shop.fromMap(doc.id, doc.data()))
          .toList();

      setState(() {
        _availableShops = shops;
        // 各店舗の選択状態と価格コントローラーを初期化
        for (final shop in shops) {
          _selectedShops[shop.id] = false;
          _priceControllers[shop.id] = TextEditingController();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('店舗データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  /// お酒データを保存
  Future<void> _saveDrink() async {
    if (!_formKey.currentState!.validate()) return;

    // 選択された店舗のリストと価格マップを作成
    final selectedShopIds = _selectedShops.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final shopPrices = <String, int>{};
    for (final shopId in selectedShopIds) {
      final priceText = _priceControllers[shopId]?.text ?? '';
      final price = int.tryParse(priceText);
      if (price != null && price > 0) {
        shopPrices[shopId] = price;
      }
    }

    // AdminDrinkオブジェクトを作成
    final drink = AdminDrink(
      nameJapanese: _nameJapaneseController.text.trim(),
      nameEnglish: _nameEnglishController.text.trim(),
      country: _countryController.text.trim(),
      region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
      category: _selectedCategory,
      alcoholPercentage: double.tryParse(_alcoholPercentageController.text) ?? 0.0,
      series: _seriesController.text.trim().isEmpty ? null : _seriesController.text.trim(),
      manufacturer: _manufacturerController.text.trim().isEmpty ? null : _manufacturerController.text.trim(),
      proComment: _proCommentController.text.trim().isEmpty ? null : _proCommentController.text.trim(),
      shopIds: selectedShopIds,
      shopPrices: shopPrices,
      createdAt: DateTime.now(),
    );

    // バリデーション
    final validationError = drink.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firestoreに保存
      await FirebaseFirestore.instance
          .collection('admin_drinks')
          .add(drink.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('お酒を登録しました'),
            backgroundColor: Colors.green,
          ),
        );

        // 画面を閉じる
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard.adminOnly(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('お酒登録'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _saveDrink,
                child: const Text(
                  '登録',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本情報セクション
                _buildSectionTitle('基本情報'),
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _nameJapaneseController,
                  label: '日本語名称',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '日本語名称は必須です';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _nameEnglishController,
                  label: '英語名称',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '英語名称は必須です';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildDropdownField(),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _countryController,
                  label: '生産国',
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '生産国は必須です';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _regionController,
                  label: '地域',
                  isRequired: false,
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _alcoholPercentageController,
                  label: 'アルコール度数 (%)',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'アルコール度数は必須です';
                    }
                    final percentage = double.tryParse(value);
                    if (percentage == null || percentage < 0 || percentage > 100) {
                      return '0〜100の数値を入力してください';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // 詳細情報セクション
                _buildSectionTitle('詳細情報（任意）'),
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _seriesController,
                  label: 'シリーズ',
                  isRequired: false,
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _manufacturerController,
                  label: '製造元',
                  isRequired: false,
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _proCommentController,
                  label: 'プロコメント',
                  isRequired: false,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 32),
                
                // 店舗・価格設定セクション
                _buildSectionTitle('店舗・価格設定'),
                const SizedBox(height: 16),
                
                _buildShopSelection(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory.isEmpty ? null : _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'カテゴリ *',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFFFAFAFA),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'カテゴリを選択してください';
        }
        return null;
      },
    );
  }

  Widget _buildShopSelection() {
    if (_availableShops.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '販売店舗を選択し、各店舗の価格を入力してください',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        ..._availableShops.map((shop) {
          final isSelected = _selectedShops[shop.id] ?? false;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            _selectedShops[shop.id] = value ?? false;
                            if (!isSelected) {
                              // 選択解除時は価格をクリア
                              _priceControllers[shop.id]?.clear();
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (shop.address.isNotEmpty)
                              Text(
                                shop.address,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceControllers[shop.id],
                      decoration: const InputDecoration(
                        labelText: '価格（円）',
                        border: OutlineInputBorder(),
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: isSelected ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '価格を入力してください';
                        }
                        final price = int.tryParse(value);
                        if (price == null || price <= 0) {
                          return '有効な価格を入力してください';
                        }
                        return null;
                      } : null,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
