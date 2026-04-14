// lib/data/models/task_model.dart
// 任务数据模型

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String listId;
  final int priority;
  final int status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isDeleted;
  final int syncStatus; // 仅本地: 0=未同步, 1=已同步

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.listId = 'inbox',
    this.priority = 0,
    this.status = 0,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.isDeleted = false,
    this.syncStatus = 0,
  });

  bool get isCompleted => status == 1;
  bool get isSynced => syncStatus == 1;

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? listId,
    int? priority,
    int? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isDeleted,
    int? syncStatus,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      listId: listId ?? this.listId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      listId: (json['list_id'] as String?) ?? 'inbox',
      priority: (json['priority'] as int?) ?? 0,
      status: (json['status'] as int?) ?? 0,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      syncStatus: 1, // 从服务器来的数据已同步
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'list_id': listId,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
