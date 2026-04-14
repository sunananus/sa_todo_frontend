// lib/core/widgets/glass_card.dart
// 毛玻璃卡片组件

import 'package:flutter/cupertino.dart';
import '../constants/app_constants.dart';
import 'glass_container.dart';

/// 毛玻璃卡片 — 带内边距的卡片样式
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.glassBorderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingLg),
      margin: margin,
      width: width,
      height: height,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}
