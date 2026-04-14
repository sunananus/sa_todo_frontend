// lib/core/widgets/animated_check_box.dart
// 带动效的任务完成复选框

import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 带动效的圆形复选框
class AnimatedCheckBox extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color? activeColor;

  const AnimatedCheckBox({
    super.key,
    required this.isChecked,
    required this.onChanged,
    this.size = 24,
    this.activeColor,
  });

  @override
  State<AnimatedCheckBox> createState() => _AnimatedCheckBoxState();
}

class _AnimatedCheckBoxState extends State<AnimatedCheckBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    if (widget.isChecked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final activeColor = widget.activeColor ?? AppColors.primary(brightness);

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.isChecked),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isChecked
                    ? activeColor
                    : CupertinoColors.transparent,
                border: Border.all(
                  color: widget.isChecked
                      ? activeColor
                      : AppColors.textSecondary(brightness),
                  width: 2,
                ),
              ),
              child: widget.isChecked
                  ? CustomPaint(
                      painter: _CheckPainter(
                        progress: _checkAnimation.value,
                        color: CupertinoColors.white,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Check mark path
    final startX = size.width * 0.25;
    final startY = size.height * 0.50;
    final midX = size.width * 0.42;
    final midY = size.height * 0.68;
    final endX = size.width * 0.75;
    final endY = size.height * 0.32;

    path.moveTo(startX, startY);

    if (progress <= 0.5) {
      final t = progress * 2;
      path.lineTo(
        startX + (midX - startX) * t,
        startY + (midY - startY) * t,
      );
    } else {
      path.lineTo(midX, midY);
      final t = (progress - 0.5) * 2;
      path.lineTo(
        midX + (endX - midX) * t,
        midY + (endY - midY) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
