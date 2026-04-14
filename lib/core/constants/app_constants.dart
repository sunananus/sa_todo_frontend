// lib/core/constants/app_constants.dart
// 全局常量

class AppConstants {
  AppConstants._();

  // App 信息
  static const String appName = 'SA Todo';
  static const String appVersion = '1.0.0';

  // 默认清单
  static const String inboxListId = 'inbox';
  static const String inboxListName = '收集箱';

  // 动画时长
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // 毛玻璃参数
  static const double glassBlurSigma = 12.0;
  static const double glassBlurSigmaDark = 15.0;
  static const double glassBorderRadius = 16.0;
  static const double glassLargeBorderRadius = 24.0;

  // 间距
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // API
  static const String defaultBaseUrl = 'http://localhost:8080/api/v1';
  static const String lastSyncTimeKey = 'last_sync_time';
  static const String baseUrlKey = 'base_url';
  static const String authTokenKey = 'auth_token';
  static const String themeModeKey = 'theme_mode';

  // 优先级
  static const int priorityNone = 0;
  static const int priorityLow = 1;
  static const int priorityMedium = 2;
  static const int priorityHigh = 3;

  // 状态
  static const int statusTodo = 0;
  static const int statusCompleted = 1;
}
