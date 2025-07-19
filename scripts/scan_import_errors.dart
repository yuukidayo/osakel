import 'dart:io';

/// Import エラー検出スクリプト
/// 
/// ビルドする前に、存在しないファイルを参照しているimport文を検出します
void main() async {
  print('🔍 Import エラー検出スクリプト開始...\n');
  
  final errors = <String>[];
  final libDirectory = Directory('lib');
  
  if (!libDirectory.existsSync()) {
    print('❌ libディレクトリが見つかりません');
    return;
  }
  
  await for (final entity in libDirectory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await scanFileForImportErrors(entity, errors);
    }
  }
  
  if (errors.isEmpty) {
    print('✅ Import エラーは見つかりませんでした！');
  } else {
    print('❌ ${errors.length}個のImport エラーが見つかりました:\n');
    for (final error in errors) {
      print(error);
    }
    
    print('\n📋 修正が必要なパターン:');
    analyzeErrorPatterns(errors);
  }
}

/// ファイル内のimport エラーをスキャン
Future<void> scanFileForImportErrors(File file, List<String> errors) async {
  try {
    final content = await file.readAsString();
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith("import '") && !line.contains('package:')) {
        final importMatch = RegExp(r"import\s+'([^']+)'").firstMatch(line);
        if (importMatch != null) {
          final importPath = importMatch.group(1)!;
          
          // 相対パスを絶対パスに変換
          final currentDir = file.parent.path;
          final targetPath = resolveImportPath(currentDir, importPath);
          
          if (!File(targetPath).existsSync()) {
            errors.add('❌ ${file.path}:${i + 1}\n   Import: $importPath\n   Target: $targetPath\n');
          }
        }
      }
    }
  } catch (e) {
    print('⚠️  ファイル読み込みエラー: ${file.path} - $e');
  }
}

/// 相対パスを絶対パスに解決
String resolveImportPath(String currentDir, String importPath) {
  final parts = importPath.split('/');
  final currentParts = currentDir.split('/');
  
  // libディレクトリのインデックスを見つける
  final libIndex = currentParts.lastIndexOf('lib');
  if (libIndex == -1) return '';
  
  final baseParts = currentParts.sublist(0, libIndex + 1);
  
  for (final part in parts) {
    if (part == '..') {
      if (baseParts.isNotEmpty) {
        baseParts.removeLast();
      }
    } else if (part != '.') {
      baseParts.add(part);
    }
  }
  
  return baseParts.join('/');
}

/// エラーパターンを分析
void analyzeErrorPatterns(List<String> errors) {
  final patterns = <String, int>{};
  
  for (final error in errors) {
    if (error.contains('models/')) {
      if (error.contains('features/')) {
        patterns['featuresディレクトリのmodelsパス'] = (patterns['featuresディレクトリのmodelsパス'] ?? 0) + 1;
      } else if (error.contains('shared/')) {
        patterns['sharedディレクトリのmodelsパス'] = (patterns['sharedディレクトリのmodelsパス'] ?? 0) + 1;
      }
    } else if (error.contains('widgets/')) {
      patterns['widgetsパス'] = (patterns['widgetsパス'] ?? 0) + 1;
    } else if (error.contains('services/')) {
      patterns['servicesパス'] = (patterns['servicesパス'] ?? 0) + 1;
    } else if (error.contains('providers/')) {
      patterns['providersパス'] = (patterns['providersパス'] ?? 0) + 1;
    }
  }
  
  patterns.forEach((pattern, count) {
    print('  • $pattern: ${count}件');
  });
  
  if (patterns.isNotEmpty) {
    print('\n💡 fix_import_paths.dartスクリプトで一括修正できる可能性があります！');
  }
}
