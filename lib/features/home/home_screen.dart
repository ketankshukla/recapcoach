import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../auth/auth_providers.dart';
import '../notes/note.dart';
import '../notes/note_providers.dart';
import '../usage/usage.dart';
import '../usage/usage_provider.dart';
import 'widgets/empty_state.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/note_card.dart';
import 'widgets/pulsing_record_fab.dart';
import 'widgets/skeleton_note_card.dart';
import 'widgets/usage_meter.dart';

/// Home screen for RecapCoach.
///
/// Phase 1 layout (per docs/08-roadmap.md):
///
///   ┌───────────────────────────────────────────────┐
///   │ [avatar]  Good morning,           [settings]  │
///   │           Ketan                                │
///   ├───────────────────────────────────────────────┤
///   │  ┌────────── usage meter ──────────────────┐  │
///   │  │ This month • [PRO/FREE]                 │  │
///   │  │ ████████░░░░░░  (gradient, animated)    │  │
///   │  │ 2 of 5 recordings • 4 / 15 min          │  │
///   │  └─────────────────────────────────────────┘  │
///   │                                               │
///   │  Recent recordings                            │
///   │  ┌────────── note card ────────────────────┐  │
///   │  │ [icon] Title              [chevron]     │  │
///   │  │        [Done] 2:14                      │  │
///   │  │        Summary preview...               │  │
///   │  └─────────────────────────────────────────┘  │
///   │                ...                            │
///   │                                               │
///   │                    ┌──────────────┐           │
///   │                    │  🎤 Record   │ ← pulse   │
///   │                    └──────────────┘           │
///   └───────────────────────────────────────────────┘
///
/// On empty state we collapse the list into a single hero illustration
/// so brand-new users have a clear destination for their first recording.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notesAsync = ref.watch(notesStreamProvider);
    final usage = ref.watch(monthlyUsageProvider).value;

    return Scaffold(
      appBar: HomeAppBar(
        displayName: user?.displayName,
        email: user?.email,
        photoUrl: user?.photoURL,
        onSettings: () => context.push(AppRoutes.settings),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Streams auto-refresh; the explicit delay is so the user
          // sees the indicator complete a cycle and feels the gesture
          // "did something" even on offline.
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: notesAsync.when(
          data: (notes) => _HomeBody(notes: notes, usage: usage),
          loading: () => _HomeBody.skeleton(usage: usage),
          error: (e, _) => _HomeError(error: e),
        ),
      ),
      floatingActionButton: PulsingRecordFab(
        onPressed: () => context.push(AppRoutes.record),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.notes, required this.usage})
      : _isSkeleton = false;

  const _HomeBody.skeleton({required this.usage})
      : notes = const [],
        _isSkeleton = true;

  final List<Note> notes;
  final UsageSnapshot? usage;
  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (usage != null) ...[
        UsageMeter(usage: usage!),
        const SizedBox(height: AppSpacing.md),
      ],
      if (_isSkeleton) ...[
        // Placeholder header so layout doesn't shift when real data
        // loads.
        const _SectionHeader(label: 'Recent recordings'),
        const SizedBox(height: AppSpacing.xs),
        for (int i = 0; i < 3; i++) ...[
          const SkeletonNoteCard(),
          const SizedBox(height: AppSpacing.xs),
        ],
      ] else if (notes.isEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        const HomeEmptyState(),
      ] else ...[
        const _SectionHeader(label: 'Recent recordings'),
        const SizedBox(height: AppSpacing.xs),
        for (final n in notes) ...[
          NoteCard(
            note: n,
            onTap: () => context.push('${AppRoutes.notes}/${n.id}'),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    ];

    return ListView(
      // physics ensures the RefreshIndicator can fire even when the
      // content is short enough to not scroll naturally.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        96, // FAB clearance
      ),
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.huge),
        Icon(
          Icons.cloud_off_rounded,
          size: 56,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Could not load notes',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
