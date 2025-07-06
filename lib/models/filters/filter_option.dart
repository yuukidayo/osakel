import 'package:flutter/material.dart';

/// 詳細検索で使用するフィルターオプションの種類
enum FilterOptionType {
  country,      // 国
  region,       // 地域
  alcohol,      // アルコール度数
  series,       // シリーズ
  type,         // タイプ
  grape,        // ぶどう品種（ワイン用）
  vintage,      // 製造年（ワイン・ウイスキー用）
  aging,        // 熟成期間
  taste,        // 味わい
  price,        // 価格帯
  brewery,      // 醸造所・蒸溜所
  material,     // 原料（ウイスキー用）
  oldBottle,    // オールドボトル（ウイスキー用）
}

/// 単一のフィルターオプション設定
class FilterOption {
  final FilterOptionType type;
  final String label;
  final Widget Function(BuildContext, Map<String, dynamic>, Function(String, dynamic)) buildWidget;
  
  const FilterOption({
    required this.type,
    required this.label,
    required this.buildWidget,
  });
}
