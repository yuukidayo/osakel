import 'dart:io';

void main() async {
  debugPrint('🔧 Import自動修正開始...');
  
  final rules = {
    '../models/': '../../models/',
    '../../models/': '../../../models/',
    '../../widgets/': '../../shared/widgets/',
    '../widgets/': '../shared/widgets/',
    '../store/shop_search_screen.dart': '../features/stores/screens/shop_search_screen.dart',
    '../../store/shop_search_screen.dart': '../../features/stores/screens/shop_search_screen.dart',
    '../shared/widgets/': '../widgets/',
    '../../shared/widgets/': '../widgets/',
    '../shared/widgets/filters/': '../../shared/widgets/filters/',
    '../shared/widgets/modals/': '../../shared/widgets/modals/',
  };
  
  int totalFiles = 0;
  int modifiedFiles = 0;
  
  final dirs = ['lib/features', 'lib/core', 'lib/shared', 'lib/screens'];
  
  for (final dirPath in dirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    
    debugPrint('📁 処理中: $dirPath');
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        totalFiles++;
        
        String content = await entity.readAsString();
        String original = content;
        
        for (final entry in rules.entries) {
          content = content.replaceAll(
            "import '${entry.key}",
            "import '${entry.value}"
          );
          content = content.replaceAll(
            'import "${entry.key}',
            'import "${entry.value}'
          );
        }
        
        if (content != original) {
          await entity.writeAsString(content);
          modifiedFiles++;
          debugPrint('✅ 修正: ${entity.path}');
        }
      }
    }
  }
  
  debugPrint('\n🎉 修正完了!');
  debugPrint('📊 総ファイル数: $totalFiles');
  debugPrint('📊 修正ファイル数: $modifiedFiles');
}
