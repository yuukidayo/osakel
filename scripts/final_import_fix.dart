import 'dart:io';

void main() async {
  print('🔧 最終import修正スクリプト開始...');
  
  final projectRoot = Directory.current;
  final libDir = Directory('${projectRoot.path}/lib');
  
  if (!libDir.existsSync()) {
    print('❌ libディレクトリが見つかりません');
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
            print('  ✅ ${pattern['description']}: ${entity.path}');
          }
        }

        // ファイルが変更された場合のみ書き込み
        if (content != originalContent) {
          await entity.writeAsString(content);
          modifiedFiles++;
          totalReplacements += fileReplacements;
          print('📝 修正完了: ${entity.path} (${fileReplacements}箇所)');
        }
        
      } catch (e) {
        print('❌ エラー: ${entity.path} - $e');
      }
    }
  }

  print('\n📊 修正結果:');
  print('  - 検査ファイル数: $totalFiles');
  print('  - 修正ファイル数: $modifiedFiles');
  print('  - 総修正箇所数: $totalReplacements');
  print('🎉 最終import修正完了!');
}
