// lib/features/home/widgets/task_item_card.dart
// 单个任务卡片

import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/animated_check_box.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/task_model.dart';
import 'package:intl/intl.dart';

class TaskItemCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback? onDismissed;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);

    return AnimatedOpacity(
      opacity: task.isCompleted ? 0.6 : 1.0,
      duration: AppConstants.animNormal,
      child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingXs,
      ),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedCheckBox(
                isChecked: task.isCompleted,
                onChanged: onStatusChanged,
                activeColor: AppColors.priorityColor(task.priority),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  AnimatedDefaultTextStyle(
                    duration: AppConstants.animNormal,
                    style: AppTextStyles.body.copyWith(
                      color: task.isCompleted
                          ? AppColors.textSecondary(brightness)
                          : AppColors.textPrimary(brightness),
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.textSecondary(brightness),
                    ),
                    child: Text(task.title),
                  ),

                  // 描述
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // 底部信息栏
                  if (task.dueDate != null || task.priority > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (task.dueDate != null) ...[
                          Icon(
                            CupertinoIcons.calendar,
                            size: 13,
                            color: _dueDateColor(brightness),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('M/d').format(task.dueDate!),
                            style: AppTextStyles.caption2.copyWith(
                              color: _dueDateColor(brightness),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (task.priority > 0)
                          PriorityBadge(priority: task.priority, compact: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Color _dueDateColor(Brightness brightness) {
    if (task.dueDate == null) return AppColors.textSecondary(brightness);
    final now = DateTime.now();
    final due = task.dueDate!;
    if (due.isBefore(now)) return AppColors.error;
    if (due.difference(now).inDays <= 1) return AppColors.warning;
    return AppColors.textSecondary(brightness);
  }
}
