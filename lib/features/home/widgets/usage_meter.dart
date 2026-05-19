import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../usage/usage.dart';

/// Refined monthly-usage meter for the home screen.
///
/// Improvements over the inline meter we shipped in Phase 0:
///
///  - Pulls colors from `AppSemanticColors.usageMeterColorFor()` so the
///    progression sage → amber → red lives in one place.
///  - Animates the progress bar (`TweenAnimationBuilder`) from 0 to its
///    current value on first build and on every change. Subtle but
///    makes the screen feel alive.
///  - Gradient fill so the bar reads as "filling up" rather than a flat
///    color block.
///  - Pro users see a celebratory "Pro plan -- you're flying" line
///    instead of a "X of Y" cap label.
///  - Free users at >= 80% see a contextual "Upgrade" CTA inline.
class UsageMeter extends StatelessWidget {
  const UsageMeter({super.key, required this.usage});

  final UsageSnapshot usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;

    final progress = usage.worstProgress.clamp(0.0, 1.0);
    final atCap = usage.isAtCap;
    final near = !atCap && progress >= 0.8;
    final fillColor = semantic.usageMeterColorFor(progress);

    final usedMin = (usage.usedSeconds / 60).toStringAsFixed(
      usage.usedSeconds < 60 ? 1 : 0,
    );
    final limitMin = (usage.limitSeconds / 60).toStringAsFixed(0);
    final isPro = usage.plan == 'pro';

    final headlineText = atCap
        ? 'Monthly limit reached'
        : near
            ? 'Almost out this month'
            : isPro
                ? 'Pro plan'
                : 'This month';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm + 2,
          AppSpacing.md,
          AppSpacing.sm + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  atCap ? Icons.lock_outline_rounded : Icons.equalizer_rounded,
                  size: 18,
                  color: fillColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    headlineText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: atCap ? scheme.error : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPro ? semantic.proBadge : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: Text(
                    isPro ? 'PRO' : 'FREE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPro ? semantic.proBadgeOn : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnimatedProgressBar(
              progress: progress,
              fillColor: fillColor,
              trackColor: semantic.usageMeterTrack,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${usage.usedRecordings} of ${usage.limitRecordings} recordings  •  '
              '$usedMin / $limitMin min',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
            if ((atCap || near) && !isPro) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      atCap
                          ? 'Upgrade to Pro for 8 hours and 100 recordings every month.'
                          : 'Going Pro lifts you to 8 hours and 100 recordings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.paywall),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated, gradient-filled progress bar used by [UsageMeter].
///
/// Animates from 0 → [progress] on first build and from previous value
/// → new value on subsequent rebuilds. The fill is a horizontal gradient
/// that fades from a subtler tint of [fillColor] to its full saturation,
/// giving the bar a "filling up" sense rather than a flat color block.
class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  final double progress;
  final Color fillColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xs),
      child: SizedBox(
        height: 10,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              children: [
                Container(color: trackColor),
                FractionallySizedBox(
                  widthFactor: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          fillColor.withValues(alpha: 0.65),
                          fillColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
