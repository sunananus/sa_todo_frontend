// lib/features/task_detail/task_detail_page.dart
// 任务详情 / 编辑页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/priority_badge.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/list_repository.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  int _priority = 0;
  String _listId = 'inbox';
  DateTime? _dueDate;


  @override
  void initState() {
    super.initState();
    final taskRepo = ref.read(taskRepositoryProvider.notifier);
    final task = taskRepo.getTaskById(widget.taskId);
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? 0;
    _listId = task?.listId ?? 'inbox';
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final taskRepo = ref.read(taskRepositoryProvider.notifier);
    final task = taskRepo.getTaskById(widget.taskId);
    if (task == null) return;

    await taskRepo.updateTask(task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      listId: _listId,
      dueDate: _dueDate,
      clearDueDate: _dueDate == null && task.dueDate != null,
    ));

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref.read(taskRepositoryProvider.notifier).deleteTask(widget.taskId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final taskRepo = ref.read(taskRepositoryProvider.notifier);
    final task = taskRepo.getTaskById(widget.taskId);
    final lists = ref.watch(listRepositoryProvider);

    if (task == null) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background(brightness),
        navigationBar: const CupertinoNavigationBar(
          middle: Text('任务详情'),
        ),
        child: const Center(child: Text('任务不存在')),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '任务详情',
          style: AppTextStyles.headline
              .copyWith(color: AppColors.textPrimary(brightness)),
        ),
        backgroundColor: AppColors.background(brightness).withValues(alpha: 0.8),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: Text(
            '保存',
            style: TextStyle(
              color: AppColors.primary(brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              GlassCard(
                child: CupertinoTextField.borderless(
                  controller: _titleController,
                  placeholder: '任务标题',
                  style: AppTextStyles.title3.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                  placeholderStyle: AppTextStyles.title3.copyWith(
                    color: AppColors.textSecondary(brightness)
                        .withValues(alpha: 0.5),
                  ),

                ),
              ).animate().fadeIn(duration: AppConstants.animNormal).slideY(begin: 0.1, end: 0, duration: AppConstants.animNormal, curve: Curves.easeOut),

              const SizedBox(height: 12),

              // 描述
              GlassCard(
                child: CupertinoTextField.borderless(
                  controller: _descController,
                  placeholder: '添加备注...',
                  maxLines: 5,
                  minLines: 3,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                  placeholderStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary(brightness)
                        .withValues(alpha: 0.5),
                  ),

                ),
              ).animate().fadeIn(delay: 50.ms, duration: AppConstants.animNormal).slideY(begin: 0.1, end: 0, delay: 50.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),

              const SizedBox(height: 16),

              // 属性区域
              GlassCard(
                child: Column(
                  children: [
                    // 清单选择
                    _buildRow(
                      context,
                      icon: CupertinoIcons.tray,
                      label: '清单',
                      value: lists
                              .where((l) => l.id == _listId)
                              .firstOrNull
                              ?.name ??
                          '收集箱',
                      onTap: () => _showListPicker(context, lists),
                    ),
                    _buildDivider(brightness),

                    // 优先级选择
                    _buildRow(
                      context,
                      icon: CupertinoIcons.flag,
                      label: '优先级',
                      trailing: PriorityBadge(priority: _priority),
                      onTap: () => _showPriorityPicker(context),
                    ),
                    _buildDivider(brightness),

                    // 截止日期
                    _buildRow(
                      context,
                      icon: CupertinoIcons.calendar,
                      label: '截止日期',
                      value: _dueDate != null
                          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                          : '无',
                      valueColor: _dueDate != null &&
                              _dueDate!.isBefore(DateTime.now())
                          ? AppColors.error
                          : null,
                      onTap: () => _showDatePicker(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: AppConstants.animNormal).slideY(begin: 0.1, end: 0, delay: 100.ms, duration: AppConstants.animNormal, curve: Curves.easeOut),

              const SizedBox(height: 24),

              // 信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '创建于 ${DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt.toLocal())}',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary(brightness)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    if (task.completedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '完成于 ${DateFormat('yyyy-MM-dd HH:mm').format(task.completedAt!.toLocal())}',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.success.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: AppConstants.animNormal),

              const SizedBox(height: 32),

              // 删除按钮
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _showDeleteConfirm(context),
                  child: Text(
                    '删除任务',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: AppConstants.animNormal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? trailing,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary(brightness)),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPrimary(brightness)),
            ),
            const Spacer(),
            ?trailing,
            if (value != null)
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: valueColor ?? AppColors.textSecondary(brightness),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textSecondary(brightness).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Brightness brightness) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 32),
      color: AppColors.separator(brightness).withValues(alpha: 0.3),
    );
  }

  void _showListPicker(BuildContext context, List lists) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('选择清单'),
        actions: lists.map((list) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _listId = list.id;
              });
              Navigator.pop(context);
            },
            child: Text(list.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('选择优先级'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() { _priority = 3; });
              Navigator.pop(context);
            },
            child: const Text('🔴 高',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() { _priority = 2; });
              Navigator.pop(context);
            },
            child: const Text('🟡 中',
                style: TextStyle(color: Color(0xFFFF9500))),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() { _priority = 1; });
              Navigator.pop(context);
            },
            child: const Text('🟢 低',
                style: TextStyle(color: Color(0xFF34C759))),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() { _priority = 0; });
              Navigator.pop(context);
            },
            child: const Text('⚪ 无'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('清除'),
                  onPressed: () {
                    setState(() {
                      _dueDate = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _dueDate ?? DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    _dueDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除任务'),
        content: const Text('确定要删除这个任务吗？'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _delete();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
