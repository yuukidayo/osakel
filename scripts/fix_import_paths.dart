import 'dart:io';

/// Import path修正スクリプト
/// 
/// 発見されたパターンに基づいて、間違ったimport pathを一括修正します
void main() async {
  debugPrint('🔧 Import Path修正スクリプト開始...\n');
  
  int totalFixed = 0;
  
  // パターン1: featuresディレクトリ - modelsパスを4階層上に修正
  totalFixed += await fixImportPattern(
    'lib/features',
    '../../../models/',
    '../../../../models/',
    'featuresディレクトリのmodelsパス'
  );
  
  // パターン2: sharedディレクトリ - modelsパスを3階層上に修正
  totalFixed += await fixImportPattern(
    'lib/shared',
    '../../models/',
    '../../../models/',
    'sharedディレクトリのmodelsパス'
  );
  
  // パターン3: featuresディレクトリ - providersパスを3階層上に修正
  totalFixed += await fixImportPattern(
    'lib/features',
    '../../providers/',
    '../../../providers/',
    'featuresディレクトリのprovidersパス'
  );
  
  // パターン4: featuresディレクトリ - core/servicesパス修正
  totalFixed += await fixImportPattern(
    'lib/features',
    '../services/firestore_service.dart',
    '../../../core/services/firestore_service.dart',
    'featuresディレクトリのfirestore_serviceパス'
  );
  
  // パターン5: sharedディレクトリ - screensパス修正
  totalFixed += await fixImportPattern(
    'lib/shared',
    '../../screens/',
    '../../../screens/',
    'sharedディレクトリのscreensパス'
  );
  
  // パターン6: sharedディレクトリ - coreパス修正
  totalFixed += await fixImportPattern(
    'lib/shared',
    '../../core/',
    '../../../core/',
    'sharedディレクトリのcoreパス'
  );
  
  // パターン7: screensディレクトリ - modelsパス修正
  totalFixed += await fixImportPattern(
    'lib/screens',
    '../../models/',
    '../models/',
    'screensディレクトリのmodelsパス'
  );
  
  // パターン8: screensディレクトリ - coreパス修正
  totalFixed += await fixImportPattern(
    'lib/screens',
    '../core/',
    '../../core/',
    'screensディレクトリのcoreパス'
  );
  
  // パターン9: screensディレクトリ - sharedパス修正
  totalFixed += await fixImportPattern(
    'lib/screens',
    '../shared/',
    '../../shared/',
    'screensディレクトリのsharedパス'
  );
  
  // パターン10: screensディレクトリ - featuresパス修正
  totalFixed += await fixImportPattern(
    'lib/screens',
    '../features/',
    '../../features/',
    'screensディレクトリのfeaturesパス'
  );
  
  // パターン11: screensディレクトリ - providersパス修正
  totalFixed += await fixImportPattern(
    'lib/screens',
    '../providers/',
    '../../providers/',
    'screensディレクトリのprovidersパス'
  );
  
  debugPrint('\n✅ 修正完了！');
  debugPrint('📊 総修正ファイル数: $totalFixed');
  debugPrint('🎉 Import path修正が完了しました！');
}

/// 指定されたパターンでimport文を修正
Future<int> fixImportPattern(
  String searchDir, 
  String fromPattern, 
  String toPattern, 
  String description
) async {
  debugPrint('🔍 $description を修正中...');
  
  int fixedCount = 0;
  final directory = Directory(searchDir);
  
  if (!directory.existsSync()) {
    debugPrint('   ⚠️  ディレクトリが見つかりません: $searchDir');
    return 0;
  }
  
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        final newContent = content.replaceAll(
          "import '$fromPattern",
          "import '$toPattern"
        );
        
        if (content != newContent) {
          await entity.writeAsString(newContent);
          debugPrint('   ✅ 修正: ${entity.path}');
          fixedCount++;
        }
      } catch (e) {
        debugPrint('   ❌ エラー: ${entity.path} - $e');
      }
    }
  }
  
  debugPrint('   📊 $description: ${fixedCount}ファイル修正\n');
  return fixedCount;
}
