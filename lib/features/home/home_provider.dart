// lib/features/home/home_provider.dart
// 主页状态管理

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/models/list_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/list_repository.dart';
import '../../data/repositories/sync_repository.dart';

/// 当前选中的清单 ID
final selectedListIdProvider = StateProvider<String?>((ref) => null);

/// 应用初始化状态
final appInitProvider = FutureProvider<void>((ref) async {
  final syncRepo = ref.read(syncRepositoryProvider);
  await syncRepo.initialLoad();
});

/// 任务列表 Provider（带过滤）
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final taskRepo = ref.read(taskRepositoryProvider);
  final selectedListId = ref.watch(selectedListIdProvider);

  if (selectedListId == null) {
    return taskRepo.tasks;
  }
  return taskRepo.getTasksByListId(selectedListId);
});

/// 清单列表 Provider
final listsProvider = Provider<List<ListModel>>((ref) {
  final listRepo = ref.read(listRepositoryProvider);
  return listRepo.lists;
});

/// 刷新触发器
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 同步状态
enum SyncState { idle, syncing, success, error }

final syncStateProvider = StateProvider<SyncState>((ref) => SyncState.idle);
