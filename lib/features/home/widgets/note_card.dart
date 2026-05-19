import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../notes/note.dart';
import 'glass_card.dart';
import 'note_status.dart';
import 'note_status_chip.dart';

/// Premium-glass list tile for a [Note] on the home screen.
///
/// Built on [GlassCard] so every note in the list reads as "frosted
/// glass over the mesh-gradient background." A 4 px vertical accent
/// bar on the leading edge encodes the note's status color (sage =
/// done, amber = transcribing, red = failed, slate = pending) so
/// users can scan a long list and read status at a glance even
/// without looking at the chip.
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

  Color _accentFor(BuildContext context, NoteStatus s) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return switch (s) {
      NoteStatus.processing => semantic.usageMeterMid,
      NoteStatus.done => semantic.usageMeterLow,
      NoteStatus.failed => semantic.usageMeterHigh,
      NoteStatus.pending => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted = isDark
        ? const Color(0xFFD8D4CB)
        : AppColors.slate500;

    final status = note.status;
    final accent = _accentFor(context, status);
    final icon = _iconFor(status);
    final hasSummary = note.summary != null && note.summary!.isNotEmpty;
    final body = switch (status) {
      NoteStatus.failed => note.processingError ?? 'Transcription failed.',
      NoteStatus.processing => 'Transcribing your recording…',
      NoteStatus.pending => 'Recorded. Waiting on transcription.',
      NoteStatus.done =>
          hasSummary ? note.summary! : 'Transcript ready. Tap to view.',
    };

    return GlassCard(
      radius: 18,
      sigma: 14,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status-color accent strip on the leading edge.
            Container(width: 4, color: accent),
            Expanded(
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
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: accent,
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
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: fgMuted,
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
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: fgMuted,
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
                              color: fgMuted,
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
          ],
        ),
      ),
    );
  }
}
