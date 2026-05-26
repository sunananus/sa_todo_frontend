// lib/features/widget/widget_provider.dart
// 小组件 Riverpod Provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import 'widget_data_service.dart';

/// 小组件更新服务 Provider
final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService(ref);
});

class WidgetService {
  final Ref _ref;

  WidgetService(this._ref);

  /// 刷新小组件数据
  Future<void> refreshWidget() async {
    final taskRepo = _ref.read(taskRepositoryProvider);
    await WidgetDataService.updateWidget(taskRepo.tasks);
  }
}
