// lib/core/widgets/tag_chip.dart
// 标签芯片组件

import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool compact;

  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final chipColor = color ?? AppColors.primary(brightness);
    final fontSize = compact ? 11.0 : 13.0;
    final hPad = compact ? 8.0 : 12.0;
    final vPad = compact ? 2.0 : 4.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.2)
              : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: Border.all(
            color: selected
                ? chipColor.withValues(alpha: 0.6)
                : chipColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: chipColor,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  CupertinoIcons.xmark,
                  size: compact ? 10 : 12,
                  color: chipColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
