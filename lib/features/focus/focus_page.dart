// lib/features/focus/focus_page.dart
// 专注模式 — 番茄钟全屏页面

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'focus_provider.dart';

class FocusPage extends ConsumerWidget {
  final String? taskTitle;

  const FocusPage({super.key, this.taskTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final focus = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(brightness),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background(brightness).withValues(alpha: 0.8),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.xmark, color: AppColors.textSecondary(brightness)),
        ),
        middle: Text(
          focus.phaseLabel,
          style: AppTextStyles.headline.copyWith(
            color: AppColors.textPrimary(brightness),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 任务标题
            if (taskTitle != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  taskTitle!,
                  style: AppTextStyles.title3.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 40),
            ],

            // 圆形进度
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景圆
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface(brightness).withValues(alpha: 0.5),
                      border: Border.all(
                        color: AppColors.separator(brightness).withValues(alpha: 0.2),
                        width: 4,
                      ),
                    ),
                  ),
                  // 进度圆
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(
                      painter: _CircleProgressPainter(
                        progress: focus.progress,
                        color: focus.phase == FocusPhase.work
                            ? AppColors.primary(brightness)
                            : AppColors.success,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  // 时间显示
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        focus.timeDisplay,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary(brightness),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        focus.isRunning ? '专注中...' : '准备开始',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 番茄计数
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isActive = i < (focus.completedPomodoros % 4 == 0 && focus.completedPomodoros > 0
                    ? 4
                    : focus.completedPomodoros % 4);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    CupertinoIcons.circle_fill,
                    size: 12,
                    color: isActive
                        ? AppColors.error
                        : AppColors.textSecondary(brightness).withValues(alpha: 0.3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),
            Text(
              '已完成 ${focus.completedPomodoros} 个番茄',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary(brightness),
              ),
            ),

            const SizedBox(height: 48),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 重置
                CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: notifier.reset,
                  child: Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    color: AppColors.textSecondary(brightness),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 32),

                // 开始/暂停
                GestureDetector(
                  onTap: focus.isRunning ? notifier.pause : notifier.start,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: focus.phase == FocusPhase.work
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: (focus.phase == FocusPhase.work
                                  ? AppColors.primary(brightness)
                                  : AppColors.success)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      focus.isRunning
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: CupertinoColors.white,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(width: 32),

                // 跳过
                CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: notifier.skip,
                  child: Icon(
                    CupertinoIcons.forward_end,
                    color: AppColors.textSecondary(brightness),
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景弧
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度弧
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (3.14159265 / 180),
      progress * 2 * 3.14159265,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
