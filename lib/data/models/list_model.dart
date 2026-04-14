// lib/data/models/list_model.dart
// 清单数据模型

class ListModel {
  final String id;
  final String name;
  final String colorCode;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final int syncStatus;

  const ListModel({
    required this.id,
    required this.name,
    this.colorCode = '#4A90D9',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = 0,
  });

  bool get isInbox => id == 'inbox';

  ListModel copyWith({
    String? id,
    String? name,
    String? colorCode,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    int? syncStatus,
  }) {
    return ListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorCode: colorCode ?? this.colorCode,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory ListModel.fromJson(Map<String, dynamic> json) {
    return ListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorCode: (json['color_code'] as String?) ?? '#4A90D9',
      sortOrder: (json['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      syncStatus: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_code': colorCode,
      'sort_order': sortOrder,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
