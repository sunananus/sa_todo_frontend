// lib/core/utils/natural_language_parser.dart
// 自然语言任务解析器
// 支持：日期/时间、优先级、标签、重复规则

import 'parsed_task.dart';

class NaturalLanguageParser {
  static final _tagPattern = RegExp(r'#(\S+)');
  static final _priorityPattern = RegExp(r'!(高|中|低|high|medium|low|[123])');
  static final _recurrencePatterns = {
    RegExp(r'每天|daily'): 'daily',
    RegExp(r'每周|weekly'): 'weekly',
    RegExp(r'每月|monthly'): 'monthly',
    RegExp(r'每年|yearly'): 'yearly',
  };

  static ParsedTask parse(String input) {
    String title = input;
    DateTime? dueDate;
    int priority = 0;
    final tags = <String>[];
    String? recurrenceRule;

    // 提取标签 #xxx
    for (final match in _tagPattern.allMatches(input)) {
      tags.add(match.group(1)!);
    }
    title = title.replaceAll(_tagPattern, '').trim();

    // 提取优先级 !高 !中 !低 !1 !2 !3
    final priorityMatch = _priorityPattern.firstMatch(title);
    if (priorityMatch != null) {
      final p = priorityMatch.group(1)!;
      switch (p) {
        case '高':
        case 'high':
        case '3':
          priority = 3;
          break;
        case '中':
        case 'medium':
        case '2':
          priority = 2;
          break;
        case '低':
        case 'low':
        case '1':
          priority = 1;
          break;
      }
      title = title.replaceAll(_priorityPattern, '').trim();
    }

    // 提取重复规则
    for (final entry in _recurrencePatterns.entries) {
      if (entry.key.hasMatch(title)) {
        recurrenceRule = entry.value;
        title = title.replaceAll(entry.key, '').trim();
        break;
      }
    }

    // 提取日期/时间
    dueDate = _extractDate(title);
    if (dueDate != null) {
      title = _removeDateExpressions(title).trim();
    }

    // 清理多余空格
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedTask(
      title: title,
      dueDate: dueDate,
      priority: priority,
      tags: tags,
      recurrenceRule: recurrenceRule,
    );
  }

  static DateTime? _extractDate(String text) {
    final now = DateTime.now();

    // 今天
    if (text.contains('今天') || text.contains('today')) {
      return _combineWithTime(now, text);
    }

    // 明天
    if (text.contains('明天') || text.contains('tomorrow')) {
      return _combineWithTime(now.add(const Duration(days: 1)), text);
    }

    // 后天
    if (text.contains('后天')) {
      return _combineWithTime(now.add(const Duration(days: 2)), text);
    }

    // 下周
    if (text.contains('下周') || text.contains('next week')) {
      final nextWeek = now.add(Duration(days: 7 - now.weekday + 1));
      return _combineWithTime(nextWeek, text);
    }

    // 下周一~下周日
    final weekdayMap = {
      '一': 1, '二': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '日': 7, '天': 7,
    };
    for (final entry in weekdayMap.entries) {
      final pattern = RegExp('下周${entry.key}');
      if (pattern.hasMatch(text)) {
        final targetDay = entry.value;
        final daysUntil = (targetDay - now.weekday + 7) % 7;
        final target = now.add(Duration(days: daysUntil == 0 ? 7 : daysUntil));
        return _combineWithTime(target, text);
      }
    }

    // 周一~周日（本周）
    for (final entry in weekdayMap.entries) {
      final pattern = RegExp('周${entry.key}|星期${entry.key}');
      if (pattern.hasMatch(text)) {
        final targetDay = entry.value;
        var daysUntil = (targetDay - now.weekday) % 7;
        if (daysUntil <= 0) daysUntil += 7;
        final target = now.add(Duration(days: daysUntil));
        return _combineWithTime(target, text);
      }
    }

    // MM/dd 或 MM-dd
    final datePattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})');
    final dateMatch = datePattern.firstMatch(text);
    if (dateMatch != null) {
      final month = int.parse(dateMatch.group(1)!);
      final day = int.parse(dateMatch.group(2)!);
      var year = now.year;
      var date = DateTime(year, month, day);
      if (date.isBefore(now)) {
        date = DateTime(year + 1, month, day);
      }
      return _combineWithTime(date, text);
    }

    return null;
  }

  static DateTime _combineWithTime(DateTime date, String text) {
    // 下午3点 / 15:00 / 3pm
    final timePattern = RegExp(r'(\d{1,2})[:\：](\d{2})');
    final timeMatch = timePattern.firstMatch(text);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // 上午/下午 X 点
    final cnTimePattern = RegExp(r'(上午|下午|早上|晚上)?(\d{1,2})点(?:(\d{1,2})分?)?');
    final cnMatch = cnTimePattern.firstMatch(text);
    if (cnMatch != null) {
      var hour = int.parse(cnMatch.group(2)!);
      final minute = cnMatch.group(3) != null ? int.parse(cnMatch.group(3)!) : 0;
      final period = cnMatch.group(1);
      if (period == '下午' || period == '晚上') {
        if (hour < 12) hour += 12;
      } else if (period == '上午' || period == '早上') {
        if (hour == 12) hour = 0;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Xpm / Xam
    final enTimePattern = RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false);
    final enMatch = enTimePattern.firstMatch(text);
    if (enMatch != null) {
      var hour = int.parse(enMatch.group(1)!);
      final isPm = enMatch.group(2)!.toLowerCase() == 'pm';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour);
    }

    // 默认当天 9:00
    return DateTime(date.year, date.month, date.day, 9, 0);
  }

  static String _removeDateExpressions(String text) {
    final patterns = [
      '今天', '明天', '后天', '下周',
      '周一', '周二', '周三', '周四', '周五', '周六', '周日',
      '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日',
      '下周一', '下周二', '下周三', '下周四', '下周五', '下周六', '下周日',
      'today', 'tomorrow', 'next week',
    ];
    String result = text;
    for (final p in patterns) {
      result = result.replaceAll(p, '');
    }
    // 移除时间表达
    result = result.replaceAll(RegExp(r'\d{1,2}[:\：]\d{2}'), '');
    result = result.replaceAll(RegExp(r'(上午|下午|早上|晚上)\d{1,2}点(\d{1,2}分?)?'), '');
    result = result.replaceAll(RegExp(r'\d{1,2}\s*(am|pm)', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'\d{1,2}[/\-]\d{1,2}'), '');
    return result;
  }
}
