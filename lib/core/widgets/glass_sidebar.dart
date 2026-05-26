// lib/core/widgets/glass_sidebar.dart
// 毛玻璃侧边导航栏

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_bottom_bar.dart';

/// 毛玻璃侧边导航栏
class GlassSidebar extends StatelessWidget {
  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassSidebar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: AppConstants.sidebarWidth,
      height: double.infinity,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassTint(brightness),
              border: Border(
                right: BorderSide(
                  color: AppColors.separator(brightness),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 应用标题
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 20,
                    left: 20,
                    bottom: 24,
                  ),
                  child: Text(
                    AppConstants.appName,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ),
                // 导航项
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = index == currentIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary(brightness)
                                  .withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 20,
                              color: isActive
                                  ? AppColors.primary(brightness)
                                  : AppColors.textSecondary(brightness),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: AppTextStyles.body.copyWith(
                                color: isActive
                                    ? AppColors.primary(brightness)
                                    : AppColors.textSecondary(brightness),
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
