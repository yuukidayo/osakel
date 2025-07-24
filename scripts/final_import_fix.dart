import 'dart:io';

void main() async {
  debugPrint('🔧 最終import修正スクリプト開始...');
  
  final projectRoot = Directory.current;
  final libDir = Directory('${projectRoot.path}/lib');
  
  if (!libDir.existsSync()) {
    debugPrint('❌ libディレクトリが見つかりません');
    return;
  }

  // 修正パターンを定義（正確なパス修正）
  final fixPatterns = [
    // 3階層上のmodelsを2階層上に修正
    {
      'from': "import '../../../models/",
      'to': "import '../../models/",
      'description': 'models 3→2階層修正'
    },
    // 4階層上のmodelsを2階層上に修正  
    {
      'from': "import '../../../../models/",
      'to': "import '../../models/",
      'description': 'models 4→2階層修正'
    },
    // 5階層上のmodelsを2階層上に修正
    {
      'from': "import '../../../../../models/",
      'to': "import '../../models/",
      'description': 'models 5→2階層修正'
    },
  ];

  int totalFiles = 0;
  int modifiedFiles = 0;
  int totalReplacements = 0;

  await for (final entity in libDir.list(recursive: true)) {
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
  debugPrint('🎉 最終import修正完了!');
}
