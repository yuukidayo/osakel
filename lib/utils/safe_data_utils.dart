/// 安全なデータ取得のためのユーティリティ関数集
class SafeDataUtils {
  /// Mapから安全に文字列を取得する
  /// nullまたは空文字の場合はデフォルト値を返す
  static String safeGetString(Map<String, dynamic>? data, String key, {String defaultValue = ''}) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    return value.toString().trim();
  }

  /// Mapから安全に文字列を取得する（未設定表示用）
  /// nullまたは空文字の場合は「未設定」を返す
  static String safeGetStringWithPlaceholder(Map<String, dynamic>? data, String key, {String placeholder = '未設定'}) {
    if (data == null) return placeholder;
    final value = data[key];
    if (value == null) return placeholder;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? placeholder : stringValue;
  }

  /// Mapから安全に数値を取得する
  /// nullまたは無効な値の場合はデフォルト値を返す
  static double safeGetDouble(Map<String, dynamic>? data, String key, {double defaultValue = 0.0}) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    if (value is num) return value.toDouble();
    
    return defaultValue;
  }

  /// Mapから安全に整数を取得する
  /// nullまたは無効な値の場合はデフォルト値を返す
  static int safeGetInt(Map<String, dynamic>? data, String key, {int defaultValue = 0}) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is num) return value.toInt();
    
    return defaultValue;
  }

  /// Mapから安全にbool値を取得する
  /// nullまたは無効な値の場合はデフォルト値を返す
  static bool safeGetBool(Map<String, dynamic>? data, String key, {bool defaultValue = false}) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return lowerValue == 'true' || lowerValue == '1';
    }
    if (value is int) return value != 0;
    
    return defaultValue;
  }

  /// ネストしたMapから安全に値を取得する
  /// 例: safeGetNested(data, ['user', 'profile', 'name'])
  static dynamic safeGetNested(Map<String, dynamic>? data, List<String> keys) {
    if (data == null || keys.isEmpty) return null;
    
    dynamic current = data;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
      if (current == null) return null;
    }
    
    return current;
  }

  /// ネストしたMapから安全に文字列を取得する
  static String safeGetNestedString(Map<String, dynamic>? data, List<String> keys, {String defaultValue = ''}) {
    final value = safeGetNested(data, keys);
    if (value == null) return defaultValue;
    return value.toString().trim();
  }
}
