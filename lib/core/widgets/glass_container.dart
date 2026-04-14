// lib/core/widgets/glass_container.dart
// 核心毛玻璃容器组件 — iOS Frosted Glass Effect

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// 毛玻璃容器 — 所有毛玻璃 UI 的基础组件
///
/// 使用 BackdropFilter + ClipRRect + RepaintBoundary
/// 自动根据 Theme brightness 调整色调和模糊度
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final double? tintOpacity;
  final bool showBorder;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma,
    this.borderRadius = AppConstants.glassBorderRadius,
    this.padding,
    this.margin,
    this.tintColor,
    this.tintOpacity,
    this.showBorder = true,
    this.width,
    this.height,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final sigma = blurSigma ??
        (isDark
            ? AppConstants.glassBlurSigmaDark
            : AppConstants.glassBlurSigma);

    final tint = tintColor ??
        (isDark ? AppColors.darkGlassTint : AppColors.lightGlassTint);

    final border = isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        constraints: constraints,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: tintOpacity != null
                    ? tint.withValues(alpha: tintOpacity!)
                    : tint,
                borderRadius: BorderRadius.circular(borderRadius),
                border: showBorder
                    ? Border.all(color: border, width: 0.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow(brightness),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
