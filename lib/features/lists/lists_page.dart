// lib/features/lists/lists_page.dart
// 清单管理页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glass_card.dart';

import '../../data/repositories/list_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../home/home_provider.dart';

class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = CupertinoTheme.brightnessOf(context);
    ref.watch(refreshTriggerProvider);
    final listRepo = ref.read(listRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final lists = listRepo.lists;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              '清单',
              style: AppTextStyles.largeTitleBold
                  .copyWith(color: AppColors.textPrimary(brightness)),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: () => _showCreateDialog(context, ref),
            ),
            backgroundColor:
                AppColors.background(brightness).withValues(alpha: 0.8),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = lists[index];
                  final taskCount = taskRepo
                      .getTasksByListId(list.id)
                      .where((t) => !t.isCompleted)
                      .length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      onTap: () {
                        ref.read(selectedListIdProvider.notifier).state =
                            list.id;
                        // 切换到首页的任务列表，使用底部导航
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _parseColor(list.colorCode)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              list.isInbox
                                  ? CupertinoIcons.tray
                                  : CupertinoIcons.folder,
                              color: _parseColor(list.colorCode),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              list.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary(brightness),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface(brightness)
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$taskCount',
                              style: AppTextStyles.footnoteBold.copyWith(
                                color: AppColors.textSecondary(brightness),
                              ),
                            ),
                          ),
                          if (!list.isInbox) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  _showDeleteConfirm(context, ref, list.id),
                              child: Icon(
                                CupertinoIcons.delete,
                                size: 18,
                                color: AppColors.error.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                childCount: lists.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('新建清单'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '清单名称',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('创建'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final listRepo = ref.read(listRepositoryProvider);
                await listRepo.createList(name: name);
                ref.read(refreshTriggerProvider.notifier).state++;
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, String listId) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除清单'),
        content: const Text('清单下的任务将移至收集箱'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final listRepo = ref.read(listRepositoryProvider);
              await listRepo.deleteList(listId);
              ref.read(refreshTriggerProvider.notifier).state++;
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
