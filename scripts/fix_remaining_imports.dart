import 'dart:io';

/// 残りのImport path修正スクリプト
/// 
/// 特殊なパターンや相対パスの問題を修正します
void main() async {
  debugPrint('🔧 残りのImport Path修正スクリプト開始...\n');
  
  int totalFixed = 0;
  
  // modelsディレクトリ内の相対パス修正
  totalFixed += await fixModelsInternalPaths();
  
  // screensディレクトリ内の相対パス修正  
  totalFixed += await fixScreensInternalPaths();
  
  // sharedディレクトリ内の残りのパス修正
  totalFixed += await fixSharedRemainingPaths();
  
  debugPrint('\n✅ 修正完了！');
  debugPrint('📊 総修正ファイル数: $totalFixed');
  debugPrint('🎉 残りのImport path修正が完了しました！');
}

/// modelsディレクトリ内の相対パス修正
Future<int> fixModelsInternalPaths() async {
  debugPrint('🔍 modelsディレクトリ内の相対パス を修正中...');
  
  int fixedCount = 0;
  final modelsDir = Directory('lib/models');
  
  if (!modelsDir.existsSync()) {
    debugPrint('   ⚠️  modelsディレクトリが見つかりません');
    return 0;
  }
  
  await for (final entity in modelsDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        String newContent = content;
        
        // 同じディレクトリ内のファイル参照はそのまま保持
        
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
  
  debugPrint('   📊 modelsディレクトリ内: ${fixedCount}ファイル修正\n');
  return fixedCount;
}

/// screensディレクトリ内の相対パス修正
Future<int> fixScreensInternalPaths() async {
  debugPrint('🔍 screensディレクトリ内の相対パス を修正中...');
  
  int fixedCount = 0;
  final screensDir = Directory('lib/screens');
  
  if (!screensDir.existsSync()) {
    debugPrint('   ⚠️  screensディレクトリが見つかりません');
    return 0;
  }
  
  await for (final entity in screensDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        String newContent = content;
        
        // ./components/ パスを components/ に修正
        newContent = newContent.replaceAll(
          "import './components/",
          "import 'components/"
        );
        
        // ./providers/ パスを providers/ に修正
        newContent = newContent.replaceAll(
          "import './providers/",
          "import 'providers/"
        );
        
        // 同じディレクトリ内のファイル参照はそのまま保持
        
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
  
  debugPrint('   📊 screensディレクトリ内: ${fixedCount}ファイル修正\n');
  return fixedCount;
}

/// sharedディレクトリ内の残りのパス修正
Future<int> fixSharedRemainingPaths() async {
  debugPrint('🔍 sharedディレクトリ内の残りのパス を修正中...');
  
  int fixedCount = 0;
  final sharedDir = Directory('lib/shared');
  
  if (!sharedDir.existsSync()) {
    debugPrint('   ⚠️  sharedディレクトリが見つかりません');
    return 0;
  }
  
  await for (final entity in sharedDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        String newContent = content;
        
        // ../services/ を ../../services/ に修正
        newContent = newContent.replaceAll(
          "import '../services/",
          "import '../../services/"
        );
        
        // ../screens/ を ../../screens/ に修正
        newContent = newContent.replaceAll(
          "import '../screens/",
          "import '../../screens/"
        );
        
        // ../../features/ を ../../../features/ に修正
        newContent = newContent.replaceAll(
          "import '../../features/",
          "import '../../../features/"
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
  
  debugPrint('   📊 sharedディレクトリ内の残り: ${fixedCount}ファイル修正\n');
  return fixedCount;
}
