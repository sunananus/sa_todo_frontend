// lib/core/theme/app_theme.dart
// CupertinoThemeData 主题定义

import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 亮色 Cupertino 主题
  static CupertinoThemeData get light => CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.lightPrimary,
        primaryContrastingColor: CupertinoColors.white,
        scaffoldBackgroundColor: AppColors.lightBackground,
        barBackgroundColor: AppColors.glassTint(Brightness.light),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.lightPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.lightTextPrimary,
          ),
          navTitleTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
          navLargeTitleTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary,
          ),
          tabLabelTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.lightTextSecondary,
          ),
          navActionTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.lightPrimary,
          ),
          pickerTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.lightTextPrimary,
          ),
          dateTimePickerTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.lightTextPrimary,
          ),
        ),
      );

  /// 暗色 Cupertino 主题
  static CupertinoThemeData get dark => CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.darkPrimary,
        primaryContrastingColor: CupertinoColors.white,
        scaffoldBackgroundColor: AppColors.darkBackground,
        barBackgroundColor: AppColors.glassTint(Brightness.dark),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.darkPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.darkTextPrimary,
          ),
          navTitleTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
          ),
          navLargeTitleTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
          tabLabelTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          ),
          navActionTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.darkPrimary,
          ),
          pickerTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.darkTextPrimary,
          ),
          dateTimePickerTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.darkTextPrimary,
          ),
        ),
      );
}
