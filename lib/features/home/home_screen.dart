import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../auth/auth_providers.dart';
import '../notes/note.dart';
import '../notes/note_providers.dart';
import '../usage/usage.dart';
import '../usage/usage_provider.dart';
import 'widgets/empty_state.dart';
import 'widgets/mesh_gradient_background.dart';
import 'widgets/note_card.dart';
import 'widgets/pulsing_record_fab.dart';
import 'widgets/skeleton_note_card.dart';
import 'widgets/weekly_stats_card.dart';

/// Home screen — premium glass dashboard variant.
///
/// Layout:
///
///   ┌────────────────────────────────────────────────┐
///   │ ░░░░░░░  animated mesh gradient ░░░░░░░░░     │ ← scaffold body
///   │                                                │
///   │  ╭──────────────── glass ────────────────╮    │
///   │  │ [avatar]                       [⚙ ]  │    │ ← WeeklyStatsCard
///   │  │                                       │    │   (hero)
///   │  │ Good evening,                         │    │
///   │  │ Ketan                                 │    │
///   │  │                                       │    │
///   │  │  3        47       ◯ 40%              │    │
///   │  │ recordings min      used              │    │
///   │  ╰───────────────────────────────────────╯    │
///   │                                                │
///   │  RECENT RECORDINGS                            │
///   │  ╭──────────── glass ──────────────────╮      │
///   │  │ ▌[icn] Title                  [▸]  │      │ ← NoteCard (glass)
///   │  │       [chip] 2:14                  │      │
///   │  │       Summary preview...            │      │
///   │  ╰─────────────────────────────────────╯      │
///   │                ...                            │
///   │                                                │
///   │                       ┌────────────────┐      │
///   │                       │ 🎤 Record call │ pulse│ ← gradient FAB
///   │                       └────────────────┘      │
///   └────────────────────────────────────────────────┘
///
/// The Scaffold uses no AppBar -- the hero glass card occupies the
/// top region instead, giving us more visual real estate. The mesh
/// gradient is the actual background, so Scaffold.backgroundColor is
/// transparent.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notesAsync = ref.watch(notesStreamProvider);
    final usage = ref.watch(monthlyUsageProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Body extends behind the (absent) status bar so the mesh
      // covers the full screen.
      extendBodyBehindAppBar: true,
      body: MeshGradientBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 350));
            },
            child: notesAsync.when(
              data: (notes) => _HomeBody(
                notes: notes,
                usage: usage,
                displayName: user?.displayName,
                email: user?.email,
                photoUrl: user?.photoURL,
                onSettings: () => context.push(AppRoutes.settings),
              ),
              loading: () => _HomeBody.skeleton(
                usage: usage,
                displayName: user?.displayName,
                email: user?.email,
                photoUrl: user?.photoURL,
                onSettings: () => context.push(AppRoutes.settings),
              ),
              error: (e, _) => _HomeError(error: e),
            ),
          ),
        ),
      ),
      floatingActionButton: PulsingRecordFab(
        onPressed: () => context.push(AppRoutes.record),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.notes,
    required this.usage,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onSettings,
  }) : _isSkeleton = false;

  const _HomeBody.skeleton({
    required this.usage,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onSettings,
  })  : notes = const [],
        _isSkeleton = true;

  /// All notes in the Hive box. Used to render the recent-recordings
  /// list + the empty state. *Not* used for hero stats anymore --
  /// those come from `usage` so they match the server-enforced caps.
  final List<Note> notes;
  final UsageSnapshot? usage;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final VoidCallback onSettings;
  final bool _isSkeleton;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      WeeklyStatsCard(
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        onSettings: onSettings,
        usage: usage,
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_isSkeleton) ...[
        const _SectionHeader(label: 'RECENT RECORDINGS'),
        const SizedBox(height: AppSpacing.xs),
        for (int i = 0; i < 3; i++) ...[
          const SkeletonNoteCard(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ] else if (notes.isEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        const HomeEmptyState(),
      ] else ...[
        const _SectionHeader(label: 'RECENT RECORDINGS'),
        const SizedBox(height: AppSpacing.xs),
        for (final n in notes) ...[
          NoteCard(
            note: n,
            onTap: () => context.push('${AppRoutes.notes}/${n.id}'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120, // FAB clearance
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
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.slate500.withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 4, bottom: 2),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          fontSize: 11,
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
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted = isDark
        ? const Color(0xFFD8D4CB)
        : AppColors.slate500;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.huge),
        Icon(
          Icons.cloud_off_rounded,
          size: 56,
          color: fgMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Could not load notes',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: fg),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: fgMuted),
        ),
      ],
    );
  }
}
