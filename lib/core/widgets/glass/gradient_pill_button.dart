import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Premium amber → gold gradient pill button.
///
/// Visual sibling to `PulsingRecordFab` minus the heartbeat halo. Use
/// it for primary CTAs throughout the glass-themed surfaces (Paywall
/// "Start free trial", Sign In "Continue with Google", Record screen
/// "Stop & save", etc.). One shared primitive means the same button
/// rhythm everywhere -- the same gradient stops, the same drop
/// shadow, the same disabled treatment.
///
/// States:
///
///  - **Idle:** amber-600 → amber-400 gradient, white label + icon,
///    1 px white-low-alpha hairline at the top edge.
///  - **Loading:** label is replaced with a 22 dp spinner; tap is
///    ignored. Pass `loading: true` for spinner state.
///  - **Disabled:** desaturates to a slate gradient and ignores taps.
///    Triggered automatically by `onPressed: null`.
class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  /// Tap handler. `null` => disabled.
  final VoidCallback? onPressed;

  /// Button copy. Hidden while [loading] is true.
  final String label;

  /// Optional leading icon. Hidden while [loading].
  final IconData? icon;

  /// Replaces the label with a 22 dp [CircularProgressIndicator] and
  /// disables tap.
  final bool loading;

  /// When true, the pill stretches horizontally to fill its parent.
  /// When false (default), it sizes to its content. Paywall uses
  /// `expanded: true` so the CTA always reads as the focal element.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final gradientColors = disabled
        ? const [AppColors.slate400, AppColors.slate300]
        : const [AppColors.amber600, AppColors.amber400];

    final pill = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: disabled
            ? null
            : [
                // Constant amber drop shadow so the button feels
                // grounded over the glass surface beneath it.
                BoxShadow(
                  color: AppColors.amber700.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: disabled ? 0.10 : 0.20),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisSize:
                  expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: pill) : pill;
  }
}
