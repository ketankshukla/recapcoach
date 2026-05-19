import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import 'glass_card.dart';

/// First-run empty state for the redesigned home screen.
///
/// Designed to play nicely with the mesh-gradient background: the
/// big amber-on-navy mic disc + soft halo provides the visual anchor;
/// the supporting glass panel underneath holds the headline + helper
/// copy + "Start recording" hint chip pointing at the FAB.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted = isDark
        ? const Color(0xFFD8D4CB)
        : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero mic disc: large amber-on-navy circle with a layered
          // halo. The outer glow uses a pure amber color so it pops
          // against the mesh in both light + dark modes.
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.navy900,
                  AppColors.navy700,
                ],
              ),
              border: Border.all(
                color: AppColors.amber400.withValues(alpha: 0.30),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber400.withValues(alpha: 0.30),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.amber600.withValues(alpha: 0.18),
                  blurRadius: 80,
                  spreadRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              size: 60,
              color: AppColors.amber400,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                Text(
                  'Capture your first call',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap "Record call" below to capture a consulting call. '
                  "You'll get a transcript, summary, and action items in seconds.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fgMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber400.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: AppColors.amber400.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppColors.amber400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Start recording',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.amber400,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
