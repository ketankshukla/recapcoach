import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'note_status.dart';

/// Compact pill-shaped chip that announces a [NoteStatus] using the
/// design-system's semantic colors.
///
/// Variants (colors picked from [AppSemanticColors] so light + dark
/// modes both look correct):
///
///   - `processing` → amber background, hourglass icon, "Transcribing"
///   - `done`       → sage background, check icon, "Done"
///   - `failed`     → red background, error icon, "Failed"
///   - `pending`    → muted slate background, mic icon, "Pending"
///
/// Designed to be small enough to live inside a note-card subtitle row
/// next to the duration label.
class NoteStatusChip extends StatelessWidget {
  const NoteStatusChip({super.key, required this.status});

  final NoteStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;

    final (label, icon, fg) = switch (status) {
      NoteStatus.processing => (
          'Transcribing',
          Icons.hourglass_top_rounded,
          semantic.usageMeterMid,
        ),
      NoteStatus.done => (
          'Done',
          Icons.check_circle_rounded,
          semantic.usageMeterLow,
        ),
      NoteStatus.failed => (
          'Failed',
          Icons.error_rounded,
          semantic.usageMeterHigh,
        ),
      NoteStatus.pending => (
          'Pending',
          Icons.mic_none_rounded,
          scheme.onSurfaceVariant,
        ),
    };

    final bg = fg.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
