import 'dart:io';

void main() async {
  print('🔧 包括的import修正スクリプト開始...');
  
  final projectRoot = Directory.current;
  final libDir = Directory('${projectRoot.path}/lib');
  
  if (!libDir.existsSync()) {
    print('❌ libディレクトリが見つかりません');
    return;
  }

  // 修正パターンを定義
  final fixPatterns = [
    // drink_category.dartの修正
    {
      'from': "import '../../../models/drink_category.dart';",
      'to': "import '../models/drink_category.dart';",
      'description': 'drink_category.dartパス修正 (providers/services)'
    },
    {
      'from': "import '../drinks/models/drink_category.dart';",
      'to': "import '../../../screens/drinks/models/drink_category.dart';",
      'description': 'drink_category.dartパス修正 (features)'
    },
    {
      'from': "import '../../drinks/models/drink_category.dart';",
      'to': "import '../../../../screens/drinks/models/drink_category.dart';",
      'description': 'drink_category.dartパス修正 (features/services)'
    },
    
    // その他の一般的な修正パターン
    {
      'from': "import '../widgets/",
      'to': "import '../shared/widgets/",
      'description': 'widgets → shared/widgets'
    },
    {
      'from': "import '../../widgets/",
      'to': "import '../../shared/widgets/",
      'description': 'widgets → shared/widgets (2階層)'
    },
    {
      'from': "import '../shared/widgets/",
      'to': "import '../widgets/",
      'description': 'shared/widgets → widgets (逆修正)'
    },
    
    // modelsパス修正
    {
      'from': "import '../models/",
      'to': "import '../../models/",
      'description': 'models 1階層上に修正'
    },
    {
      'from': "import '../../models/",
      'to': "import '../../../models/",
      'description': 'models 2階層上に修正'
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
  print('🎉 包括的import修正完了!');
}
