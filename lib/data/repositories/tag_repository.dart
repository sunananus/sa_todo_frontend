// lib/data/repositories/tag_repository.dart
// 标签数据仓库 — Drift 本地持久化 + API 同步

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../local/database.dart';
import '../models/tag_model.dart';
import '../models/task_tag_model.dart';

final tagRepositoryProvider =
    AsyncNotifierProvider<TagRepository, List<TagModel>>(TagRepository.new);

class TagRepository extends AsyncNotifier<List<TagModel>> {
  final _uuid = const Uuid();

  AppDatabase get _db => ref.read(appDatabaseProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  // TaskTags 内存缓存（无 syncStatus，全量推送）
  final List<TaskTagModel> _taskTags = [];

  @override
  Future<List<TagModel>> build() => _loadFromDb();

  Future<List<TagModel>> _loadFromDb() async {
    final entities = await _db.getAllTags();
    final models = entities.map(TagModel.fromEntity).toList();
    models.sort((a, b) => a.name.compareTo(b.name));
    return models;
  }

  Future<void> _notify() async {
    state = AsyncData(await _loadFromDb());
  }

  List<TaskTagModel> get taskTags =>
      List.unmodifiable(_taskTags.where((tt) => !tt.isDeleted).toList());

  Future<List<TagModel>> getTagsForTask(String taskId) async {
    final entities = await _db.getTaskTagsForTask(taskId);
    final tagIds = entities.map((e) => e.tagId).toSet();
    final allTags = state.valueOrNull ?? [];
    return allTags.where((t) => tagIds.contains(t.id)).toList();
  }

  Future<List<TagModel>> get unsyncedTags async {
    final entities = await _db.getUnsyncedTags();
    return entities.map(TagModel.fromEntity).toList();
  }

  List<TaskTagModel> get unsyncedTaskTags => _taskTags.toList();

  Future<void> loadFromServer() async {
    try {
      final response = await _api.getTags();
      if (response.isSuccess && response.data != null) {
        final serverTags =
            response.data!.map((j) => TagModel.fromJson(j)).toList();
        for (final tag in serverTags) {
          await _db.insertTag(tag.toEntity().toCompanion(true));
        }
      }
    } catch (_) {}
    await _notify();
  }

  Future<TagModel> createTag({required String name}) async {
    final now = DateTime.now().toUtc();
    final tag = TagModel(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      syncStatus: 0,
    );

    await _db.insertTag(tag.toEntity().toCompanion(true));
    await _notify();

    try {
      final response = await _api.createTag(tag.toJson());
      if (response.isSuccess) {
        final synced = tag.copyWith(syncStatus: 1);
        await _db.updateTag(synced.toEntity().toCompanion(true));
        await _notify();
      }
    } catch (_) {}

    return tag;
  }

  Future<TagModel> updateTag(TagModel tag) async {
    final updated = tag.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 0,
    );
    await _db.updateTag(updated.toEntity().toCompanion(true));
    await _notify();

    try {
      await _api.updateTag(tag.id, updated.toJson());
    } catch (_) {}

    return updated;
  }

  Future<void> deleteTag(String tagId) async {
    final now = DateTime.now().toUtc();
    final entity = await _db.getTagById(tagId);
    if (entity == null) return;
    final tag = TagModel.fromEntity(entity);

    final deleted = tag.copyWith(
      isDeleted: true,
      updatedAt: now,
      syncStatus: 0,
    );
    await _db.updateTag(deleted.toEntity().toCompanion(true));
    await _notify();

    try {
      await _api.deleteTag(tagId);
    } catch (_) {}
  }

  /// 给任务添加标签
  void addTagToTask(String taskId, String tagId) {
    final exists = _taskTags.any(
      (tt) => tt.taskId == taskId && tt.tagId == tagId && !tt.isDeleted,
    );
    if (!exists) {
      _taskTags.add(TaskTagModel(
        id: _uuid.v4(),
        taskId: taskId,
        tagId: tagId,
      ));
    }
  }

  /// 移除任务标签
  void removeTagFromTask(String taskId, String tagId) {
    final index = _taskTags.indexWhere(
      (tt) => tt.taskId == taskId && tt.tagId == tagId && !tt.isDeleted,
    );
    if (index >= 0) {
      _taskTags[index] = _taskTags[index].copyWith(isDeleted: true);
    }
  }

  Future<void> mergeFromServer(
      List<TagModel> serverTags, List<TaskTagModel> serverTaskTags) async {
    for (final serverTag in serverTags) {
      final localEntity = await _db.getTagById(serverTag.id);
      if (localEntity != null) {
        final local = TagModel.fromEntity(localEntity);
        if (serverTag.updatedAt.isAfter(local.updatedAt)) {
          await _db.updateTag(serverTag.toEntity().toCompanion(true));
        }
      } else {
        await _db.insertTag(serverTag.toEntity().toCompanion(true));
      }
    }
    // TaskTags 简单替换
    for (final serverTT in serverTaskTags) {
      final index = _taskTags.indexWhere((tt) => tt.id == serverTT.id);
      if (index >= 0) {
        _taskTags[index] = serverTT;
      } else {
        _taskTags.add(serverTT);
      }
    }
    await _notify();
  }
}
