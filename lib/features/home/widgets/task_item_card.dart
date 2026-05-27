// lib/features/home/widgets/task_item_card.dart
// 单个任务卡片

import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/animated_check_box.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/task_model.dart';
import 'package:intl/intl.dart';

class TaskItemCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback? onDismissed;
  final VoidCallback? onSwipeComplete;
  final List<String> tagNames;
  final List<TaskModel> subtasks;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    this.onDismissed,
    this.onSwipeComplete,
    this.tagNames = const [],
    this.subtasks = const [],
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
      child: Dismissible(
        key: ValueKey(task.id),
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.4,
          DismissDirection.endToStart: 0.4,
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // 右滑完成
            onSwipeComplete?.call();
            return false;
          }
          // 左滑删除
          return true;
        },
        onDismissed: (_) => onDismissed?.call(),
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: AppColors.success,
            size: 28,
          ),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(
            CupertinoIcons.delete,
            color: AppColors.error,
            size: 24,
          ),
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
                  if (task.dueDate != null || task.priority > 0 || task.recurrenceRule != null) ...[
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
                        if (task.recurrenceRule != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.repeat,
                            size: 13,
                            color: AppColors.textSecondary(brightness),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // 标签
                  if (tagNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tagNames
                          .map((name) => TagChip(label: name, compact: true))
                          .toList(),
                    ),
                  ],

                  // 子任务进度
                  if (subtasks.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.list_bullet_indent,
                          size: 14,
                          color: AppColors.textSecondary(brightness),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${subtasks.where((s) => s.isCompleted).length}/${subtasks.length}',
                          style: AppTextStyles.caption2.copyWith(
                            color: AppColors.textSecondary(brightness),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final progress = subtasks.isEmpty
                                  ? 0.0
                                  : subtasks.where((s) => s.isCompleted).length /
                                      subtasks.length;
                              return Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.separator(brightness)
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: constraints.maxWidth * progress,
                                    decoration: BoxDecoration(
                                      color: subtasks.every((s) => s.isCompleted)
                                          ? AppColors.success
                                          : AppColors.primary(brightness),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
