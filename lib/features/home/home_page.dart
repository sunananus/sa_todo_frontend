// lib/features/home/home_page.dart
// 主页 — 任务列表

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/list_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../widget/widget_provider.dart';
import 'home_provider.dart';
import 'widgets/task_item_card.dart';
import 'widgets/quick_add_bar.dart';
import 'widgets/task_detail_drawer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.initialLoad();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
    // 初始加载后刷新小组件
    ref.read(widgetServiceProvider).refreshWidget();
  }

  Future<void> _sync() async {
    ref.read(syncStateProvider.notifier).state = SyncState.syncing;
    try {
      final syncRepo = ref.read(syncRepositoryProvider);
      final result = await syncRepo.syncFull();
      ref.read(syncStateProvider.notifier).state =
          result.success ? SyncState.success : SyncState.error;
    } catch (_) {
      ref.read(syncStateProvider.notifier).state = SyncState.error;
    }
    // 自动恢复
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) ref.read(syncStateProvider.notifier).state = SyncState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    // 监听任务变更以重建 UI 和刷新小组件
    final tasks = ref.watch(filteredTasksProvider);
    ref.listen(taskRepositoryProvider, (prev, next) {
      ref.read(widgetServiceProvider).refreshWidget();
    });
    final listsAsync = ref.watch(listRepositoryProvider);
    final lists = listsAsync.valueOrNull ?? [];
    final tagsAsync = ref.watch(tagRepositoryProvider);
    final allTags = tagsAsync.valueOrNull ?? [];
    final tagRepo = ref.read(tagRepositoryProvider.notifier);
    final selectedListId = ref.watch(selectedListIdProvider);
    final syncState = ref.watch(syncStateProvider);

    final selectedList = selectedListId != null
        ? lists.where((l) => l.id == selectedListId).firstOrNull
        : null;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      child: Stack(
        children: [
          // 背景渐变装饰
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary(brightness).withValues(alpha: 0.12),
                    AppColors.primary(brightness).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.08),
                    AppColors.success.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 主内容
          CustomScrollView(
            slivers: [
              // 导航栏
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  ref.watch(isSearchModeProvider)
                      ? '搜索结果'
                      : selectedList?.name ?? '全部任务',
                  style: AppTextStyles.largeTitleBold.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 搜索按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final isSearch = ref.read(isSearchModeProvider);
                        if (isSearch) {
                          ref.read(searchQueryProvider.notifier).state = '';
                        } else {
                          _showSearchBar(context, ref);
                        }
                      },
                      child: Icon(
                        ref.watch(isSearchModeProvider)
                            ? CupertinoIcons.xmark_circle_fill
                            : CupertinoIcons.search,
                        color: AppColors.primary(brightness),
                      ),
                    ),
                    // 同步按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: syncState == SyncState.syncing ? null : _sync,
                      child: syncState == SyncState.syncing
                          ? const CupertinoActivityIndicator()
                          : Icon(
                              syncState == SyncState.success
                                  ? CupertinoIcons.checkmark_circle
                                  : syncState == SyncState.error
                                      ? CupertinoIcons.exclamationmark_circle
                                      : CupertinoIcons.arrow_2_circlepath,
                              color: syncState == SyncState.success
                                  ? AppColors.success
                                  : syncState == SyncState.error
                                      ? AppColors.error
                                      : AppColors.primary(brightness),
                            ),
                    ),
                  ],
                ),
                backgroundColor:
                    AppColors.background(brightness).withValues(alpha: 0.8),
              ),

              // 清单筛选横条
              if (lists.length > 1)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip(
                          context,
                          label: '全部',
                          isSelected: selectedListId == null,
                          onTap: () => ref
                              .read(selectedListIdProvider.notifier)
                              .state = null,
                        ),
                        ...lists.map((list) => _buildFilterChip(
                              context,
                              label: list.name,
                              isSelected: selectedListId == list.id,
                              color: _parseColor(list.colorCode),
                              onTap: () => ref
                                  .read(selectedListIdProvider.notifier)
                                  .state = list.id,
                            )),
                      ],
                    ),
                  ),
                ),

              // 加载中
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              // 空状态
              else if (tasks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal,
                          size: 64,
                          color: AppColors.textSecondary(brightness)
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ref.watch(isSearchModeProvider)
                              ? '没有找到匹配的任务'
                              : '没有待办事项',
                          style: AppTextStyles.title3.copyWith(
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ref.watch(isSearchModeProvider)
                              ? '试试其他关键词'
                              : '点击底部 + 快速添加',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary(brightness)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // 任务列表
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  sliver: SliverReorderableList(
                    itemCount: tasks.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final taskIds = tasks.map((t) => t.id).toList();
                      final item = taskIds.removeAt(oldIndex);
                      taskIds.insert(newIndex, item);
                      await ref.read(taskRepositoryProvider.notifier).reorderTasks(taskIds);
                    },
                    itemBuilder: (context, index) {
                        final task = tasks[index];
                        final allTasks = ref.read(taskRepositoryProvider).valueOrNull ?? [];
                        final taskSubtasks = allTasks.where((t) => t.parentId == task.id).toList();
                        final taskTagNames = tagRepo.taskTags
                            .where((tt) => tt.taskId == task.id)
                            .map((tt) => allTags
                                .where((t) => t.id == tt.tagId)
                                .map((t) => t.name)
                                .firstOrNull)
                            .whereType<String>()
                            .toList();
                        return KeyedSubtree(
                          key: ValueKey(task.id),
                          child: TaskItemCard(
                            task: task,
                            tagNames: taskTagNames,
                            subtasks: taskSubtasks,
                            onTap: () => setState(() => _selectedTaskId = task.id),
                            onStatusChanged: (checked) async {
                              await ref.read(taskRepositoryProvider.notifier).toggleTaskStatus(task.id);
                            },
                            onSwipeComplete: () async {
                              final taskRepo = ref.read(taskRepositoryProvider.notifier);
                              await taskRepo.toggleTaskStatus(task.id);
                              if (mounted) {
                                _showUndoSnackBar(
                                  task.isCompleted ? '任务已恢复' : '任务已完成',
                                  () async => await taskRepo.toggleTaskStatus(task.id),
                                );
                              }
                            },
                            onDismissed: () async {
                              final taskRepo = ref.read(taskRepositoryProvider.notifier);
                              final deletedTask = task;
                              await taskRepo.deleteTask(task.id);
                              if (mounted) {
                                _showUndoSnackBar('任务已删除', () async {
                                  // 恢复已删除的任务（重新创建）
                                  await taskRepo.createTask(
                                    title: deletedTask.title,
                                    description: deletedTask.description,
                                    listId: deletedTask.listId,
                                    priority: deletedTask.priority,
                                    dueDate: deletedTask.dueDate,
                                    parentId: deletedTask.parentId,
                                    recurrenceRule: deletedTask.recurrenceRule,
                                  );
                                });
                              }
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
                              ),
                        );
                      },
                  ),
                ),

              // 已完成任务折叠区域
              if (!ref.watch(isSearchModeProvider))
                SliverToBoxAdapter(
                  child: _buildCompletedSection(brightness),
                ),
            ],
          ),

          // 底部快速添加栏
          Positioned(
            left: 0,
            right: 0,
            bottom: (MediaQuery.sizeOf(context).width >= AppConstants.kDesktopBreakpoint ? 0 : 50) + MediaQuery.paddingOf(context).bottom,
            child: QuickAddBar(
              initialExpanded: GoRouterState.of(context).uri.queryParameters['action'] == 'quickadd',
              onSubmit: (title, parsed) async {
                await ref.read(taskRepositoryProvider.notifier).createTask(
                  title: title,
                  listId: selectedListId ?? AppConstants.inboxListId,
                  dueDate: parsed.dueDate,
                  priority: parsed.priority,
                  recurrenceRule: parsed.recurrenceRule,
                );
                // 添加标签
                if (parsed.tags.isNotEmpty) {
                  final tagRepo = ref.read(tagRepositoryProvider.notifier);
                  for (final tagName in parsed.tags) {
                    final existingTags = ref.read(tagRepositoryProvider).valueOrNull ?? [];
                    final existing = existingTags.where((t) => t.name == tagName).firstOrNull;
                    final tag = existing ?? await tagRepo.createTag(name: tagName);
                    // 获取刚创建的任务 ID
                    final tasks = ref.read(taskRepositoryProvider).valueOrNull ?? [];
                    final newTask = tasks.first;
                    tagRepo.addTagToTask(newTask.id, tag.id);
                  }
                }
              },
            ),
          ),

          // 右侧抽屉 — 任务详情
          if (_selectedTaskId != null)
            GestureDetector(
              onTap: () => setState(() => _selectedTaskId = null),
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.3),
              ),
            ),
          if (_selectedTaskId != null)
            TaskDetailDrawer(
              taskId: _selectedTaskId!,
              onClose: () => setState(() => _selectedTaskId = null),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primary(brightness))
                : AppColors.surface(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(
                    color: AppColors.separator(brightness).withValues(alpha: 0.3),
                  ),
          ),
          child: Text(
            label,
            style: AppTextStyles.subheadlineMedium.copyWith(
              color: isSelected
                  ? CupertinoColors.white
                  : AppColors.textPrimary(brightness),
            ),
          ),
        ),
      ),
    );
  }

  void _showUndoSnackBar(String message, Future<void> Function() onUndo) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 120 + MediaQuery.paddingOf(context).bottom,
        left: 24,
        right: 24,
        child: GestureDetector(
          onTap: () => entry.remove(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.separator(brightness).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(message, style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary(brightness),
                  )),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    entry.remove();
                    await onUndo();
                  },
                  child: Text('撤销', style: AppTextStyles.body.copyWith(
                    color: AppColors.primary(brightness),
                    fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _showSearchBar(BuildContext context, WidgetRef ref) {
    final brightness = CupertinoTheme.brightnessOf(context);
    showCupertinoDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return CupertinoAlertDialog(
          title: const Text('搜索任务'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              placeholder: '输入关键词...',
              autofocus: true,
              suffix: GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).state =
                      controller.text.trim();
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(CupertinoIcons.search,
                      size: 20,
                      color: AppColors.primary(brightness)),
                ),
              ),
              onSubmitted: (value) {
                ref.read(searchQueryProvider.notifier).state =
                    value.trim();
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('搜索'),
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state =
                    controller.text.trim();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  Widget _buildCompletedSection(Brightness brightness) {
    final completedCount = ref.watch(completedCountProvider);
    final showCompleted = ref.watch(showCompletedProvider);

    if (completedCount == 0) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onTap: () => ref.read(showCompletedProvider.notifier).state = !showCompleted,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  showCompleted
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textSecondary(brightness),
                ),
                const SizedBox(width: 8),
                Text(
                  '已完成 ($completedCount)',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
