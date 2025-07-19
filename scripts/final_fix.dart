import 'dart:io';

void main() async {
  print('🔧 最終一括修正開始...');
  
  final fixes = [
    // admin_guard
    {
      'file': 'lib/screens/admin/add_drink_screen.dart',
      'from': "import '../widgets/admin_guard.dart';",
      'to': "import '../shared/widgets/admin_guard.dart';",
    },
    
    // drink search screens
    {
      'file': 'lib/screens/drinks/drink_search_screen.dart',
      'from': "import '../widgets/filters/drink_filter_bottom_sheet.dart';",
      'to': "import '../../shared/widgets/filters/drink_filter_bottom_sheet.dart';",
    },
    {
      'file': 'lib/screens/drinks/drink_search_screen.dart',
      'from': "import '../widgets/modals/category_selection_modal.dart';",
      'to': "import '../../shared/widgets/modals/category_selection_modal.dart';",
    },
    {
      'file': 'lib/screens/drinks/drink_search_screen_backup.dart',
      'from': "import '../widgets/filters/drink_filter_bottom_sheet.dart';",
      'to': "import '../../shared/widgets/filters/drink_filter_bottom_sheet.dart';",
    },
    
    // core utils
    {
      'file': 'lib/core/utils/marker_utils.dart',
      'from': "import '../widgets/price_marker.dart';",
      'to': "import '../../shared/widgets/price_marker.dart';",
    },
  ];
  
  int fixedCount = 0;
  
  for (final fix in fixes) {
    final file = File(fix['file']!);
    if (file.existsSync()) {
      String content = await file.readAsString();
      if (content.contains(fix['from']!)) {
        content = content.replaceAll(fix['from']!, fix['to']!);
        await file.writeAsString(content);
        print('✅ 修正: ${fix['file']}');
        fixedCount++;
      }
    }
  }
  
  print('\n🎉 最終修正完了: ${fixedCount}ファイル');
}
