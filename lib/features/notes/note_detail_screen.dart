import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'note.dart';
import 'note_player.dart';
import 'note_providers.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByIdProvider(noteId));
    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Note not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(note.displayTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref, note),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetadataCard(note: note),
          const SizedBox(height: 12),
          NotePlayer(
            key: ValueKey(note.audioFilePath),
            audioFilePath: note.audioFilePath,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Summary',
            isProcessing: note.isProcessing,
            errorMessage: note.processingError,
            placeholder:
                'Your AI summary will appear here once the recording is processed.',
            content: note.summary,
            onCopy: note.summary == null
                ? null
                : () => _copy(context, note.summary!),
          ),
          const SizedBox(height: 16),
          _ActionItemsSection(note: note),
          const SizedBox(height: 16),
          _Section(
            title: 'Transcript',
            isProcessing: note.isProcessing,
            errorMessage: note.processingError,
            placeholder:
                'The full transcript will appear here once the recording is processed.',
            content: note.transcript,
            onCopy: note.transcript == null
                ? null
                : () => _copy(context, note.transcript!),
          ),
          const SizedBox(height: 32),
        ],
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
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this recording?'),
        content: const Text(
          'This permanently removes the audio file and any transcript or summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
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

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.graphic_eq, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.displayTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Duration ${note.durationLabel}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.isProcessing,
    required this.errorMessage,
    required this.placeholder,
    required this.content,
    this.onCopy,
  });

  final String title;
  final bool isProcessing;
  final String? errorMessage;
  final String placeholder;
  final String? content;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (isProcessing) {
      body = Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing…',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    } else if (errorMessage != null) {
      body = Text(
        errorMessage!,
        style: TextStyle(color: scheme.error),
      );
    } else if (content == null || content!.isEmpty) {
      body = Text(
        placeholder,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    } else {
      body = Text(content!);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    onPressed: onCopy,
                    tooltip: 'Copy',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}

class _ActionItemsSection extends StatelessWidget {
  const _ActionItemsSection({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = note.actionItems;

    Widget body;
    if (note.isProcessing) {
      body = Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing…',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    } else if (items == null || items.isEmpty) {
      body = Text(
        'Action items pulled from the call will appear here.',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_box_outline_blank,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action items',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}
