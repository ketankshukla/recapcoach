import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../auth/auth_providers.dart';
import '../notes/note.dart';
import '../notes/note_providers.dart';
import '../paywall/entitlement_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPro = ref.watch(entitlementProvider).value ?? false;
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RecapCoach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Stream auto-refreshes; placeholder for future "sync" action.
          await Future<void>.delayed(const Duration(milliseconds: 250));
        },
        child: notesAsync.when(
          data: (notes) => _NotesList(
            notes: notes,
            user: user?.email,
            isPro: isPro,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load notes: $e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.record),
        icon: const Icon(Icons.mic),
        label: const Text('Record call'),
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.notes,
    required this.user,
    required this.isPro,
  });

  final List<Note> notes;
  final String? user;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountCard(user: user, isPro: isPro),
          const SizedBox(height: 32),
          const _EmptyState(),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _AccountCard(user: user, isPro: isPro),
        const SizedBox(height: 16),
        Text(
          'Recent recordings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NoteTile(note: n),
          ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.isPro});
  final String? user;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                isPro ? Icons.workspace_premium : Icons.person,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user ?? 'Welcome',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isPro ? 'Pro' : 'Free plan',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!isPro)
              FilledButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: const Text('Upgrade'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.mic_none, size: 64, color: scheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          'No recordings yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Tap "Record call" below to capture your next consulting call. '
            'You\'ll get a transcript, summary, and action items in seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSummary = note.summary != null && note.summary!.isNotEmpty;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.6),
          child: Icon(
            note.isProcessing ? Icons.hourglass_top : Icons.graphic_eq,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          note.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          note.isProcessing
              ? 'Processing… (${note.durationLabel})'
              : hasSummary
                  ? note.summary!
                  : 'Duration ${note.durationLabel} \u2014 not yet processed',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('${AppRoutes.notes}/${note.id}'),
      ),
    );
  }
}
