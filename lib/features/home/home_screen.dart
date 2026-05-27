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
import 'widgets/glass_card.dart';
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
    final usage = ref.watch(liveUsageProvider);

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
      floatingActionButton: (usage?.isAtCap ?? false) && !(usage?.isDeveloper ?? false)
          ? null
          : PulsingRecordFab(
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
      ] else if (notes.isEmpty && (usage?.isAtCap ?? false)) ...[
        const SizedBox(height: AppSpacing.md),
        _CapExhaustedState(
          onUpgrade: () => context.push(AppRoutes.paywall),
        ),
      ] else if (notes.isEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        const HomeEmptyState(),
      ] else ...[
        // Show upgrade card above recordings when cap is reached.
        if ((usage?.isAtCap ?? false) && !(usage?.isDeveloper ?? false)) ...[
          _CapExhaustedState(
            onUpgrade: () => context.push(AppRoutes.paywall),
          ),
        ],
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

class _CapExhaustedState extends StatelessWidget {
  const _CapExhaustedState({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted = isDark
        ? const Color(0xFFD8D4CB)
        : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.red.shade900, Colors.red.shade700]
                    : [Colors.red.shade100, Colors.red.shade50],
              ),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.block_rounded,
              size: 48,
              color: isDark ? Colors.red.shade200 : Colors.red.shade600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                Text(
                  'Monthly cap reached',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You\u2019ve used all your free recordings this month. '
                  'Deleted recordings still count toward your monthly cap.\n\n'
                  'Upgrade to Pro to unlock 100 recordings and 8 hours '
                  'of transcription every month.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fgMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
