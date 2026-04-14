// lib/core/widgets/priority_badge.dart
// 优先级标记组件

import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PriorityBadge extends StatelessWidget {
  final int priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  String get _label {
    switch (priority) {
      case 3: return '高';
      case 2: return '中';
      case 1: return '低';
      default: return '';
    }
  }

  IconData get _icon {
    switch (priority) {
      case 3: return CupertinoIcons.flag_fill;
      case 2: return CupertinoIcons.flag_fill;
      case 1: return CupertinoIcons.flag;
      default: return CupertinoIcons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (priority == 0) return const SizedBox.shrink();

    final color = AppColors.priorityColor(priority);

    if (compact) {
      return Icon(_icon, size: 14, color: color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTextStyles.caption2.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
