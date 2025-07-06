import 'package:flutter/material.dart';
import 'filter_option.dart';

/// カテゴリごとのフィルターオプション定義
class DrinkFilterOptions {
  // すべてのカテゴリ共通の基本オプション
  static List<FilterOption> commonOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      FilterOption(
        type: FilterOptionType.country,
        label: '生産国',
        buildWidget: (context, values, onChange) => _buildCountryChips(
          context, 
          values, 
          onChange,
          countries: ['日本', 'アメリカ', 'フランス', 'イタリア', 'イギリス', 'スコットランド', 'アイルランド', 'カナダ', 'メキシコ', 'スペイン', 'ドイツ', 'ベルギー', 'オーストラリア', 'ニュージーランド', 'チリ', 'その他'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.region,
        label: '生産エリア',
        buildWidget: (context, values, onChange) => _buildRegionChips(
          context, 
          values, 
          onChange,
          regions: ['北海道', '東北', '関東', '中部', '関西', '中国', '四国', '九州', '沖縄', 'その他国内', '海外'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.alcohol,
        label: 'アルコール度数',
        buildWidget: (context, values, onChange) => _buildAlcoholRangeSlider(
          context, 
          values, 
          onChange,
          min: 0.0,
          max: 60.0,
        ),
      ),
      FilterOption(
        type: FilterOptionType.series,
        label: 'シリーズ',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['レギュラー', 'プレミアム', 'スペシャル', 'リミテッド', 'シーズナル', 'その他'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.brewery,
        label: 'メーカー',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['サントリー', 'キリン', 'アサヒ', 'サッポロ', 'ニッカ', '白州', '山崎', '響', '知多', '余市', 'その他国内', '海外メーカー'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.price,
        label: '価格帯',
        buildWidget: (context, values, onChange) => _buildPriceRangeSlider(context, values, onChange),
      ),
    ];
  }
  
  // ビール用のフィルターオプション
  static List<FilterOption> beerOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      // ビール固有のオプション
      FilterOption(
        type: FilterOptionType.type,
        label: 'ビールタイプ',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['ラガー', 'ピルスナー', 'IPA', 'ペールエール', 'スタウト', 'ポーター', 'ヴァイツェン', 'ベルジャン', 'その他'],
        ),
      ),
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }
  
  // ワイン用のフィルターオプション
  static List<FilterOption> wineOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      // ワイン固有のオプション
      FilterOption(
        type: FilterOptionType.type,
        label: 'ワインタイプ',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['赤', '白', 'ロゼ', 'スパークリング', '甘口', '辛口', 'ミディアム', 'フルボディ', 'ナチュラルワイン', 'オレンジワイン', 'その他'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.grape,
        label: 'ぶどう品種',
        buildWidget: (context, values, onChange) => _buildGrapeChips(context, values, onChange),
      ),
      FilterOption(
        type: FilterOptionType.vintage,
        label: 'ヴィンテージ',
        buildWidget: (context, values, onChange) => _buildVintageDropdown(context, values, onChange),
      ),
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }
  
  // ウイスキー用のフィルターオプション
  static List<FilterOption> whiskyOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      // ウイスキー固有のオプション
      FilterOption(
        type: FilterOptionType.type,
        label: 'ウイスキータイプ',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['シングルモルト', 'ブレンデッド', 'グレーン', 'バーボン', 'ライ', 'その他'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.aging,
        label: '熟成年数',
        buildWidget: (context, values, onChange) => _buildAgingDropdown(context, values, onChange),
      ),
      FilterOption(
        type: FilterOptionType.material,
        label: '主原料',
        buildWidget: (context, values, onChange) => _buildMaterialChips(context, values, onChange),
      ),
      FilterOption(
        type: FilterOptionType.taste,
        label: '風味プロファイル',
        buildWidget: (context, values, onChange) => _buildTasteChips(
          context, 
          values, 
          onChange,
          tastes: ['フルーティ', 'スモーキー', 'スパイシー', 'フローラル', '甘い', '軽い', '重い', '複雑', 'ピート', 'シェリー', 'ドライ', 'その他'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.oldBottle,
        label: 'オールドボトル',
        buildWidget: (context, values, onChange) => _buildOldBottleSwitch(context, values, onChange),
      ),
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }
  
  // 日本酒用のフィルターオプション
  static List<FilterOption> sakeOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      // 日本酒固有のオプション
      FilterOption(
        type: FilterOptionType.type,
        label: '日本酒タイプ',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['純米', '大吟醸', '吟醸', '本醸造', '生酒', '熟成酒', '原酒', 'にごり酒', '冷酒', '熱燗', 'その他'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.taste,
        label: '味わい',
        buildWidget: (context, values, onChange) => _buildTasteChips(
          context, 
          values, 
          onChange,
          tastes: ['辛口', '甘口', 'さっぱり', '濃醇', '熟成', '爽やか', 'フルーティ', 'その他'],
        ),
      ),
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }
  
  // リキュール用のフィルターオプション
  static List<FilterOption> liqueurOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      // リキュール固有のオプション
      FilterOption(
        type: FilterOptionType.type,
        label: 'リキュールタイプ',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['フルーツ', 'ハーブ', 'スパイス', 'クリーム', 'コーヒー', 'チョコレート', '蜂蜜', 'その他'],
        ),
      ),
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }
  
  // カテゴリに対応するフィルターオプションを取得
  static List<FilterOption> getOptionsForCategory(
    String category, 
    BuildContext context,
    Map<String, dynamic> filterValues,
    Function(String, dynamic) onFilterChanged
  ) {
    switch (category.toLowerCase()) {
      case 'ビール':
        return beerOptions(context, filterValues, onFilterChanged);
      case 'ワイン':
        return wineOptions(context, filterValues, onFilterChanged);
      case 'ウイスキー':
        return whiskyOptions(context, filterValues, onFilterChanged);
      case '日本酒':
        return sakeOptions(context, filterValues, onFilterChanged);
      case 'リキュール':
        return liqueurOptions(context, filterValues, onFilterChanged);
      default:
        return commonOptions(context, filterValues, onFilterChanged);
    }
  }
  
  // 国選択UI
  static Widget _buildCountryChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange, {
    required List<String> countries,
  }) {
    final selectedCountries = values['country'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: countries.map((country) => FilterChip(
        label: Text(country),
        selected: selectedCountries.contains(country),
        onSelected: (selected) {
          final newList = List<String>.from(selectedCountries);
          if (selected) {
            newList.add(country);
          } else {
            newList.remove(country);
          }
          onChange('country', newList);
        },
      )).toList(),
    );
  }
  
  // 地域選択UI
  static Widget _buildRegionChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange, {
    required List<String> regions,
  }) {
    final selectedRegions = values['region'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: regions.map((region) => FilterChip(
        label: Text(region),
        selected: selectedRegions.contains(region),
        onSelected: (selected) {
          final newList = List<String>.from(selectedRegions);
          if (selected) {
            newList.add(region);
          } else {
            newList.remove(region);
          }
          onChange('region', newList);
        },
      )).toList(),
    );
  }
  
  // タイプ選択UI
  static Widget _buildTypeChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange, {
    required List<String> types,
  }) {
    final selectedTypes = values['type'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) => FilterChip(
        label: Text(type),
        selected: selectedTypes.contains(type),
        onSelected: (selected) {
          final newList = List<String>.from(selectedTypes);
          if (selected) {
            newList.add(type);
          } else {
            newList.remove(type);
          }
          onChange('type', newList);
        },
      )).toList(),
    );
  }
  
  // 味わい選択UI
  static Widget _buildTasteChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange, {
    required List<String> tastes,
  }) {
    final selectedTastes = values['taste'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tastes.map((taste) => FilterChip(
        label: Text(taste),
        selected: selectedTastes.contains(taste),
        onSelected: (selected) {
          final newList = List<String>.from(selectedTastes);
          if (selected) {
            newList.add(taste);
          } else {
            newList.remove(taste);
          }
          onChange('taste', newList);
        },
      )).toList(),
    );
  }
  
  // ぶどう品種選択UI
  static Widget _buildGrapeChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final grapes = [
      'カベルネ・ソーヴィニヨン', 'メルロー', 'ピノ・ノワール', 'シャルドネ', 
      'ソーヴィニヨン・ブラン', 'リースリング', 'マスカット', 'シラー', 
      'マルベック', 'テンプラニーリョ', '甲州', 'マスカット・ベリーA', 'その他'
    ];
    final selectedGrapes = values['grape'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: grapes.map((grape) => FilterChip(
        label: Text(grape),
        selected: selectedGrapes.contains(grape),
        onSelected: (selected) {
          final newList = List<String>.from(selectedGrapes);
          if (selected) {
            newList.add(grape);
          } else {
            newList.remove(grape);
          }
          onChange('grape', newList);
        },
      )).toList(),
    );
  }
  
  // ヴィンテージ選択UI
  static Widget _buildVintageDropdown(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final currentYear = DateTime.now().year;
    final years = List.generate(50, (index) => currentYear - index);
    final selectedVintage = values['vintage'] as int? ?? 0;
    
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: selectedVintage > 0 ? selectedVintage : null,
      hint: const Text('年代を選択'),
      items: [
        const DropdownMenuItem<int>(
          value: 0,
          child: Text('指定なし'),
        ),
        ...years.map((year) => 
          DropdownMenuItem<int>(
            value: year,
            child: Text('$year年'),
          )
        ),
      ],
      onChanged: (value) {
        onChange('vintage', value ?? 0);
      },
    );
  }
  
  // 熟成年数選択UI
  static Widget _buildAgingDropdown(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final agingOptions = [
      'すべて', 'ノンエイジ', '3年以上', '5年以上', '10年以上', '12年以上', 
      '15年以上', '18年以上', '21年以上', '25年以上', '30年以上'
    ];
    final selectedAging = values['aging'] as String? ?? 'すべて';
    
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: selectedAging,
      items: agingOptions.map((age) => 
        DropdownMenuItem<String>(
          value: age,
          child: Text(age),
        )
      ).toList(),
      onChanged: (value) {
        onChange('aging', value ?? 'すべて');
      },
    );
  }
  
  // アルコール度数スライダー
  static Widget _buildAlcoholRangeSlider(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange, {
    required double min,
    required double max,
  }) {
    final alcoholRange = values['alcoholRange'] as RangeValues? ?? RangeValues(min, max);
    
    return Column(
      children: [
        RangeSlider(
          values: alcoholRange,
          min: min,
          max: max,
          divisions: ((max - min) / 2).round(),
          labels: RangeLabels(
            '${alcoholRange.start.toStringAsFixed(1)}%', 
            '${alcoholRange.end.toStringAsFixed(1)}%'
          ),
          onChanged: (values) {
            onChange('alcoholRange', values);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toStringAsFixed(1)}%'),
              Text('${max.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }
  
  // 価格帯スライダー
  static Widget _buildPriceRangeSlider(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final priceRange = values['priceRange'] as RangeValues? ?? const RangeValues(0, 10000);
    
    return Column(
      children: [
        RangeSlider(
          values: priceRange,
          min: 0,
          max: 10000,
          divisions: 20,
          labels: RangeLabels(
            '¥${priceRange.start.round()}', 
            '¥${priceRange.end.round()}'
          ),
          onChanged: (values) {
            onChange('priceRange', values);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('¥0'),
              Text('¥10,000+'),
            ],
          ),
        ),
      ],
    );
  }

  // ウイスキーの原料選択用UIビルダー
  static Widget _buildMaterialChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final materials = ['モルト', 'グレーン', 'ライ麦', 'トウモロコシ', '大麦', '小麦', '希少種穀', 'その他'];
    final selectedMaterials = values['material'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((material) => FilterChip(
        label: Text(material),
        selected: selectedMaterials.contains(material),
        onSelected: (selected) {
          final newList = List<String>.from(selectedMaterials);
          if (selected) {
            newList.add(material);
          } else {
            newList.remove(material);
          }
          onChange('material', newList);
        },
      )).toList(),
    );
  }

  // ウイスキーのオールドボトル選択用UIビルダー
  static Widget _buildOldBottleSwitch(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final isOldBottle = values['oldBottle'] as bool? ?? false;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('オールドボトルのみ'),
        Switch(
          value: isOldBottle,
          onChanged: (value) {
            onChange('oldBottle', value);
          },
        ),
      ],
    );
  }
}
