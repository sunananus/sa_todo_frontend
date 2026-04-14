// lib/core/theme/app_theme.dart
// CupertinoThemeData 主题定义

import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 亮色 Cupertino 主题
  static CupertinoThemeData get light => const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.lightPrimary,
        primaryContrastingColor: CupertinoColors.white,
        scaffoldBackgroundColor: AppColors.lightBackground,
        barBackgroundColor: Color(0xE6F2F2F7),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.lightPrimary,
          textStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.lightTextPrimary,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary,
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          navActionTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.lightPrimary,
          ),
        ),
      );

  /// 暗色 Cupertino 主题
  static CupertinoThemeData get dark => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.darkPrimary,
        primaryContrastingColor: CupertinoColors.white,
        scaffoldBackgroundColor: AppColors.darkBackground,
        barBackgroundColor: Color(0xE6000000),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.darkPrimary,
          textStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.darkTextPrimary,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          navActionTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            color: AppColors.darkPrimary,
          ),
        ),
      );
}
