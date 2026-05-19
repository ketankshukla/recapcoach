import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular arc-ring progress indicator. Replaces the horizontal
/// `LinearProgressIndicator` we used for the usage meter -- a ring is
/// far more graphic and lets us put the usage label inside it.
///
/// Visuals:
///
///  - Track ring: muted (40% alpha) version of `trackColor`.
///  - Progress arc: a sweep gradient from a soft tint of `color`
///    (50% alpha) to the full color, drawn from 12 o'clock clockwise.
///  - Both ring + arc use rounded stroke caps for a tactile feel.
///  - Animates from 0 to `progress` on first build (and between
///    values on subsequent rebuilds) over 800ms with `Curves.easeOutCubic`.
///
/// `center` lets callers slot in the live "X / Y" label inside the
/// ring -- the home stats card uses it to show "40%" with a small
/// "used" subtitle below.
class ArcUsageRing extends StatelessWidget {
  const ArcUsageRing({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.size = 96,
    this.strokeWidth = 10,
    this.center,
    this.duration = const Duration(milliseconds: 800),
  });

  final double progress; // 0..1
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size.square(size),
                painter: _ArcPainter(
                  progress: value,
                  color: color,
                  trackColor: trackColor,
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // SweepGradient from soft tint -> full color, rotated so 12 o'clock
    // is the zero angle. The gradient spans the *whole* circle so the
    // arc reveals more of it as `progress` grows.
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.5), color],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2, // start at 12 o'clock
      2 * math.pi * progress, // sweep clockwise
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
