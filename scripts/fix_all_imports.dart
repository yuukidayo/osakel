import 'dart:io';

/// 全Import path修正スクリプト
/// 
/// 検出された全てのimportエラーを一括修正します
void main() async {
  print('🔧 全Import Path修正スクリプト開始...\n');
  
  int totalFixed = 0;
  
  // 1. modelsディレクトリ内の相対パス修正
  totalFixed += await fixModelsDirectory();
  
  // 2. screensディレクトリ内のパス修正
  totalFixed += await fixScreensDirectory();
  
  // 3. sharedディレクトリ内のパス修正
  totalFixed += await fixSharedDirectory();
  
  print('\n✅ 修正完了！');
  print('📊 総修正ファイル数: $totalFixed');
  print('🎉 全Import path修正が完了しました！');
}

/// modelsディレクトリ内の修正
Future<int> fixModelsDirectory() async {
  print('🔍 modelsディレクトリ を修正中...');
  int fixedCount = 0;
  
  // lib/models/filters/drink_filter_options.dart
  final filterOptionsFile = File('lib/models/filters/drink_filter_options.dart');
  if (filterOptionsFile.existsSync()) {
    final content = await filterOptionsFile.readAsString();
    final newContent = content.replaceAll(
      "import 'filter_option.dart';",
      "import './filter_option.dart';"
    );
    if (content != newContent) {
      await filterOptionsFile.writeAsString(newContent);
      print('   ✅ 修正: lib/models/filters/drink_filter_options.dart');
      fixedCount++;
    }
  }
  
  // lib/models/shop_with_price.dart
  final shopWithPriceFile = File('lib/models/shop_with_price.dart');
  if (shopWithPriceFile.existsSync()) {
    String content = await shopWithPriceFile.readAsString();
    content = content.replaceAll("import 'shop.dart';", "import './shop.dart';");
    content = content.replaceAll("import 'drink_shop_link.dart';", "import './drink_shop_link.dart';");
    await shopWithPriceFile.writeAsString(content);
    print('   ✅ 修正: lib/models/shop_with_price.dart');
    fixedCount++;
  }
  
  print('   📊 modelsディレクトリ: ${fixedCount}ファイル修正\n');
  return fixedCount;
}

/// screensディレクトリ内の修正
Future<int> fixScreensDirectory() async {
  print('🔍 screensディレクトリ を修正中...');
  int fixedCount = 0;
  
  final patterns = [
    // dart:developer は標準ライブラリなので削除
    ['import \'dart:developer\';', '// import \'dart:developer\'; // 不要なimport'],
    
    // 同じディレクトリ内のファイル参照
    ['import \'subcategory_screen.dart\';', 'import \'./subcategory_screen.dart\';'],
    ['import \'drinks/drink_search_screen.dart\';', 'import \'./drinks/drink_search_screen.dart\';'],
    ['import \'notification/notification_test_screen.dart\';', 'import \'./notification/notification_test_screen.dart\';'],
    
    // components参照
    ['import \'components/category_top_bar.dart\';', 'import \'./components/category_top_bar.dart\';'],
    ['import \'components/search_bar.dart\';', 'import \'./components/search_bar.dart\';'],
    ['import \'components/subcategory_bar.dart\';', 'import \'./components/subcategory_bar.dart\';'],
    ['import \'components/search_results_list.dart\';', 'import \'./components/search_results_list.dart\';'],
    ['import \'providers/drink_search_notifier.dart\';', 'import \'./providers/drink_search_notifier.dart\';'],
    ['import \'drink_item.dart\';', 'import \'./drink_item.dart\';'],
  ];
  
  final screensDir = Directory('lib/screens');
  if (screensDir.existsSync()) {
    await for (final entity in screensDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        String originalContent = content;
        
        for (final pattern in patterns) {
          content = content.replaceAll(pattern[0], pattern[1]);
        }
        
        if (content != originalContent) {
          await entity.writeAsString(content);
          print('   ✅ 修正: ${entity.path}');
          fixedCount++;
        }
      }
    }
  }
  
  print('   📊 screensディレクトリ: ${fixedCount}ファイル修正\n');
  return fixedCount;
}

/// sharedディレクトリ内の修正
Future<int> fixSharedDirectory() async {
  print('🔍 sharedディレクトリ を修正中...');
  int fixedCount = 0;
  
  final sharedDir = Directory('lib/shared');
  if (sharedDir.existsSync()) {
    await for (final entity in sharedDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        String originalContent = content;
        
        // 残りの修正パターン
        content = content.replaceAll(
          'import \'../../services/admin_service.dart\';',
          'import \'../../../services/admin_service.dart\';'
        );
        content = content.replaceAll(
          'import \'../../screens/category_list_screen.dart\';',
          'import \'../../../screens/category_list_screen.dart\';'
        );
        
        if (content != originalContent) {
          await entity.writeAsString(content);
          print('   ✅ 修正: ${entity.path}');
          fixedCount++;
        }
      }
    }
  }
  
  print('   📊 sharedディレクトリ: ${fixedCount}ファイル修正\n');
  return fixedCount;
}
