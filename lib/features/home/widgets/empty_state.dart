import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// First-run empty state for the home screen.
///
/// Layout:
///
///   ┌─────────────────────────────┐
///   │       [ illustration ]      │   ← stylised mic glyph in
///   │                             │     amber-on-navy circle
///   │  Capture your first call    │
///   │                             │
///   │  Tap "Record call" below    │
///   │  to capture a meeting and   │
///   │  get a transcript +         │
///   │  summary in seconds.        │
///   └─────────────────────────────┘
///
/// We deliberately avoid a CTA button here -- the floating "Record call"
/// FAB is the primary action and re-stating it inside the empty state
/// would create button-soup.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration: amber mic icon on a deep-navy disc, with a
          // soft outer halo to give it a sense of presence without
          // needing a real raster asset (those come in a polish pass).
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navy800,
              boxShadow: [
                BoxShadow(
                  color: semantic.recordingPulse.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              size: 44,
              color: AppColors.amber400,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Capture your first call',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Tap "Record call" below to capture a consulting call. '
              "You'll get a transcript, summary, and action items in seconds.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Subtle hint chip, anchored to the FAB visually via the
          // arrow-down glyph so a brand-new user knows where to tap.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: semantic.shimmer,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Start recording',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
