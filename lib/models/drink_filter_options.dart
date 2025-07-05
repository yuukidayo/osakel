import 'package:flutter/material.dart';

/// 詳細検索で使用するフィルターオプションの種類
enum FilterOptionType {
  country,      // 国
  region,       // 地域
  alcohol,      // アルコール度数
  series,       // シリーズ
  type,         // タイプ
  grape,        // ぶどう品種（ワイン用）
  vintage,      // 製造年（ワイン用）
  aging,        // 熟成期間
  taste,        // 味わい
  price,        // 価格帯
  brewery,      // 醸造所・蒸溜所
}

/// 単一のフィルターオプション設定
class FilterOption {
  final FilterOptionType type;
  final String label;
  final Widget Function(BuildContext, Map<String, dynamic>, Function(String, dynamic)) buildWidget;
  
  FilterOption({
    required this.type,
    required this.label,
    required this.buildWidget,
  });
}

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
          types: ['ラガー', 'ピルスナー', 'エール', 'IPA', 'ペールエール', 'スタウト', '白ビール', 'クラフト', 'フルーツ', 'ヘイズ', 'サワー', 'その他'],
        ),
      ),
      // 共通オプションを追加
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
          types: ['赤ワイン', '白ワイン', 'ロゼ', 'スパークリング', 'デザートワイン'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.grape,
        label: 'ぶどう品種',
        buildWidget: (context, values, onChange) => _buildGrapeChips(
          context, 
          values, 
          onChange,
        ),
      ),
      FilterOption(
        type: FilterOptionType.vintage,
        label: 'ヴィンテージ',
        buildWidget: (context, values, onChange) => _buildVintageDropdown(
          context, 
          values, 
          onChange,
        ),
      ),
      // 共通オプションを追加
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
          types: ['シングルモルト', 'ブレンデッド', 'バーボン', 'ライ', 'ジャパニーズ'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.aging,
        label: '熟成年数',
        buildWidget: (context, values, onChange) => _buildAgingDropdown(
          context, 
          values, 
          onChange,
        ),
      ),
      // 共通オプションを追加
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }

  // 日本酒用のフィルターオプション
  static List<FilterOption> sakeOptions(BuildContext context, Map<String, dynamic> filterValues, Function(String, dynamic) onFilterChanged) {
    return [
      // 日本酒固有のオプション
      FilterOption(
        type: FilterOptionType.type,
        label: '特定名称',
        buildWidget: (context, values, onChange) => _buildTypeChips(
          context, 
          values, 
          onChange,
          types: ['本醸造', '特別本醸造', '純米', '特別純米', '吟醸', '大吟醸', '純米吟醸'],
        ),
      ),
      FilterOption(
        type: FilterOptionType.taste,
        label: '味わい',
        buildWidget: (context, values, onChange) => _buildTasteChips(
          context, 
          values, 
          onChange,
          tastes: ['辛口', '中口', '甘口', 'フルーティー', '濃醇', '淡麗'],
        ),
      ),
      // 共通オプションを追加
      ...commonOptions(context, filterValues, onFilterChanged),
    ];
  }
  
  // カテゴリ名から適切なフィルターオプションを取得
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
      case 'すべてのカテゴリ':
      default:
        // すべての共通オプションを返す
        return commonOptions(context, filterValues, onFilterChanged);
    }
  }
  
  // 各フィルターオプションのUIコンポーネント実装

  // 国フィルター用のUIコンポーネント
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
  
  // 地域フィルター用のUIコンポーネント
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
  
  // タイプフィルター用のUIコンポーネント
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
  
  // 味わいフィルター用のUIコンポーネント
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
  
  // ぶどう品種フィルター用のUIコンポーネント
  static Widget _buildGrapeChips(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final grapeTypes = [
      'カベルネ・ソーヴィニヨン', 'メルロー', 'ピノ・ノワール', 
      'シャルドネ', 'ソーヴィニヨン・ブラン', 'リースリング',
      'マスカット', '甲州', '山ぶどう', 'その他'
    ];
    final selectedGrapes = values['grape'] as List<String>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: grapeTypes.map((grape) => FilterChip(
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
  
  // ヴィンテージドロップダウン
  static Widget _buildVintageDropdown(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final currentYear = DateTime.now().year;
    final vintages = List<int>.generate(30, (index) => currentYear - index);
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
      hint: const Text('すべて'),
      items: [
        const DropdownMenuItem<int>(
          value: 0,
          child: Text('すべて'),
        ),
        ...vintages.map((year) => 
          DropdownMenuItem<int>(
            value: year,
            child: Text(year.toString() + '年'),
          )
        ).toList(),
      ],
      onChanged: (value) {
        onChange('vintage', value ?? 0);
      },
    );
  }
  
  // 熟成年数ドロップダウン
  static Widget _buildAgingDropdown(
    BuildContext context, 
    Map<String, dynamic> values, 
    Function(String, dynamic) onChange,
  ) {
    final agingOptions = [
      'すべて', 'ノンエイジ', '3年以上', '5年以上', '10年以上', '12年以上', '15年以上', '18年以上', '21年以上', '25年以上'
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
}
