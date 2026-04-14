// lib/data/repositories/tag_repository.dart
// 标签数据仓库

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../models/tag_model.dart';
import '../models/task_tag_model.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.read(apiClientProvider));
});

class TagRepository {
  final ApiClient _api;
  final _uuid = const Uuid();
  final List<TagModel> _tags = [];
  final List<TaskTagModel> _taskTags = [];

  TagRepository(this._api);

  List<TagModel> get tags => List.unmodifiable(
      _tags.where((t) => !t.isDeleted).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    );

  List<TaskTagModel> get taskTags =>
      List.unmodifiable(_taskTags.where((tt) => !tt.isDeleted).toList());

  List<TagModel> getTagsForTask(String taskId) {
    final tagIds = _taskTags
        .where((tt) => tt.taskId == taskId && !tt.isDeleted)
        .map((tt) => tt.tagId)
        .toSet();
    return tags.where((t) => tagIds.contains(t.id)).toList();
  }

  List<TagModel> get unsyncedTags =>
      _tags.where((t) => t.syncStatus == 0).toList();

  List<TaskTagModel> get unsyncedTaskTags =>
      _taskTags.toList(); // TaskTag 没有 syncStatus，全量推送

  Future<void> loadFromServer() async {
    try {
      final response = await _api.getTags();
      if (response.isSuccess && response.data != null) {
        _tags.clear();
        _tags.addAll(response.data!.map((j) => TagModel.fromJson(j)));
      }
    } catch (_) {}
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

    _tags.add(tag);

    try {
      final response = await _api.createTag(tag.toJson());
      if (response.isSuccess) {
        final index = _tags.indexWhere((t) => t.id == tag.id);
        if (index >= 0) _tags[index] = tag.copyWith(syncStatus: 1);
      }
    } catch (_) {}

    return tag;
  }

  Future<TagModel> updateTag(TagModel tag) async {
    final updated = tag.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 0,
    );
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index >= 0) _tags[index] = updated;

    try {
      await _api.updateTag(tag.id, updated.toJson());
    } catch (_) {}

    return updated;
  }

  Future<void> deleteTag(String tagId) async {
    final now = DateTime.now().toUtc();
    final index = _tags.indexWhere((t) => t.id == tagId);
    if (index >= 0) {
      _tags[index] = _tags[index].copyWith(
        isDeleted: true,
        updatedAt: now,
        syncStatus: 0,
      );
    }
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

  void mergeFromServer(List<TagModel> serverTags, List<TaskTagModel> serverTaskTags) {
    for (final serverTag in serverTags) {
      final index = _tags.indexWhere((t) => t.id == serverTag.id);
      if (index >= 0) {
        if (serverTag.updatedAt.isAfter(_tags[index].updatedAt)) {
          _tags[index] = serverTag;
        }
      } else {
        _tags.add(serverTag);
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
  }
}
