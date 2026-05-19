import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../../features/home/widgets/glass_card.dart';

/// Square 44 dp frosted-glass icon button.
///
/// Used as a floating top-corner control on full-bleed screens that
/// drop the Material `AppBar` (Paywall close, Record cancel, etc.).
/// Sits on top of the `MeshGradientBackground` so the icon reads
/// against the blurred surface beneath.
///
/// Pass `tint` to colour the icon for destructive actions (e.g. red
/// for "Discard" on the Record screen). Default is the foreground
/// off-white in dark mode and ink-900 in light mode.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.tint,
    this.size = 44,
    this.iconSize = 22,
    this.radius = 14,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  /// Override the default foreground colour. Useful for destructive
  /// actions: pass `AppColors.error600` and you get a red-on-glass
  /// "Discard" affordance.
  final Color? tint;

  /// Outer dimension. 44 dp matches Apple/Google minimum tap targets.
  final double size;

  /// Icon glyph size.
  final double iconSize;

  /// Corner radius. Defaults to 14 (~ a soft square). Pass `size / 2`
  /// to get a circular button.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = tint ??
        (isDark ? const Color(0xFFF7F4EE) : AppColors.ink900);
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: radius,
      onTap: onPressed,
      child: SizedBox(
        height: size,
        width: size,
        child: Tooltip(
          message: tooltip ?? '',
          child: Icon(icon, color: fg, size: iconSize),
        ),
      ),
    );
  }
}
