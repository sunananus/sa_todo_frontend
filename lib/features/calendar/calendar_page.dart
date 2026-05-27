// lib/features/calendar/calendar_page.dart
// 日历视图 — 按日期查看任务

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../home/home_provider.dart';
import '../home/widgets/task_item_card.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    return ref.read(tasksByDateProvider(day));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final selectedTasks = _selectedDay != null
        ? ref.watch(tasksByDateProvider(_selectedDay!))
        : <TaskModel>[];
    final allTasks = ref.read(taskRepositoryProvider).valueOrNull ?? [];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              '日历',
              style: AppTextStyles.largeTitleBold.copyWith(
                color: AppColors.textPrimary(brightness),
              ),
            ),
            backgroundColor:
                AppColors.background(brightness).withValues(alpha: 0.8),
          ),

          // 日历组件
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.separator(brightness).withValues(alpha: 0.2),
                ),
              ),
              child: TableCalendar<TaskModel>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getTasksForDay,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary(brightness).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: AppColors.primary(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary(brightness),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  defaultTextStyle: TextStyle(
                    color: AppColors.textPrimary(brightness),
                  ),
                  weekendTextStyle: TextStyle(
                    color: AppColors.textSecondary(brightness),
                  ),
                  outsideTextStyle: TextStyle(
                    color: AppColors.textSecondary(brightness).withValues(alpha: 0.4),
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppColors.primary(brightness),
                    shape: BoxShape.circle,
                  ),
                  markerSize: 5,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                ),
                headerStyle: HeaderStyle(
                  titleTextStyle: AppTextStyles.headline.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(
                    CupertinoIcons.chevron_left,
                    color: AppColors.primary(brightness),
                  ),
                  rightChevronIcon: Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.primary(brightness),
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                  weekendStyle: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
              ),
            ),
          ),

          // 选中日期的任务列表
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    _selectedDay != null
                        ? '${_selectedDay!.month}月${_selectedDay!.day}日 的任务'
                        : '选择日期查看任务',
                    style: AppTextStyles.subheadlineMedium.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                  const Spacer(),
                  if (selectedTasks.isNotEmpty)
                    Text(
                      '${selectedTasks.length} 个',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (selectedTasks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.calendar_badge_plus,
                        size: 48,
                        color: AppColors.textSecondary(brightness)
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '这天没有任务',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = selectedTasks[index];
                    final taskSubtasks = allTasks
                        .where((t) => t.parentId == task.id)
                        .toList();
                    return TaskItemCard(
                      task: task,
                      subtasks: taskSubtasks,
                      onTap: () => context.push('/task/${task.id}'),
                      onStatusChanged: (checked) async {
                        await ref
                            .read(taskRepositoryProvider.notifier)
                            .toggleTaskStatus(task.id);
                      },
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: AppConstants.animNormal,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: Duration(milliseconds: 50 * index),
                          duration: AppConstants.animNormal,
                          curve: Curves.easeOut,
                        );
                  },
                  childCount: selectedTasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
