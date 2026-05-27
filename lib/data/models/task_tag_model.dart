// lib/data/models/task_tag_model.dart
// 任务-标签关联模型

import '../local/database.dart';

class TaskTagModel {
  final String id;
  final String taskId;
  final String tagId;
  final bool isDeleted;

  const TaskTagModel({
    required this.id,
    required this.taskId,
    required this.tagId,
    this.isDeleted = false,
  });

  TaskTagModel copyWith({
    String? id,
    String? taskId,
    String? tagId,
    bool? isDeleted,
  }) {
    return TaskTagModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory TaskTagModel.fromJson(Map<String, dynamic> json) {
    return TaskTagModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      tagId: json['tag_id'] as String,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'tag_id': tagId,
      'is_deleted': isDeleted,
    };
  }

  TaskTagEntity toEntity() => TaskTagEntity(
        id: id,
        taskId: taskId,
        tagId: tagId,
        isDeleted: isDeleted,
      );

  factory TaskTagModel.fromEntity(TaskTagEntity entity) => TaskTagModel(
        id: entity.id,
        taskId: entity.taskId,
        tagId: entity.tagId,
        isDeleted: entity.isDeleted,
      );
}
