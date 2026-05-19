import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass card surface.
///
/// Wraps any widget in a `BackdropFilter` blur + low-alpha fill + 1px
/// hairline border, producing the "frosted glass over a gradient
/// background" look that's the centerpiece of the premium-glass home
/// screen redesign.
///
/// The widget is theme-aware: in dark mode it uses near-white at very
/// low alpha (white surface tint over the dark mesh = "frosted"), in
/// light mode it uses near-white at higher alpha so cards remain
/// legible over the lighter mesh.
///
/// Performance: every `GlassCard` creates its own `BackdropFilter`
/// which is a `RepaintBoundary` + a Vulkan/Impeller blur pass. We cap
/// the sigma at 18 and avoid stacking glass cards on top of each
/// other (the home screen never nests cards).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.sigma = 18,
    this.tint,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double sigma;

  /// Override the default fill. Pass `Colors.transparent` to skip the
  /// fill (useful when the card is purely structural).
  final Color? tint;

  /// Override the default border tint.
  final Color? borderColor;

  /// Optional gradient overlay painted *above* the blur and *below*
  /// the child. Used by the hero stats card to add a subtle warm tint
  /// in the corner.
  final Gradient? gradient;

  /// Optional tap handler; when set, the card gets InkWell ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = tint ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.7));

    final body = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        border: Border.all(color: border, width: 1),
      ),
      padding: padding,
      child: child,
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: onTap == null
            ? body
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: body,
                ),
              ),
      ),
    );

    // Soft outer drop shadow gives the card a real sense of "floating"
    // above the mesh. The shadow tint is mode-aware: amber-tinted in
    // dark mode for warmth, navy-tinted in light mode.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF1B2A4E).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: clipped,
    );
  }
}
