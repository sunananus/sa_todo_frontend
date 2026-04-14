// lib/core/theme/app_colors.dart
// 语义化颜色 Token - iOS 风格

import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._();

  // ========== Light Mode ==========
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF9F9FB);
  static const Color lightGlassTint = Color(0xAAFFFFFF);
  static const Color lightGlassBorder = Color(0x40FFFFFF);
  static const Color lightPrimary = Color(0xFF007AFF);
  static const Color lightPrimaryLight = Color(0xFF5AC8FA);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextTertiary = Color(0xFFC7C7CC);
  static const Color lightSeparator = Color(0xFFC6C6C8);
  static const Color lightGroupedBackground = Color(0xFFF2F2F7);
  static const Color lightCardShadow = Color(0x1A000000);

  // ========== Dark Mode ==========
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceSecondary = Color(0xFF2C2C2E);
  static const Color darkGlassTint = Color(0xB01E1E1E);
  static const Color darkGlassBorder = Color(0x25FFFFFF);
  static const Color darkPrimary = Color(0xFF0A84FF);
  static const Color darkPrimaryLight = Color(0xFF64D2FF);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF48484A);
  static const Color darkSeparator = Color(0xFF38383A);
  static const Color darkGroupedBackground = Color(0xFF000000);
  static const Color darkCardShadow = Color(0x40000000);

  // ========== Priority Colors (共享) ==========
  static const Color priorityHigh = Color(0xFFFF3B30);
  static const Color priorityMedium = Color(0xFFFF9500);
  static const Color priorityLow = Color(0xFF34C759);
  static const Color priorityNone = Color(0xFF8E8E93);

  // ========== Status Colors ==========
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF5AC8FA);

  // ========== 渐变色 ==========
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C759), Color(0xFF30D158)],
  );

  /// 根据亮暗模式返回对应颜色
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? lightBackground : darkBackground;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? lightSurface : darkSurface;

  static Color surfaceSecondary(Brightness brightness) =>
      brightness == Brightness.light ? lightSurfaceSecondary : darkSurfaceSecondary;

  static Color glassTint(Brightness brightness) =>
      brightness == Brightness.light ? lightGlassTint : darkGlassTint;

  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.light ? lightGlassBorder : darkGlassBorder;

  static Color primary(Brightness brightness) =>
      brightness == Brightness.light ? lightPrimary : darkPrimary;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.light ? lightTextPrimary : darkTextPrimary;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.light ? lightTextSecondary : darkTextSecondary;

  static Color separator(Brightness brightness) =>
      brightness == Brightness.light ? lightSeparator : darkSeparator;

  static Color cardShadow(Brightness brightness) =>
      brightness == Brightness.light ? lightCardShadow : darkCardShadow;

  /// 根据优先级返回颜色
  static Color priorityColor(int priority) {
    switch (priority) {
      case 3:
        return priorityHigh;
      case 2:
        return priorityMedium;
      case 1:
        return priorityLow;
      default:
        return priorityNone;
    }
  }
}
