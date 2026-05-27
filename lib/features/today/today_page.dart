// lib/features/today/today_page.dart
// 我的一天 — 今日任务视图

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../home/home_provider.dart';
import '../home/widgets/task_item_card.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final tasks = ref.watch(todayTasksProvider);
    final allTasks = ref.read(taskRepositoryProvider).valueOrNull ?? [];
    final tagRepo = ref.read(tagRepositoryProvider.notifier);
    final allTags = ref.read(tagRepositoryProvider).valueOrNull ?? [];
    final now = DateTime.now();

    final overdueTasks = tasks.where((t) => t.dueDate!.isBefore(DateTime(now.year, now.month, now.day))).toList();
    final todayTasks = tasks.where((t) => !overdueTasks.contains(t)).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      child: Stack(
        children: [
          // 背景装饰
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.1),
                    AppColors.warning.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  '我的一天',
                  style: AppTextStyles.largeTitleBold.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                backgroundColor:
                    AppColors.background(brightness).withValues(alpha: 0.8),
              ),

              // 日期标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    DateFormat('M月d日 EEEE', 'zh_CN').format(now),
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary(brightness),
                    ),
                  ),
                ),
              ),

              // 空状态
              if (tasks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.sun_max,
                          size: 64,
                          color: AppColors.textSecondary(brightness)
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '今天没有待办任务',
                          style: AppTextStyles.title3.copyWith(
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '享受轻松的一天吧',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary(brightness)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // 逾期任务
                if (overdueTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.exclamationmark_circle,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text(
                            '逾期 (${overdueTasks.length})',
                            style: AppTextStyles.subheadlineMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = overdueTasks[index];
                        return _buildTaskCard(context, ref, task, allTasks, tagRepo, allTags);
                      },
                      childCount: overdueTasks.length,
                    ),
                  ),
                ],

                // 今日任务
                if (todayTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.sunrise,
                              size: 16, color: AppColors.primary(brightness)),
                          const SizedBox(width: 6),
                          Text(
                            '今天 (${todayTasks.length})',
                            style: AppTextStyles.subheadlineMedium.copyWith(
                              color: AppColors.textPrimary(brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = todayTasks[index];
                          return _buildTaskCard(context, ref, task, allTasks, tagRepo, allTags);
                        },
                        childCount: todayTasks.length,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    List<TaskModel> allTasks,
    dynamic tagRepo,
    List allTags,
  ) {
    final taskSubtasks = allTasks.where((t) => t.parentId == task.id).toList();
    final taskTagNames = tagRepo.taskTags
        .where((tt) => tt.taskId == task.id)
        .map((tt) => allTags
            .where((t) => t.id == tt.tagId)
            .map((t) => t.name)
            .firstOrNull)
        .whereType<String>()
        .toList();

    return TaskItemCard(
      task: task,
      tagNames: taskTagNames,
      subtasks: taskSubtasks,
      onTap: () => context.push('/task/${task.id}'),
      onStatusChanged: (checked) async {
        await ref.read(taskRepositoryProvider.notifier).toggleTaskStatus(task.id);
      },
    ).animate().fadeIn(
      duration: AppConstants.animNormal,
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: AppConstants.animNormal,
      curve: Curves.easeOut,
    );
  }
}
