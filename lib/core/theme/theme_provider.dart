// lib/core/theme/theme_provider.dart
// 主题状态管理 — Riverpod

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,
  dark,
  system;

  static AppThemeMode fromString(String value) {
    switch (value) {
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.light;
    }
  }
}

/// 主题状态管理 Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  /// 从本地存储加载主题设置
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(AppConstants.themeModeKey) ?? 'system';
    state = AppThemeMode.fromString(themeStr);
  }

  /// 设置主题
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, mode.name);
  }

  /// 切换主题（仅在 light/dark 之间切换）
  Future<void> toggleTheme() async {
    final newMode =
        state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(newMode);
  }

  /// 获取实际亮度（考虑 system 模式）
  Brightness resolveBrightness(BuildContext context) {
    switch (state) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return MediaQuery.platformBrightnessOf(context);
    }
  }
}
