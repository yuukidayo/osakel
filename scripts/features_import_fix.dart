import 'dart:io';

void main() async {
  debugPrint('🔧 featuresディレクトリimport修正スクリプト開始...');
  
  final projectRoot = Directory.current;
  final featuresDir = Directory('${projectRoot.path}/lib/features');
  
  if (!featuresDir.existsSync()) {
    debugPrint('❌ featuresディレクトリが見つかりません');
    return;
  }

  // featuresディレクトリ専用の修正パターン
  final fixPatterns = [
    // features内の2階層上のmodelsを3階層上に修正
    {
      'from': "import '../../models/",
      'to': "import '../../../models/",
      'description': 'features内 models 2→3階層修正'
    },
  ];

  int totalFiles = 0;
  int modifiedFiles = 0;
  int totalReplacements = 0;

  await for (final entity in featuresDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFiles++;
      
      try {
        String content = await entity.readAsString();
        String originalContent = content;
        int fileReplacements = 0;

        // 各パターンを適用
        for (final pattern in fixPatterns) {
          final from = pattern['from'] as String;
          final to = pattern['to'] as String;
          
          if (content.contains(from)) {
            content = content.replaceAll(from, to);
            fileReplacements++;
            debugPrint('  ✅ ${pattern['description']}: ${entity.path}');
          }
        }

        // ファイルが変更された場合のみ書き込み
        if (content != originalContent) {
          await entity.writeAsString(content);
          modifiedFiles++;
          totalReplacements += fileReplacements;
          debugPrint('📝 修正完了: ${entity.path} (${fileReplacements}箇所)');
        }
        
      } catch (e) {
        debugPrint('❌ エラー: ${entity.path} - $e');
      }
    }
  }

  debugPrint('\n📊 修正結果:');
  debugPrint('  - 検査ファイル数: $totalFiles');
  debugPrint('  - 修正ファイル数: $modifiedFiles');
  debugPrint('  - 総修正箇所数: $totalReplacements');
  debugPrint('🎉 featuresディレクトリimport修正完了!');
}
