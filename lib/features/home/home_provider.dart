// lib/features/home/home_provider.dart
// 主页状态管理

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/sync_repository.dart';

/// 当前选中的清单 ID
final selectedListIdProvider = StateProvider<String?>((ref) => null);

/// 搜索关键词
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 是否显示已完成任务
final showCompletedProvider = StateProvider<bool>((ref) => false);

/// 是否处于搜索模式
final isSearchModeProvider = Provider<bool>((ref) {
  return ref.watch(searchQueryProvider).isNotEmpty;
});

/// 应用初始化状态
final appInitProvider = FutureProvider<void>((ref) async {
  final syncRepo = ref.read(syncRepositoryProvider);
  await syncRepo.initialLoad();
});

/// 任务列表 Provider（带过滤 + 搜索，默认隐藏已完成）
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(taskRepositoryProvider);
  final selectedListId = ref.watch(selectedListIdProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final showCompleted = ref.watch(showCompletedProvider);

  var tasks = tasksAsync.valueOrNull ?? [];

  // 仅显示顶层任务（子任务在卡片内展开显示）
  tasks = tasks.where((t) => t.parentId == null).toList();

  // 默认隐藏已完成任务
  if (!showCompleted) {
    tasks = tasks.where((t) => !t.isCompleted).toList();
  }

  // 按清单过滤
  if (selectedListId != null) {
    tasks = tasks.where((t) => t.listId == selectedListId).toList();
  }

  // 按搜索关键词过滤
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    tasks = tasks.where((t) {
      return t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
    }).toList();
  }

  return tasks;
});

/// 已完成任务数量
final completedCountProvider = Provider<int>((ref) {
  final tasksAsync = ref.watch(taskRepositoryProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  return tasks.where((t) => t.parentId == null && t.isCompleted).length;
});

/// 今日任务：今天到期 + 已逾期的任务
final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksAsync = ref.watch(taskRepositoryProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  return tasks.where((t) {
    if (t.parentId != null) return false; // 只显示顶层任务
    if (t.isCompleted) return false; // 不显示已完成
    if (t.dueDate == null) return false;
    final due = t.dueDate!;
    return due.isBefore(todayEnd); // 今天或逾期
  }).toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
});

/// 按日期分组的任务（日历用）
final tasksByDateProvider = Provider.family<List<TaskModel>, DateTime>((ref, date) {
  final tasksAsync = ref.watch(taskRepositoryProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  final dayStart = DateTime(date.year, date.month, date.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  return tasks.where((t) {
    if (t.dueDate == null) return false;
    return t.dueDate!.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
           t.dueDate!.isBefore(dayEnd);
  }).toList();
});

/// 同步状态
enum SyncState { idle, syncing, success, error }

final syncStateProvider = StateProvider<SyncState>((ref) => SyncState.idle);
