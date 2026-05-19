import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Skeleton placeholder shown while the Hive notes box is loading.
///
/// Shape mirrors [NoteCard] so the layout doesn't shift when the real
/// data arrives. The shimmer color comes from
/// `AppSemanticColors.shimmer` so light + dark modes both look right.
///
/// We render a *static* skeleton (no shimmer animation) for now -- it's
/// rare for the Hive box to take more than a few hundred milliseconds
/// to open, so an animated shimmer would barely be visible. If we ever
/// gate this on real network I/O we can revisit.
class SkeletonNoteCard extends StatelessWidget {
  const SkeletonNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final base = semantic.shimmer;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Block(width: 44, height: 44, color: base, radius: AppRadii.sm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Block(width: 180, height: 14, color: base),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Block(width: 64, height: 16, color: base, radius: AppRadii.xs),
                      const SizedBox(width: AppSpacing.xs),
                      _Block(width: 48, height: 10, color: base),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Block(width: double.infinity, height: 10, color: base),
                  const SizedBox(height: 6),
                  _Block(width: 220, height: 10, color: base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 4,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
