import 'package:flutter/material.dart';

/// 店舗検索用の水平フィルターバー
/// 左側にフィルター数表示、右側にピル型フィルターボタン群を提供
class FilterBar extends StatelessWidget {
  final String? selectedFilter;
  final Function(String) onFilterSelected;
  final int activeFilterCount;
  final String? facilityName;
  final List<String> activeFilters;

  const FilterBar({
    Key? key,
    this.selectedFilter,
    required this.onFilterSelected,
    this.activeFilterCount = 0,
    this.facilityName,
    this.activeFilters = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本フィルターボタンを等幅で横並び
          Row(
            children: [
              Expanded(
                child: _PillFilterButton(
                  label: 'エリア',
                  leadingIcon: Icons.location_on_outlined,
                  isActive: selectedFilter == 'area',
                  onPressed: () => onFilterSelected('area'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillFilterButton(
                  label: 'カテゴリ',
                  leadingIcon: Icons.category_outlined,
                  isActive: selectedFilter == 'category',
                  onPressed: () => onFilterSelected('category'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillFilterButton(
                  label: '特徴',
                  leadingIcon: Icons.tune_outlined,
                  isActive: selectedFilter == 'feature',
                  onPressed: () => onFilterSelected('feature'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



/// ピル型フィルターボタン（白背景、黒文字）
class _PillFilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;
  final IconData? leadingIcon;

  const _PillFilterButton({
    Key? key,
    required this.label,
    required this.isActive,
    required this.onPressed,
    this.leadingIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // パディングを縮小して改行を防止
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFFAFBFC), // アクティブ時黒、非アクティブ時オフホワイト
          borderRadius: BorderRadius.circular(8), // 控えめな角丸
          border: Border.all(
            color: isActive ? Colors.black : const Color(0xFF495057), // ダークグレーボーダー
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // 極薄い影
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 左側アイコン
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon!,
                size: 16,
                color: isActive ? Colors.white : const Color(0xFF6C757D),
              ),
              const SizedBox(width: 6),
            ],
            // ラベルテキスト
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF212529), // チャコール
                  fontSize: 12, // サイズを元に戻して可読性向上
                  fontWeight: FontWeight.w500, // Medium weight
                  letterSpacing: 0.3, // レタースペーシングで高級感
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 従来のフィルターボタンの個別コンポーネント（改善版）
class _FilterButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // カラーとグラデーションの定義
    Color textColor;
    Color borderColor;
    List<Color> gradientColors;
    List<BoxShadow> shadows;

    if (widget.isSelected) {
      // 選択状態: エレガントな黒グラデーション
      textColor = const Color(0xFFFFFFFF);
      borderColor = const Color(0xFF333333);
      gradientColors = [
        const Color(0xFF444444),
        const Color(0xFF222222),
      ];
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
    } else if (_isPressed) {
      // 押下状態: 微細なグラデーション
      textColor = const Color(0xFF333333);
      borderColor = const Color(0xFF333333);
      gradientColors = [
        const Color(0xFFF5F5F5),
        const Color(0xFFEAEAEA),
      ];
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];
    } else {
      // デフォルト状態: 清潔な白グラデーション
      textColor = const Color(0xFF333333);
      borderColor = const Color(0xFF333333);
      gradientColors = [
        const Color(0xFFFFFFFF),
        const Color(0xFFFAFAFA),
      ];
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          offset: const Offset(0, 3),
          blurRadius: 10,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _animationController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _animationController.reverse();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _animationController.reverse();
            },
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
                boxShadow: shadows.map((shadow) => BoxShadow(
                  color: shadow.color.withOpacity(
                    shadow.color.opacity * _shadowAnimation.value,
                  ),
                  offset: shadow.offset,
                  blurRadius: shadow.blurRadius,
                  spreadRadius: shadow.spreadRadius,
                )).toList(),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                  child: Text(widget.label),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
