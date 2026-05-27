// lib/data/models/task_model.dart
// 任务数据模型

import '../local/database.dart';

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
  final String? parentId; // 父任务 ID，null 表示顶层任务
  final String? recurrenceRule; // 重复规则：daily/weekly/monthly/yearly 或 RRULE
  final DateTime? reminderAt; // 提醒时间
  final int sortOrder; // 排序顺序

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
    this.parentId,
    this.recurrenceRule,
    this.reminderAt,
    this.sortOrder = 0,
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
    String? parentId,
    bool clearParentId = false,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    int? sortOrder,
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
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      recurrenceRule: clearRecurrenceRule ? null : (recurrenceRule ?? this.recurrenceRule),
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      sortOrder: sortOrder ?? this.sortOrder,
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
      parentId: json['parent_id'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : null,
      sortOrder: (json['sort_order'] as int?) ?? 0,
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
      'parent_id': parentId,
      'recurrence_rule': recurrenceRule,
      'reminder_at': reminderAt?.toUtc().toIso8601String(),
      'sort_order': sortOrder,
    };
  }

  TaskEntity toEntity() => TaskEntity(
        id: id,
        title: title,
        description: description,
        listId: listId,
        priority: priority,
        status: status,
        dueDate: dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        isDeleted: isDeleted,
        syncStatus: syncStatus,
        parentId: parentId,
        recurrenceRule: recurrenceRule,
        reminderAt: reminderAt,
        sortOrder: sortOrder,
      );

  factory TaskModel.fromEntity(TaskEntity entity) => TaskModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        listId: entity.listId,
        priority: entity.priority,
        status: entity.status,
        dueDate: entity.dueDate,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        completedAt: entity.completedAt,
        isDeleted: entity.isDeleted,
        syncStatus: entity.syncStatus,
        parentId: entity.parentId,
        recurrenceRule: entity.recurrenceRule,
        reminderAt: entity.reminderAt,
        sortOrder: entity.sortOrder,
      );
}
