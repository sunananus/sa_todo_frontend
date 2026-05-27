// lib/core/utils/parsed_task.dart
// 自然语言解析结果

class ParsedTask {
  final String title;
  final DateTime? dueDate;
  final int priority; // 0=无, 1=低, 2=中, 3=高
  final List<String> tags;
  final String? recurrenceRule;
  final String? listHint;

  const ParsedTask({
    required this.title,
    this.dueDate,
    this.priority = 0,
    this.tags = const [],
    this.recurrenceRule,
    this.listHint,
  });
}
