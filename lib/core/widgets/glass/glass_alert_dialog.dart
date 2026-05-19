import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../../features/home/widgets/glass_card.dart';
import 'gradient_pill_button.dart';

/// Glass-styled replacement for the Material `AlertDialog`.
///
/// Sits over a darkened barrier (`barrierColor: Colors.black54`) and
/// renders a centred `GlassCard` with title + message + 1-2 actions.
/// Used for permission prompts, quota / paywall pre-flight nudges,
/// and destructive-action confirmations across glass-themed screens.
///
/// API parity with `showDialog` + `AlertDialog`:
///
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   barrierColor: Colors.black.withValues(alpha: 0.6),
///   builder: (_) => const GlassAlertDialog(
///     title: 'Delete account?',
///     message: 'This permanently deletes your account and all data.',
///     primaryLabel: 'Delete',
///     primaryReturn: true,
///     primaryDestructive: true,
///     secondaryLabel: 'Cancel',
///     secondaryReturn: false,
///   ),
/// );
/// ```
///
/// Returns the value associated with whichever button was tapped, or
/// `null` if the dialog was dismissed by tap-outside.
///
/// Pass `primaryDestructive: true` to render the primary CTA as a
/// red-tinted `OutlinedButton` instead of the loud amber
/// `GradientPillButton`. Destructive actions should never sit in the
/// hottest visual slot of the screen.
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
    this.primaryReturn,
    this.secondaryReturn,
    this.primaryDestructive = false,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;
  final Object? primaryReturn;
  final Object? secondaryReturn;
  final bool primaryDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    Widget primaryButton() {
      if (primaryDestructive) {
        return _DestructiveButton(
          label: primaryLabel,
          onPressed: () =>
              Navigator.of(context).pop(primaryReturn ?? true),
        );
      }
      return GradientPillButton(
        onPressed: () => Navigator.of(context).pop(primaryReturn ?? true),
        label: primaryLabel,
        expanded: true,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        radius: 22,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fgMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (secondaryLabel != null) ...[
              primaryButton(),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(secondaryReturn ?? false),
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(
                    color: fgMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else
              primaryButton(),
          ],
        ),
      ),
    );
  }
}

/// Red-tinted destructive primary button. Used for "Delete account"
/// and similar non-reversible actions where the loud amber CTA would
/// invite a misclick.
class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.error600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.error600.withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.error600,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
