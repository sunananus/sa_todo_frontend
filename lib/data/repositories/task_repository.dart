// lib/data/repositories/task_repository.dart
// 任务数据仓库 — Drift 本地持久化 + API 同步

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../local/database.dart';
import '../models/task_model.dart';

final taskRepositoryProvider =
    AsyncNotifierProvider<TaskRepository, List<TaskModel>>(TaskRepository.new);

class TaskRepository extends AsyncNotifier<List<TaskModel>> {
  final _uuid = const Uuid();

  AppDatabase get _db => ref.read(appDatabaseProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<List<TaskModel>> build() => _loadFromDb();

  /// 从本地数据库加载可见任务
  Future<List<TaskModel>> _loadFromDb() async {
    final entities = await _db.getAllTasks();
    final models = entities.map(TaskModel.fromEntity).toList();
    models.sort(_compareTask);
    return models;
  }

  /// 排序：自定义顺序 → 未完成优先 → 高优先级优先 → 最新优先
  static int _compareTask(TaskModel a, TaskModel b) {
    if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
    if (a.status != b.status) return a.status.compareTo(b.status);
    if (a.priority != b.priority) return b.priority.compareTo(a.priority);
    return b.createdAt.compareTo(a.createdAt);
  }

  /// 通知 UI 刷新
  Future<void> _notify() async {
    state = AsyncData(await _loadFromDb());
  }

  List<TaskModel> getTasksByListId(String listId) {
    final tasks = state.valueOrNull ?? [];
    return tasks.where((t) => t.listId == listId).toList();
  }

  Future<List<TaskModel>> get unsyncedTasks async {
    final entities = await _db.getUnsyncedTasks();
    return entities.map(TaskModel.fromEntity).toList();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final entity = await _db.getTaskById(id);
    return entity != null ? TaskModel.fromEntity(entity) : null;
  }

  /// 从服务器加载所有任务并写入本地 DB
  Future<void> loadFromServer() async {
    try {
      final response = await _api.getTasks();
      if (response.isSuccess && response.data != null) {
        final serverTasks =
            response.data!.map((j) => TaskModel.fromJson(j)).toList();
        for (final task in serverTasks) {
          await _db.insertTask(task.toEntity().toCompanion(true));
        }
        await _notify();
      }
    } catch (_) {
      // 网络异常，使用本地缓存
    }
  }

  /// 获取指定父任务的子任务
  Future<List<TaskModel>> getSubtasks(String parentId) async {
    final allTasks = state.valueOrNull ?? [];
    return allTasks.where((t) => t.parentId == parentId).toList();
  }

  /// 获取顶层任务（无父任务）
  List<TaskModel> get topLevelTasks {
    final tasks = state.valueOrNull ?? [];
    return tasks.where((t) => t.parentId == null).toList();
  }

  /// 创建任务
  Future<TaskModel> createTask({
    required String title,
    String description = '',
    String listId = 'inbox',
    int priority = 0,
    DateTime? dueDate,
    String? parentId,
    String? recurrenceRule,
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
      parentId: parentId,
      recurrenceRule: recurrenceRule,
    );

    // 写入本地 DB
    await _db.insertTask(task.toEntity().toCompanion(true));
    await _notify();

    // 异步推送到服务器
    try {
      final response = await _api.createTask(task.toJson());
      if (response.isSuccess) {
        final synced = task.copyWith(syncStatus: 1);
        await _db.updateTask(synced.toEntity().toCompanion(true));
        await _notify();
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

    await _db.updateTask(updated.toEntity().toCompanion(true));
    await _notify();

    try {
      final response = await _api.updateTask(task.id, updated.toJson());
      if (response.isSuccess) {
        final synced = updated.copyWith(syncStatus: 1);
        await _db.updateTask(synced.toEntity().toCompanion(true));
        await _notify();
      }
    } catch (_) {}

    return updated;
  }

  /// 计算下一次重复日期
  DateTime? _nextDueDate(String rule, DateTime current) {
    switch (rule) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      default:
        return null;
    }
  }

  /// 切换任务完成状态
  Future<TaskModel> toggleTaskStatus(String taskId) async {
    final entity = await _db.getTaskById(taskId);
    if (entity == null) throw Exception('Task not found');
    final task = TaskModel.fromEntity(entity);

    final now = DateTime.now().toUtc();
    final newStatus = task.isCompleted ? 0 : 1;

    final updated = task.copyWith(
      status: newStatus,
      completedAt: newStatus == 1 ? now : null,
      clearCompletedAt: newStatus == 0,
      updatedAt: now,
      syncStatus: 0,
    );

    await _db.updateTask(updated.toEntity().toCompanion(true));
    await _notify();

    try {
      await _api.updateTask(taskId, updated.toJson());
      final synced = updated.copyWith(syncStatus: 1);
      await _db.updateTask(synced.toEntity().toCompanion(true));
      await _notify();
    } catch (_) {}

    // 重复任务：完成时自动生成下一次
    if (newStatus == 1 &&
        task.recurrenceRule != null &&
        task.dueDate != null) {
      final nextDate = _nextDueDate(task.recurrenceRule!, task.dueDate!);
      if (nextDate != null) {
        await createTask(
          title: task.title,
          description: task.description,
          listId: task.listId,
          priority: task.priority,
          dueDate: nextDate,
          parentId: task.parentId,
          recurrenceRule: task.recurrenceRule,
        );
      }
    }

    return updated;
  }

  /// 软删除任务
  Future<void> deleteTask(String taskId) async {
    final entity = await _db.getTaskById(taskId);
    if (entity == null) return;
    final task = TaskModel.fromEntity(entity);

    final now = DateTime.now().toUtc();
    final deleted = task.copyWith(
      isDeleted: true,
      updatedAt: now,
      syncStatus: 0,
    );

    await _db.updateTask(deleted.toEntity().toCompanion(true));
    await _notify();

    try {
      await _api.deleteTask(taskId);
      final synced = deleted.copyWith(syncStatus: 1);
      await _db.updateTask(synced.toEntity().toCompanion(true));
      await _notify();
    } catch (_) {}
  }

  /// 本地批量更新（同步用）
  Future<void> mergeFromServer(List<TaskModel> serverTasks) async {
    for (final serverTask in serverTasks) {
      final localEntity = await _db.getTaskById(serverTask.id);
      if (localEntity != null) {
        final local = TaskModel.fromEntity(localEntity);
        if (serverTask.updatedAt.isAfter(local.updatedAt)) {
          await _db.updateTask(serverTask.toEntity().toCompanion(true));
        }
      } else {
        await _db.insertTask(serverTask.toEntity().toCompanion(true));
      }
    }
    await _notify();
  }

  /// 更新任务排序顺序
  Future<void> reorderTasks(List<String> taskIds) async {
    for (int i = 0; i < taskIds.length; i++) {
      final entity = await _db.getTaskById(taskIds[i]);
      if (entity != null) {
        final task = TaskModel.fromEntity(entity);
        final updated = task.copyWith(sortOrder: i, updatedAt: DateTime.now().toUtc());
        await _db.updateTask(updated.toEntity().toCompanion(true));
      }
    }
    await _notify();
  }

  /// 获取统计数据
  Future<Map<String, int>> getWeeklyStats() async {
    final entities = await _db.getAllTasksIncludingDeleted();
    final tasks = entities.map(TaskModel.fromEntity).toList();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final stats = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i + 1));
      final key = '${day.month}/${day.day}';
      stats[key] = tasks.where((t) {
        if (t.completedAt == null) return false;
        final c = t.completedAt!.toLocal();
        return c.year == day.year && c.month == day.month && c.day == day.day;
      }).length;
    }

    return stats;
  }

  Future<int> get totalCompleted async {
    final tasks = state.valueOrNull ?? [];
    return tasks.where((t) => t.isCompleted).length;
  }

  Future<int> get totalPending async {
    final tasks = state.valueOrNull ?? [];
    return tasks.where((t) => !t.isCompleted).length;
  }

  /// 计算连续完成天数
  Future<int> get currentStreak async {
    final entities = await _db.getAllTasksIncludingDeleted();
    final tasks = entities.map(TaskModel.fromEntity).toList();
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final hasCompleted = tasks.any((t) {
        if (t.completedAt == null) return false;
        final c = t.completedAt!.toLocal();
        return c.year == day.year && c.month == day.month && c.day == day.day;
      });
      if (hasCompleted) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  /// 计算最长连续完成天数
  Future<int> get longestStreak async {
    final entities = await _db.getAllTasksIncludingDeleted();
    final tasks = entities.map(TaskModel.fromEntity).toList();

    // 获取所有有完成任务的日期
    final completedDates = <DateTime>{};
    for (final t in tasks) {
      if (t.completedAt != null) {
        final c = t.completedAt!.toLocal();
        completedDates.add(DateTime(c.year, c.month, c.day));
      }
    }
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates.toList()..sort();
    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }
    return maxStreak;
  }

  /// 优先级分布统计
  Future<Map<String, int>> getPriorityDistribution() async {
    final tasks = state.valueOrNull ?? [];
    return {
      '高': tasks.where((t) => t.priority == 3 && !t.isCompleted).length,
      '中': tasks.where((t) => t.priority == 2 && !t.isCompleted).length,
      '低': tasks.where((t) => t.priority == 1 && !t.isCompleted).length,
      '无': tasks.where((t) => t.priority == 0 && !t.isCompleted).length,
    };
  }
}
