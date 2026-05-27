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
  return SyncRepository(ref: ref);
});

class SyncRepository {
  final Ref _ref;

  SyncRepository({required Ref ref}) : _ref = ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  /// 执行全量同步（先 push 再 pull）
  Future<SyncResult> syncFull() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getString(AppConstants.lastSyncTimeKey) ??
          '1970-01-01T00:00:00Z';

      // 收集本地未同步的变更
      final taskRepo = _ref.read(taskRepositoryProvider.notifier);
      final listRepo = _ref.read(listRepositoryProvider.notifier);
      final tagRepo = _ref.read(tagRepositoryProvider.notifier);

      final unsyncedTasks = await taskRepo.unsyncedTasks;
      final unsyncedLists = await listRepo.unsyncedLists;
      final unsyncedTags = await tagRepo.unsyncedTags;

      final changes = <String, dynamic>{
        'tasks': unsyncedTasks.map((t) => t.toJson()).toList(),
        'lists': unsyncedLists.map((l) => l.toJson()).toList(),
        'tags': unsyncedTags.map((t) => t.toJson()).toList(),
        'task_tags': tagRepo.unsyncedTaskTags.map((tt) => tt.toJson()).toList(),
      };

      final response = await _api.syncFull({
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

      if (serverChanges['tasks'] != null) {
        final serverTasks = (serverChanges['tasks'] as List)
            .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await taskRepo.mergeFromServer(serverTasks);
      }

      if (serverChanges['lists'] != null) {
        final serverLists = (serverChanges['lists'] as List)
            .map((j) => ListModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await listRepo.mergeFromServer(serverLists);
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
        await tagRepo.mergeFromServer(serverTags, serverTaskTags);
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
    await _ref.read(listRepositoryProvider.notifier).loadFromServer();
    await _ref.read(tagRepositoryProvider.notifier).loadFromServer();
    await _ref.read(taskRepositoryProvider.notifier).loadFromServer();
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
