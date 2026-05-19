import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../notes/note.dart';
import 'note_status.dart';
import 'note_status_chip.dart';

/// Polished list tile for a [Note] on the home screen.
///
/// Replaces the previous bare `ListTile`. Differences:
///
///  - Status chip in the subtitle row (Transcribing / Done / Failed /
///    Pending), driven by [NoteStatusX].
///  - Tactile shadow + 12 dp radius; aligned to the design-system
///    `cardTheme` so it looks consistent with the usage meter and
///    account card.
///  - Two-line summary preview that gracefully degrades when the
///    transcript has not yet returned.
///  - Icon avatar matches the status (mic / hourglass / check / error).
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  final Note note;
  final VoidCallback onTap;

  IconData _iconFor(NoteStatus s) => switch (s) {
        NoteStatus.processing => Icons.hourglass_top_rounded,
        NoteStatus.done => Icons.graphic_eq_rounded,
        NoteStatus.failed => Icons.error_outline_rounded,
        NoteStatus.pending => Icons.mic_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = note.status;
    final icon = _iconFor(status);
    final hasSummary = note.summary != null && note.summary!.isNotEmpty;
    final body = switch (status) {
      NoteStatus.failed => note.processingError ?? 'Transcription failed.',
      NoteStatus.processing => 'Transcribing your recording…',
      NoteStatus.pending => 'Recorded. Waiting on transcription.',
      NoteStatus.done => hasSummary
          ? note.summary!
          : 'Transcript ready. Tap to view.',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      // Tighten card margin compared to the global cardTheme, which adds
      // 4 dp around every card -- our list already pads each row.
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        NoteStatusChip(status: status),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            note.durationLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
