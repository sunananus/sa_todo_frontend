// lib/features/home/home_page.dart
// 主页 — 任务列表

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/list_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../widget/widget_provider.dart';
import 'home_provider.dart';
import 'widgets/task_item_card.dart';
import 'widgets/quick_add_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  bool _isLoading = true;

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
      ref.read(refreshTriggerProvider.notifier).state++;
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
    // 监听刷新触发器以重建 UI
    ref.watch(refreshTriggerProvider);
    // 任务变更时刷新小组件
    ref.listen(refreshTriggerProvider, (prev, next) {
      ref.read(widgetServiceProvider).refreshWidget();
    });
    final taskRepo = ref.read(taskRepositoryProvider);
    final listRepo = ref.read(listRepositoryProvider);
    final selectedListId = ref.watch(selectedListIdProvider);
    final syncState = ref.watch(syncStateProvider);

    final tasks = selectedListId == null
        ? taskRepo.tasks
        : taskRepo.getTasksByListId(selectedListId);

    final lists = listRepo.lists;
    final selectedList = selectedListId != null
        ? listRepo.getListById(selectedListId)
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
                  selectedList?.name ?? '全部任务',
                  style: AppTextStyles.largeTitleBold.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          '没有待办事项',
                          style: AppTextStyles.title3.copyWith(
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击底部 + 快速添加',
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
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasks[index];
                        return TaskItemCard(
                          task: task,
                          onTap: () => context.push('/task/${task.id}'),
                          onStatusChanged: (checked) async {
                            final taskRepo = ref.read(taskRepositoryProvider);
                            await taskRepo.toggleTaskStatus(task.id);
                            ref.read(refreshTriggerProvider.notifier).state++;
                          },
                        );
                      },
                      childCount: tasks.length,
                    ),
                  ),
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
              onSubmit: (title) async {
                final taskRepo = ref.read(taskRepositoryProvider);
                await taskRepo.createTask(
                  title: title,
                  listId: selectedListId ?? AppConstants.inboxListId,
                );
                ref.read(refreshTriggerProvider.notifier).state++;
              },
            ),
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

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
