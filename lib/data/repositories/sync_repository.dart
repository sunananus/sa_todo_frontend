// lib/data/repositories/sync_repository.dart
// 同步仓库 — 实现 Local-First 同步策略

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../api/api_client.dart';
import '../models/task_model.dart';
import '../models/list_model.dart';
import '../models/tag_model.dart';
import '../models/task_tag_model.dart';
import 'task_repository.dart';
import 'list_repository.dart';
import 'tag_repository.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    api: ref.read(apiClientProvider),
    taskRepo: ref.read(taskRepositoryProvider),
    listRepo: ref.read(listRepositoryProvider),
    tagRepo: ref.read(tagRepositoryProvider),
  );
});

class SyncRepository {
  final ApiClient api;
  final TaskRepository taskRepo;
  final ListRepository listRepo;
  final TagRepository tagRepo;

  SyncRepository({
    required this.api,
    required this.taskRepo,
    required this.listRepo,
    required this.tagRepo,
  });

  /// 执行全量同步（先 push 再 pull）
  Future<SyncResult> syncFull() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getString(AppConstants.lastSyncTimeKey) ??
          '1970-01-01T00:00:00Z';

      // 收集本地未同步的变更
      final changes = <String, dynamic>{
        'tasks': taskRepo.unsyncedTasks.map((t) => t.toJson()).toList(),
        'lists': listRepo.unsyncedLists.map((l) => l.toJson()).toList(),
        'tags': tagRepo.unsyncedTags.map((t) => t.toJson()).toList(),
        'task_tags': tagRepo.unsyncedTaskTags.map((tt) => tt.toJson()).toList(),
      };

      final response = await api.syncFull({
        'last_sync_time': lastSyncTime,
        'changes': changes,
      });

      if (!response.isSuccess || response.data == null) {
        return SyncResult(success: false, message: response.message);
      }

      final data = response.data!;

      // 处理服务端返回的变更
      final serverChanges =
          data['server_changes'] as Map<String, dynamic>? ?? {};

      // 合并服务端数据
      if (serverChanges['tasks'] != null) {
        final serverTasks = (serverChanges['tasks'] as List)
            .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
            .toList();
        taskRepo.mergeFromServer(serverTasks);
      }

      if (serverChanges['lists'] != null) {
        final serverLists = (serverChanges['lists'] as List)
            .map((j) => ListModel.fromJson(j as Map<String, dynamic>))
            .toList();
        listRepo.mergeFromServer(serverLists);
      }

      if (serverChanges['tags'] != null || serverChanges['task_tags'] != null) {
        final serverTags = serverChanges['tags'] != null
            ? (serverChanges['tags'] as List)
                .map((j) => TagModel.fromJson(j as Map<String, dynamic>))
                .toList()
            : <TagModel>[];
        final serverTaskTags = serverChanges['task_tags'] != null
            ? (serverChanges['task_tags'] as List)
                .map((j) => TaskTagModel.fromJson(j as Map<String, dynamic>))
                .toList()
            : <TaskTagModel>[];
        tagRepo.mergeFromServer(serverTags, serverTaskTags);
      }

      // 保存服务端时间为下次同步时间
      final serverTime =
          serverChanges['server_time'] as String? ??
          (data['push_result'] as Map<String, dynamic>?)?['server_time'] as String?;
      if (serverTime != null) {
        await prefs.setString(AppConstants.lastSyncTimeKey, serverTime);
      }

      final pushResult =
          data['push_result'] as Map<String, dynamic>? ?? {};
      final acceptedCount = pushResult['accepted_count'] as int? ?? 0;

      return SyncResult(
        success: true,
        message: '同步成功',
        acceptedCount: acceptedCount,
      );
    } catch (e) {
      return SyncResult(success: false, message: '同步失败: $e');
    }
  }

  /// 初始加载：从服务器获取全量数据
  Future<void> initialLoad() async {
    await listRepo.loadFromServer();
    await tagRepo.loadFromServer();
    await taskRepo.loadFromServer();
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int acceptedCount;

  const SyncResult({
    required this.success,
    this.message = '',
    this.acceptedCount = 0,
  });
}
