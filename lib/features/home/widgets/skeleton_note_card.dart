import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import 'glass_card.dart';

/// Skeleton placeholder shown while the Hive notes box opens.
///
/// Shape mirrors the new glass [NoteCard] so the layout doesn't shift
/// when real data arrives:
///
///  - Same 18 px radius, same 4 px leading accent strip.
///  - Same icon-plus-text-block geometry inside the glass surface.
///
/// Block tints adapt to light vs dark so the skeleton fits the mesh
/// background's vibe in either mode.
class SkeletonNoteCard extends StatelessWidget {
  const SkeletonNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final block = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final accent = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return GlassCard(
      radius: 18,
      sigma: 14,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Block(
                      width: 44,
                      height: 44,
                      color: block,
                      radius: 12,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Block(width: 180, height: 14, color: block),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Block(
                                width: 64,
                                height: 16,
                                color: block,
                                radius: AppRadii.xs,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _Block(width: 48, height: 10, color: block),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _Block(
                            width: double.infinity,
                            height: 10,
                            color: block,
                          ),
                          const SizedBox(height: 6),
                          _Block(width: 220, height: 10, color: block),
                        ],
                      ),
                    ),
                  ],
                ),
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
