import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../../features/home/widgets/glass_card.dart';

/// Low-key frosted-glass pill button with a text label.
///
/// Visual sibling to [GlassIconButton] -- same glass surface, but
/// shaped as a horizontal pill and carrying a text label instead of
/// an icon. Used for tertiary actions on full-bleed glass screens
/// where a [GradientPillButton] would be too loud (e.g. the "Restore"
/// link in the Paywall top-right corner).
///
/// Default rendering picks the off-white / ink foreground appropriate
/// to the current theme; pass [tint] for an emphasis colour (e.g.
/// amber for "Upgrade").
class GlassPillButton extends StatelessWidget {
  const GlassPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tint,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = tint ??
        (isDark ? const Color(0xFFF7F4EE) : AppColors.ink900);
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      radius: 22,
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
