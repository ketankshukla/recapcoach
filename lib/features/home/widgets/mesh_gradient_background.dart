import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Animated mesh-gradient background used by the redesigned home
/// screen.
///
/// Renders a base color plus 3-4 large radial-gradient "blobs" whose
/// centers drift slowly along independent sin/cos paths. Period is
/// deliberately long (28 seconds) so the motion reads as ambient
/// atmosphere rather than as an animated banner.
///
/// Light vs dark mode use entirely different palettes:
///
///  - **Dark:** deep ink base + navy-700 cool blob + amber-bloom warm
///    blob + sage atmospheric tint. Creates the "premium night-mode
///    fitness app" look that's the marquee experience for direction A.
///  - **Light:** warm cream base + sage cool blob + amber bloom +
///    navy haze. Refined and editorial; works as a daytime alternative.
///
/// Performance: three radial gradient paints per frame at ~60 fps on
/// Impeller is comfortable. We do NOT call `markNeedsPaint` -- the
/// `AnimationController.repeat()` ticks rebuild the `AnimatedBuilder`
/// which in turn rebuilds the `CustomPaint` each frame.
class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;

  /// Setting `false` freezes the gradient at t=0 (used by widget tests
  /// + low-power devices, and by the empty-state hero where motion
  /// would compete with the FAB pulse).
  final bool animate;

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant MeshGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshPainter(t: _ctrl.value, isDark: isDark),
          // `child` is the actual app content layered on top of the
          // mesh; we pass it through so it isn't rebuilt every frame.
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.t, required this.isDark});

  /// Animation phase in [0, 1].
  final double t;
  final bool isDark;

  // Palette for the two modes. Pulled from `AppColors` so any future
  // palette update flows through automatically.
  static const _darkBase = Color(0xFF080F1F); // ink900-ish, slightly cooler
  static const _lightBase = Color(0xFFFAF9F4); // warm cream (matches scaffold)

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = isDark ? _darkBase : _lightBase;
    canvas.drawRect(Offset.zero & size, base);

    const twoPi = 2 * math.pi;
    final w = size.width;
    final h = size.height;

    // Three blobs. Each has its own oscillation phase + speed multiplier
    // so the composition never repeats exactly.
    final blobs = <_Blob>[
      _Blob(
        // Cool blue/navy blob: top-left, drifts diagonally.
        center: Offset(
          w * 0.22 + w * 0.06 * math.sin(t * twoPi),
          h * 0.18 + h * 0.04 * math.cos(t * twoPi),
        ),
        radius: w * 0.85,
        color: isDark
            ? AppColors.navy700.withValues(alpha: 0.55)
            : AppColors.navy100.withValues(alpha: 0.55),
      ),
      _Blob(
        // Warm amber bloom: lower-right, drifts faster.
        center: Offset(
          w * 0.85 + w * 0.08 * math.cos(t * twoPi * 1.3),
          h * 0.55 + h * 0.05 * math.sin(t * twoPi * 1.3),
        ),
        radius: w * 0.7,
        color: isDark
            ? AppColors.amber600.withValues(alpha: 0.22)
            : AppColors.amber100.withValues(alpha: 0.55),
      ),
      _Blob(
        // Atmospheric sage tint: bottom-left, slowest oscillation.
        center: Offset(
          w * 0.18 + w * 0.05 * math.sin(t * twoPi * 0.7),
          h * 0.88 + h * 0.04 * math.cos(t * twoPi * 0.9),
        ),
        radius: w * 0.65,
        color: isDark
            ? AppColors.sage700.withValues(alpha: 0.30)
            : AppColors.sage300.withValues(alpha: 0.32),
      ),
    ];

    for (final b in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color, b.color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: b.center, radius: b.radius),
        );
      canvas.drawCircle(b.center, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}

class _Blob {
  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Offset center;
  final double radius;
  final Color color;
}
