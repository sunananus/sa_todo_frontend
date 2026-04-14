// lib/core/widgets/glass_bottom_bar.dart
// 毛玻璃底部标签栏

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 底部标签栏项目
class GlassTabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 毛玻璃底部标签栏
class GlassBottomBar extends StatelessWidget {
  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassTint(brightness),
            border: Border(
              top: BorderSide(
                color: AppColors.separator(brightness),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = index == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 24,
                            color: isActive
                                ? AppColors.primary(brightness)
                                : AppColors.textSecondary(brightness),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTextStyles.caption2.copyWith(
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
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
