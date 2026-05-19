import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass/glass_alert_dialog.dart';
import '../../core/widgets/glass/glass_icon_button.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/mesh_gradient_background.dart';
import 'note.dart';
import 'note_player.dart';
import 'note_providers.dart';

/// Glass-themed note detail screen.
///
/// Sits over `MeshGradientBackground` with floating glass back +
/// delete controls in the top corners. Displays the note's title +
/// metadata, the (already glass-themed) `NotePlayer`, then three
/// stacked `GlassCard` sections:
///
///  1. **Summary** -- AI summary, with a copy-to-clipboard action.
///  2. **Action items** -- bulleted list of follow-ups extracted by
///     the transcription service.
///  3. **Transcript** -- full transcript text, with a copy action.
///
/// Each section gracefully handles four states: `isProcessing`,
/// `errorMessage` set, content empty / null, and content present.
/// The destructive Delete confirmation uses `GlassAlertDialog` with
/// `primaryDestructive: true` (red outlined CTA).
class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByIdProvider(noteId));
    if (note == null) {
      // The note vanished out from under us (deleted from another
      // device, cache pruned, etc.). Render a minimal glass screen
      // so we don't fall back to a flat M3 surface mid-flow.
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: MeshGradientBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('Note not found.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted =
        isDark ? const Color(0xFFD8D4CB) : AppColors.slate500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ---- Floating top controls ----
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: GlassIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  tint: AppColors.error600,
                  onPressed: () => _confirmDelete(context, ref, note),
                ),
              ),

              // ---- Scrollable content ----
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  72,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  _Header(note: note, fg: fg, fgMuted: fgMuted),
                  const SizedBox(height: AppSpacing.lg),

                  NotePlayer(
                    key: ValueKey(note.audioFilePath),
                    audioFilePath: note.audioFilePath,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _Section(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Summary',
                    fg: fg,
                    fgMuted: fgMuted,
                    isProcessing: note.isProcessing,
                    errorMessage: note.processingError,
                    placeholder:
                        'Your AI summary will appear here once the recording '
                        'is processed.',
                    content: note.summary,
                    onCopy: note.summary == null
                        ? null
                        : () => _copy(context, note.summary!),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _ActionItemsSection(
                    note: note,
                    fg: fg,
                    fgMuted: fgMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _Section(
                    icon: Icons.subject_rounded,
                    title: 'Transcript',
                    fg: fg,
                    fgMuted: fgMuted,
                    isProcessing: note.isProcessing,
                    errorMessage: note.processingError,
                    placeholder:
                        'The full transcript will appear here once the '
                        'recording is processed.',
                    content: note.transcript,
                    onCopy: note.transcript == null
                        ? null
                        : () => _copy(context, note.transcript!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const GlassAlertDialog(
        title: 'Delete this recording?',
        message:
            'This permanently removes the audio file and any transcript '
            'or summary.',
        primaryLabel: 'Delete',
        primaryReturn: true,
        primaryDestructive: true,
        secondaryLabel: 'Cancel',
        secondaryReturn: false,
      ),
    );
    if (ok != true) return;
    await ref.read(noteRepositoryProvider).delete(note.id);
    if (!context.mounted) return;
    context.pop();
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

// =============================================================================
// Header -- title + metadata row
// =============================================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.note,
    required this.fg,
    required this.fgMuted,
  });

  final Note note;
  final Color fg;
  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('MMM d, y · h:mm a').format(note.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.displayTitle,
          style: theme.textTheme.displaySmall?.copyWith(
            color: fg,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: fgMuted,
            ),
            const SizedBox(width: 4),
            Text(
              note.durationLabel,
              style: TextStyle(
                color: fgMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '  ·  ',
              style: TextStyle(color: fgMuted, fontSize: 13),
            ),
            Flexible(
              child: Text(
                dateLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fgMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Generic glass section -- title row + state-aware body
// =============================================================================

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.fg,
    required this.fgMuted,
    required this.isProcessing,
    required this.errorMessage,
    required this.placeholder,
    required this.content,
    this.onCopy,
  });

  final IconData icon;
  final String title;
  final Color fg;
  final Color fgMuted;
  final bool isProcessing;
  final String? errorMessage;
  final String placeholder;
  final String? content;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isProcessing) {
      body = _ProcessingRow(fgMuted: fgMuted);
    } else if (errorMessage != null) {
      body = Text(
        errorMessage!,
        style: const TextStyle(
          color: AppColors.error600,
          height: 1.4,
        ),
      );
    } else if (content == null || content!.isEmpty) {
      body = Text(
        placeholder,
        style: TextStyle(color: fgMuted, height: 1.4),
      );
    } else {
      body = SelectableText(
        content!,
        style: TextStyle(color: fg, height: 1.5, fontSize: 14.5),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon,
            title: title,
            fg: fg,
            onCopy: onCopy,
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.fg,
    required this.onCopy,
  });

  final IconData icon;
  final String title;
  final Color fg;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Small amber-tinted icon avatar so each section has a clear
        // glanceable identity.
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: AppColors.amber400.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.amber400.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.amber600),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: fg.withValues(alpha: 0.75),
            ),
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy',
            onPressed: onCopy,
          ),
      ],
    );
  }
}

class _ProcessingRow extends StatelessWidget {
  const _ProcessingRow({required this.fgMuted});

  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.amber400,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Processing…',
          style: TextStyle(color: fgMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// =============================================================================
// Action items section -- bulleted list with check-box bullets
// =============================================================================

class _ActionItemsSection extends StatelessWidget {
  const _ActionItemsSection({
    required this.note,
    required this.fg,
    required this.fgMuted,
  });

  final Note note;
  final Color fg;
  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    final items = note.actionItems;

    Widget body;
    if (note.isProcessing) {
      body = _ProcessingRow(fgMuted: fgMuted);
    } else if (items == null || items.isEmpty) {
      body = Text(
        'Action items pulled from the call will appear here.',
        style: TextStyle(color: fgMuted, height: 1.4),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.amber600,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: fg,
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.checklist_rounded,
            title: 'Action items',
            fg: fg,
            onCopy: null,
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
  }
}
