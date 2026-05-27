// lib/features/home/widgets/task_detail_drawer.dart
// 右侧抽屉 — 任务详情编辑

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/list_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../core/notifications/notification_service.dart';

class TaskDetailDrawer extends ConsumerStatefulWidget {
  final String taskId;
  final VoidCallback onClose;

  const TaskDetailDrawer({
    super.key,
    required this.taskId,
    required this.onClose,
  });

  @override
  ConsumerState<TaskDetailDrawer> createState() => _TaskDetailDrawerState();
}

class _TaskDetailDrawerState extends ConsumerState<TaskDetailDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  int _priority = 0;
  String _listId = 'inbox';
  DateTime? _dueDate;
  TaskModel? _task;
  bool _loading = true;
  List<String> _taskTagIds = [];
  List<TaskModel> _subtasks = [];
  String? _recurrenceRule;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animNormal,
    );
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _loadTask();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(TaskDetailDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _loadTask();
    }
  }

  Future<void> _loadTask() async {
    setState(() => _loading = true);
    final taskRepo = ref.read(taskRepositoryProvider.notifier);
    final task = await taskRepo.getTaskById(widget.taskId);
    if (task != null && mounted) {
      final tagRepo = ref.read(tagRepositoryProvider.notifier);
      final taskTags = await tagRepo.getTagsForTask(widget.taskId);
      final subtasks = await taskRepo.getSubtasks(widget.taskId);
      setState(() {
        _task = task;
        _titleController.text = task.title;
        _descController.text = task.description;
        _priority = task.priority;
        _listId = task.listId;
        _dueDate = task.dueDate;
        _taskTagIds = taskTags.map((t) => t.id).toList();
        _subtasks = subtasks;
        _recurrenceRule = task.recurrenceRule;
        _reminderAt = task.reminderAt;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_task == null) return;
    final taskRepo = ref.read(taskRepositoryProvider.notifier);

    await taskRepo.updateTask(_task!.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      listId: _listId,
      dueDate: _dueDate,
      clearDueDate: _dueDate == null && _task!.dueDate != null,
      recurrenceRule: _recurrenceRule,
      clearRecurrenceRule:
          _recurrenceRule == null && _task!.recurrenceRule != null,
      reminderAt: _reminderAt,
      clearReminderAt: _reminderAt == null && _task!.reminderAt != null,
    ));

    // 调度或取消通知
    final notifId = _task!.id.hashCode;
    if (_reminderAt != null) {
      await NotificationService().scheduleReminder(
        id: notifId,
        title: '任务提醒',
        body: _titleController.text.trim(),
        scheduledTime: _reminderAt!,
      );
    } else {
      await NotificationService().cancel(notifId);
    }
  }

  Future<void> _delete() async {
    await ref.read(taskRepositoryProvider.notifier).deleteTask(widget.taskId);
    widget.onClose();
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final listsAsync = ref.watch(listRepositoryProvider);
    final lists = listsAsync.valueOrNull ?? [];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= AppConstants.kDesktopBreakpoint;
    final drawerWidth = isDesktop ? 400.0 : screenWidth * 0.85;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: drawerWidth,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            )),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background(brightness),
                border: Border(
                  left: BorderSide(
                    color:
                        AppColors.separator(brightness).withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(brightness),
                  Expanded(
                    child: _loading
                        ? const Center(child: CupertinoActivityIndicator())
                        : _task == null
                            ? const Center(child: Text('任务不存在'))
                            : _buildContent(brightness, lists),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Brightness brightness) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 16,
        right: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background(brightness).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: AppColors.separator(brightness).withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _close,
            child: Icon(
              CupertinoIcons.xmark,
              color: AppColors.textSecondary(brightness),
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            '任务详情',
            style: AppTextStyles.headline.copyWith(
              color: AppColors.textPrimary(brightness),
            ),
          ),
          const Spacer(),
          CupertinoButton(
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
        ],
      ),
    );
  }

  Widget _buildContent(Brightness brightness, List lists) {
    return SingleChildScrollView(
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
                color:
                    AppColors.textSecondary(brightness).withValues(alpha: 0.5),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppConstants.animNormal)
              .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: AppConstants.animNormal,
                  curve: Curves.easeOut),

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
                color:
                    AppColors.textSecondary(brightness).withValues(alpha: 0.5),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 50.ms, duration: AppConstants.animNormal)
              .slideY(
                  begin: 0.1,
                  end: 0,
                  delay: 50.ms,
                  duration: AppConstants.animNormal,
                  curve: Curves.easeOut),

          const SizedBox(height: 16),

          // 属性区域
          GlassCard(
            child: Column(
              children: [
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
                _buildRow(
                  context,
                  icon: CupertinoIcons.flag,
                  label: '优先级',
                  trailing: PriorityBadge(priority: _priority),
                  onTap: () => _showPriorityPicker(context),
                ),
                _buildDivider(brightness),
                _buildRow(
                  context,
                  icon: CupertinoIcons.calendar,
                  label: '截止日期',
                  value: _dueDate != null
                      ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                      : '无',
                  valueColor:
                      _dueDate != null && _dueDate!.isBefore(DateTime.now())
                          ? AppColors.error
                          : null,
                  onTap: () => _showDatePicker(context),
                ),
                _buildDivider(brightness),
                _buildRow(
                  context,
                  icon: CupertinoIcons.repeat,
                  label: '重复',
                  value: _recurrenceLabel,
                  onTap: () => _showRecurrencePicker(context),
                ),
                _buildDivider(brightness),
                _buildRow(
                  context,
                  icon: CupertinoIcons.bell,
                  label: '提醒',
                  value: _reminderAt != null
                      ? DateFormat('M/d HH:mm')
                          .format(_reminderAt!.toLocal())
                      : '无',
                  onTap: () => _showReminderPicker(context),
                ),
                _buildDivider(brightness),
                _buildTagRow(context),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: AppConstants.animNormal)
              .slideY(
                  begin: 0.1,
                  end: 0,
                  delay: 100.ms,
                  duration: AppConstants.animNormal,
                  curve: Curves.easeOut),

          const SizedBox(height: 16),

          // 子任务
          _buildSubtaskSection(brightness),

          const SizedBox(height: 24),

          // 信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '创建于 ${DateFormat('yyyy-MM-dd HH:mm').format(_task!.createdAt.toLocal())}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary(brightness)
                        .withValues(alpha: 0.6),
                  ),
                ),
                if (_task!.completedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '完成于 ${DateFormat('yyyy-MM-dd HH:mm').format(_task!.completedAt!.toLocal())}',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.success.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: AppConstants.animNormal),

          const SizedBox(height: 16),

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

          const SizedBox(height: 32),
        ],
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
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textPrimary(brightness)),
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

  Widget _buildSubtaskSection(Brightness brightness) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.list_bullet_indent,
                  size: 20, color: AppColors.textSecondary(brightness)),
              const SizedBox(width: 12),
              Text(
                '子任务',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textPrimary(brightness)),
              ),
              const Spacer(),
              if (_subtasks.isNotEmpty)
                Text(
                  '${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
            ],
          ),
          if (_subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._subtasks.map((sub) => _buildSubtaskItem(sub, brightness)),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showAddSubtaskDialog,
            child: Row(
              children: [
                Icon(CupertinoIcons.add_circled,
                    size: 20, color: AppColors.primary(brightness)),
                const SizedBox(width: 8),
                Text(
                  '添加子任务',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.primary(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 120.ms, duration: AppConstants.animNormal)
        .slideY(
            begin: 0.1,
            end: 0,
            delay: 120.ms,
            duration: AppConstants.animNormal,
            curve: Curves.easeOut);
  }

  Widget _buildSubtaskItem(TaskModel subtask, Brightness brightness) {
    return Dismissible(
      key: ValueKey(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error,
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      onDismissed: (_) async {
        await ref.read(taskRepositoryProvider.notifier).deleteTask(subtask.id);
        setState(() => _subtasks.removeWhere((s) => s.id == subtask.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await ref
                    .read(taskRepositoryProvider.notifier)
                    .toggleTaskStatus(subtask.id);
                final updated = await ref
                    .read(taskRepositoryProvider.notifier)
                    .getTaskById(subtask.id);
                if (updated != null && mounted) {
                  setState(() {
                    final idx =
                        _subtasks.indexWhere((s) => s.id == subtask.id);
                    if (idx >= 0) _subtasks[idx] = updated;
                  });
                }
              },
              child: Icon(
                subtask.isCompleted
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 22,
                color: subtask.isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary(brightness),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtask.title,
                style: AppTextStyles.body.copyWith(
                  color: subtask.isCompleted
                      ? AppColors.textSecondary(brightness)
                      : AppColors.textPrimary(brightness),
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: AppColors.textSecondary(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubtaskDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('添加子任务'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '子任务标题',
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
            child: const Text('添加'),
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                final newSub = await ref
                    .read(taskRepositoryProvider.notifier)
                    .createTask(
                      title: title,
                      listId: _task!.listId,
                      parentId: widget.taskId,
                    );
                setState(() => _subtasks.add(newSub));
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
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
              setState(() {
                _priority = 3;
              });
              Navigator.pop(context);
            },
            child: const Text('🔴 高', style: TextStyle(color: Color(0xFFFF3B30))),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _priority = 2;
              });
              Navigator.pop(context);
            },
            child: const Text('🟡 中', style: TextStyle(color: Color(0xFFFF9500))),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _priority = 1;
              });
              Navigator.pop(context);
            },
            child: const Text('🟢 低', style: TextStyle(color: Color(0xFF34C759))),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _priority = 0;
              });
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

  String get _recurrenceLabel {
    switch (_recurrenceRule) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return '不重复';
    }
  }

  void _showRecurrencePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('重复频率'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _recurrenceRule = null);
              Navigator.pop(context);
            },
            child: const Text('不重复'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _recurrenceRule = 'daily');
              Navigator.pop(context);
            },
            child: const Text('每天'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _recurrenceRule = 'weekly');
              Navigator.pop(context);
            },
            child: const Text('每周'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _recurrenceRule = 'monthly');
              Navigator.pop(context);
            },
            child: const Text('每月'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _recurrenceRule = 'yearly');
              Navigator.pop(context);
            },
            child: const Text('每年'),
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

  void _showReminderPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('设置提醒'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _reminderAt = null);
              Navigator.pop(context);
            },
            child: const Text('关闭提醒'),
          ),
          if (_dueDate != null)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _reminderAt = _dueDate);
                Navigator.pop(context);
              },
              child: const Text('到期时提醒'),
            ),
          if (_dueDate != null)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() =>
                    _reminderAt = _dueDate!.subtract(const Duration(minutes: 15)));
                Navigator.pop(context);
              },
              child: const Text('15 分钟前'),
            ),
          if (_dueDate != null)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() =>
                    _reminderAt = _dueDate!.subtract(const Duration(hours: 1)));
                Navigator.pop(context);
              },
              child: const Text('1 小时前'),
            ),
          if (_dueDate != null)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() =>
                    _reminderAt = _dueDate!.subtract(const Duration(days: 1)));
                Navigator.pop(context);
              },
              child: const Text('1 天前'),
            ),
          if (_dueDate == null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showCustomReminderPicker(context);
              },
              child: const Text('自定义时间'),
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

  void _showCustomReminderPicker(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
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
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () {
                    setState(() => _reminderAt = selectedDate);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: selectedDate,
                onDateTimeChanged: (date) => selectedDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final tagsAsync = ref.watch(tagRepositoryProvider);
    final allTags = tagsAsync.valueOrNull ?? [];
    final taskTags = allTags.where((t) => _taskTagIds.contains(t.id)).toList();

    return GestureDetector(
      onTap: () => _showTagPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(CupertinoIcons.tag,
                size: 20, color: AppColors.textSecondary(brightness)),
            const SizedBox(width: 12),
            Text(
              '标签',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPrimary(brightness)),
            ),
            const Spacer(),
            if (taskTags.isEmpty)
              Text(
                '无',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary(brightness)),
              )
            else
              Wrap(
                spacing: 6,
                children: taskTags
                    .map((t) => TagChip(label: t.name, compact: true))
                    .toList(),
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

  void _showTagPicker(BuildContext context) {
    final tagsAsync = ref.read(tagRepositoryProvider);
    final allTags = tagsAsync.valueOrNull ?? [];
    final tagRepo = ref.read(tagRepositoryProvider.notifier);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('选择标签', style: AppTextStyles.headline),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('完成'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: allTags.isEmpty
                      ? Center(
                          child: Text(
                            '暂无标签，请先创建',
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textSecondary(
                                  CupertinoTheme.brightnessOf(context)),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: allTags.length,
                          itemBuilder: (_, i) {
                            final tag = allTags[i];
                            final isSelected = _taskTagIds.contains(tag.id);
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    _taskTagIds.remove(tag.id);
                                    tagRepo.removeTagFromTask(
                                        widget.taskId, tag.id);
                                  } else {
                                    _taskTagIds.add(tag.id);
                                    tagRepo.addTagToTask(
                                        widget.taskId, tag.id);
                                  }
                                });
                                setState(() {});
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    TagChip(
                                        label: tag.name, selected: isSelected),
                                    const Spacer(),
                                    if (isSelected)
                                      Icon(CupertinoIcons.checkmark_circle_fill,
                                          color: AppColors.primary(
                                              CupertinoTheme.brightnessOf(
                                                  context)),
                                          size: 22),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // 新建标签
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add,
                          size: 18,
                          color: AppColors.primary(
                              CupertinoTheme.brightnessOf(context))),
                      const SizedBox(width: 6),
                      Text(
                          '新建标签',
                          style: TextStyle(
                              color: AppColors.primary(
                                  CupertinoTheme.brightnessOf(context)))),
                    ],
                  ),
                  onPressed: () =>
                      _showCreateTagDialog(context, setModalState),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context, StateSetter setModalState) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('新建标签'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '标签名称',
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
                final tagRepo = ref.read(tagRepositoryProvider.notifier);
                final newTag = await tagRepo.createTag(name: name);
                tagRepo.addTagToTask(widget.taskId, newTag.id);
                setModalState(() {
                  _taskTagIds.add(newTag.id);
                });
                setState(() {});
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
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
