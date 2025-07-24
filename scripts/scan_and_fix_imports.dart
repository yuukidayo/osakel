import 'dart:io';

void main() async {
  debugPrint('🔍 Import問題スキャン＆修正開始...');
  
  // 実際のファイル構造をスキャン
  final fileMap = <String, String>{};
  await _scanFiles(Directory('lib'), fileMap);
  
  debugPrint('📁 発見されたファイル: ${fileMap.length}個');
  
  int totalFiles = 0;
  int fixedFiles = 0;
  List<String> errors = [];
  
  // 全Dartファイルをチェック
  await for (final entity in Directory('lib').list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFiles++;
      
      final content = await entity.readAsString();
      final lines = content.split('\n');
      bool modified = false;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('import \'') && !line.contains('package:')) {
          final importMatch = RegExp(r"import\s+['\"]([^'\"\]+)['\"]").firstMatch(line);
          if (importMatch != null) {
            final importPath = importMatch.group(1)!;
            final resolvedPath = _resolveImportPath(entity.path, importPath);
            
            if (!File(resolvedPath).existsSync()) {
              // ファイルが存在しない場合、正しいパスを探す
              final fileName = importPath.split('/').last;
              if (fileMap.containsKey(fileName)) {
                final correctPath = _calculateRelativePath(entity.path, fileMap[fileName]!);
                lines[i] = line.replaceAll(importPath, correctPath);
                modified = true;
                debugPrint('🔧 修正: ${entity.path}');
                debugPrint('   ${importPath} → ${correctPath}');
              } else {
                errors.add('❌ ${entity.path}: ${importPath} (ファイル未発見)');
              }
            }
          }
        }
      }
      
      if (modified) {
        await entity.writeAsString(lines.join('\n'));
        fixedFiles++;
      }
    }
  }
  
  debugPrint('\n🎉 スキャン完了!');
  debugPrint('📊 総ファイル数: $totalFiles');
  debugPrint('📊 修正ファイル数: $fixedFiles');
  
  if (errors.isNotEmpty) {
    debugPrint('\n⚠️ 未解決エラー:');
    for (final error in errors) {
      debugPrint(error);
    }
  }
}

Future<void> _scanFiles(Directory dir, Map<String, String> fileMap) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final fileName = entity.path.split('/').last;
      fileMap[fileName] = entity.path;
    }
  }
}

String _resolveImportPath(String fromFile, String importPath) {
  final fromDir = File(fromFile).parent.path;
  final parts = importPath.split('/');
  String currentPath = fromDir;
  
  for (final part in parts) {
    if (part == '..') {
      currentPath = Directory(currentPath).parent.path;
    } else if (part != '.') {
      currentPath = '$currentPath/$part';
    }
  }
  
  return currentPath;
}

String _calculateRelativePath(String fromFile, String toFile) {
  final fromParts = File(fromFile).parent.path.split('/');
  final toParts = toFile.split('/');
  
  // 共通部分を見つける
  int commonLength = 0;
  for (int i = 0; i < fromParts.length && i < toParts.length; i++) {
    if (fromParts[i] == toParts[i]) {
      commonLength++;
    } else {
      break;
    }
  }
  
  // 相対パスを構築
  final upLevels = fromParts.length - commonLength;
  final downParts = toParts.sublist(commonLength);
  
  final relativeParts = List.filled(upLevels, '..') + downParts;
  return relativeParts.join('/');
}
