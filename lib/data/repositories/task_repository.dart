// lib/data/repositories/task_repository.dart
// 任务数据仓库 — 管理本地状态 + API 调用

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../models/task_model.dart';

final taskRepositoryProvider =
    NotifierProvider<TaskRepository, List<TaskModel>>(TaskRepository.new);

class TaskRepository extends Notifier<List<TaskModel>> {
  final _uuid = const Uuid();

  // 本地内存缓存（包含已删除的，全量）
  final List<TaskModel> _tasks = [];

  ApiClient get _api => ref.read(apiClientProvider);

  @override
  List<TaskModel> build() => [];

  /// 排序后的可见任务列表
  List<TaskModel> get _visibleTasks =>
      _tasks.where((t) => !t.isDeleted).toList()
        ..sort((a, b) {
          if (a.status != b.status) return a.status.compareTo(b.status);
          if (a.priority != b.priority) return b.priority.compareTo(a.priority);
          return b.createdAt.compareTo(a.createdAt);
        });

  /// 同步 state 到 UI
  void _notify() => state = _visibleTasks;

  List<TaskModel> getTasksByListId(String listId) {
    return state.where((t) => t.listId == listId).toList();
  }

  List<TaskModel> get unsyncedTasks =>
      _tasks.where((t) => t.syncStatus == 0).toList();

  TaskModel? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 从服务器加载所有任务
  Future<void> loadFromServer() async {
    try {
      final response = await _api.getTasks();
      if (response.isSuccess && response.data != null) {
        _tasks.clear();
        _tasks.addAll(response.data!.map((j) => TaskModel.fromJson(j)));
        _notify();
      }
    } catch (_) {
      // 网络异常，使用本地缓存
    }
  }

  /// 创建任务
  Future<TaskModel> createTask({
    required String title,
    String description = '',
    String listId = 'inbox',
    int priority = 0,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toUtc();
    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      listId: listId,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      syncStatus: 0,
    );

    _tasks.add(task);
    _notify();

    // 异步推送到服务器
    try {
      final response = await _api.createTask(task.toJson());
      if (response.isSuccess) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index >= 0) {
          _tasks[index] = task.copyWith(syncStatus: 1);
          _notify();
        }
      }
    } catch (_) {
      // 离线模式，保持 syncStatus = 0
    }

    return task;
  }

  /// 更新任务
  Future<TaskModel> updateTask(TaskModel task) async {
    final updated = task.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 0,
    );

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = updated;
    }
    _notify();

    try {
      final response = await _api.updateTask(task.id, updated.toJson());
      if (response.isSuccess) {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx >= 0) {
          _tasks[idx] = updated.copyWith(syncStatus: 1);
          _notify();
        }
      }
    } catch (_) {}

    return updated;
  }

  /// 切换任务完成状态
  Future<TaskModel> toggleTaskStatus(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) throw Exception('Task not found');

    final now = DateTime.now().toUtc();
    final newStatus = task.isCompleted ? 0 : 1;

    final updated = task.copyWith(
      status: newStatus,
      completedAt: newStatus == 1 ? now : null,
      clearCompletedAt: newStatus == 0,
      updatedAt: now,
      syncStatus: 0,
    );

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _tasks[index] = updated;
    }
    _notify();

    try {
      await _api.updateTask(taskId, updated.toJson());
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx >= 0) {
        _tasks[idx] = updated.copyWith(syncStatus: 1);
        _notify();
      }
    } catch (_) {}

    return updated;
  }

  /// 软删除任务
  Future<void> deleteTask(String taskId) async {
    final now = DateTime.now().toUtc();
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _tasks[index] = _tasks[index].copyWith(
        isDeleted: true,
        updatedAt: now,
        syncStatus: 0,
      );
    }
    _notify();

    try {
      await _api.deleteTask(taskId);
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx >= 0) {
        _tasks[idx] = _tasks[idx].copyWith(syncStatus: 1);
        _notify();
      }
    } catch (_) {}
  }

  /// 本地批量更新（同步用）
  void mergeFromServer(List<TaskModel> serverTasks) {
    for (final serverTask in serverTasks) {
      final index = _tasks.indexWhere((t) => t.id == serverTask.id);
      if (index >= 0) {
        final local = _tasks[index];
        if (serverTask.updatedAt.isAfter(local.updatedAt)) {
          _tasks[index] = serverTask;
        }
      } else {
        _tasks.add(serverTask);
      }
    }
    _notify();
  }

  /// 获取统计数据
  Map<String, int> getWeeklyStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final stats = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i + 1));
      final key = '${day.month}/${day.day}';
      stats[key] = _tasks.where((t) {
        if (t.completedAt == null) return false;
        final c = t.completedAt!.toLocal();
        return c.year == day.year && c.month == day.month && c.day == day.day;
      }).length;
    }

    return stats;
  }

  int get totalCompleted =>
      _tasks.where((t) => t.isCompleted && !t.isDeleted).length;

  int get totalPending =>
      _tasks.where((t) => !t.isCompleted && !t.isDeleted).length;
}
