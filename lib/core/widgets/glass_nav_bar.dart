// lib/core/widgets/glass_nav_bar.dart
// 毛玻璃顶部导航栏

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 毛玻璃顶部导航栏
class GlassNavBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool largeTitle;

  const GlassNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.largeTitle = false,
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
              bottom: BorderSide(
                color: AppColors.separator(brightness),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: largeTitle ? 96 : 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ?leading,
                    if (leading != null) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: largeTitle
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: (largeTitle
                                    ? AppTextStyles.largeTitleBold
                                    : AppTextStyles.headline)
                                .copyWith(
                              color: AppColors.textPrimary(brightness),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary(brightness),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) const SizedBox(width: 8),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(largeTitle ? 140 : 88);

  @override
  bool shouldFullyObstruct(BuildContext context) => false;
}
