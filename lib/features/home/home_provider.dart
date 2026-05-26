// lib/features/home/home_provider.dart
// 主页状态管理

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
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
  final tasks = ref.watch(taskRepositoryProvider);
  final selectedListId = ref.watch(selectedListIdProvider);

  if (selectedListId == null) {
    return tasks;
  }
  return tasks.where((t) => t.listId == selectedListId).toList();
});

/// 同步状态
enum SyncState { idle, syncing, success, error }

final syncStateProvider = StateProvider<SyncState>((ref) => SyncState.idle);
