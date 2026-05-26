// lib/features/widget/widget_data_service.dart
// 小组件数据服务 — 桥接内存任务列表与原生小组件共享存储

import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../../data/models/task_model.dart';

class WidgetDataService {
  static const _appGroupId = 'group.com.satodo.saTodo';
  static const _androidWidgetName = 'SaTodoWidgetProvider';
  static const _iOSWidgetName = 'SATodoWidget';
  static const _pendingTasksKey = 'pending_tasks';
  static const _taskCountKey = 'task_count';
  static const _maxTasks = 5;

  /// 初始化 home_widget（设置 iOS App Group）
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// 将未完成任务推送到小组件共享存储
  static Future<void> updateWidget(List<TaskModel> tasks) async {
    // 过滤未完成、未删除的任务
    final pending = tasks
        .where((t) => !t.isCompleted && !t.isDeleted)
        .toList()
      ..sort((a, b) {
        if (a.priority != b.priority) return b.priority.compareTo(a.priority);
        return b.createdAt.compareTo(a.createdAt);
      });

    final displayTasks = pending.take(_maxTasks).toList();
    final totalCount = pending.length;

    // 序列化为 JSON
    final jsonArray = displayTasks
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'priority': t.priority,
            })
        .toList();

    await HomeWidget.saveWidgetData<String>(_pendingTasksKey, jsonEncode(jsonArray));
    await HomeWidget.saveWidgetData<int>(_taskCountKey, totalCount);

    // 触发原生小组件刷新
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
