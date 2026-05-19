import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../notes/note.dart';
import '../../usage/usage.dart';
import 'arc_usage_ring.dart';
import 'glass_card.dart';
import 'time_based_greeting.dart';
import 'user_avatar.dart';

/// Hero card on the home screen.
///
/// Replaces the old `HomeAppBar` + `_AccountCard` + `UsageMeter`
/// combo with a single statement element that:
///
///  1. Hosts the avatar + settings icon (top row).
///  2. Renders the time-based greeting in display-size typography
///     (32-36 pt bold).
///  3. Shows three at-a-glance stats: this-week recordings count,
///     this-week minutes captured, and a circular usage arc with the
///     percent used in the center.
///
/// Designed to be the visual focal point of the screen. Built on top
/// of [GlassCard] so it sits over the mesh-gradient background with a
/// frosted-glass feel.
///
/// `now` is overridable for tests so we can deterministically
/// exercise greeting + weekly-window math without time-of-day flakiness.
class WeeklyStatsCard extends StatelessWidget {
  const WeeklyStatsCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onSettings,
    required this.notes,
    required this.usage,
    this.now,
  });

  final String? displayName;
  final String? email;
  final String? photoUrl;
  final VoidCallback onSettings;
  final List<Note> notes;
  final UsageSnapshot? usage;
  final DateTime? now;

  /// Returns the first whitespace-separated token of `name`, or null
  /// when blank. Mirrors the old AppBar logic.
  static String? firstName(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// Sums durations of notes created in the last 7 days. Exposed
  /// statically so tests can verify the windowing logic without a
  /// widget pump.
  static ({int count, int minutes}) weeklyStats(
    List<Note> notes,
    DateTime now,
  ) {
    final cutoff = now.subtract(const Duration(days: 7));
    var count = 0;
    var ms = 0;
    for (final n in notes) {
      if (n.createdAt.isAfter(cutoff)) {
        count++;
        ms += n.durationMs;
      }
    }
    return (count: count, minutes: (ms / 60000).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    final t = now ?? DateTime.now();
    final greeting = TimeBasedGreeting.forTime(t);
    final fname = firstName(displayName);
    final hasName = fname != null;

    final stats = weeklyStats(notes, t);
    final progress = (usage?.worstProgress ?? 0).clamp(0.0, 1.0);
    final isPro = usage?.plan == 'pro';
    final atCap = usage?.isAtCap ?? false;
    final ringColor = semantic.usageMeterColorFor(progress);

    // Foreground text color tuned for the glass surface in each mode.
    // Dark mode: nearly-white off-white. Light mode: deep navy ink.
    final fg = isDark ? const Color(0xFFF7F4EE) : AppColors.ink900;
    final fgMuted = isDark
        ? const Color(0xFFD8D4CB)
        : AppColors.slate500;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      radius: 24,
      // Subtle warm gradient overlay in the top-left corner; gives the
      // card a focal "hot spot" that catches the eye first.
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.amber600.withValues(alpha: 0.10),
                Colors.transparent,
              ]
            : [
                AppColors.amber100.withValues(alpha: 0.45),
                Colors.transparent,
              ],
        stops: const [0.0, 0.6],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + settings.
          Row(
            children: [
              UserAvatar(
                photoUrl: photoUrl,
                displayName: displayName,
                email: email,
                radius: 20,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: fg.withValues(alpha: 0.85),
                ),
                tooltip: 'Settings',
                onPressed: onSettings,
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Greeting line.
          Text(
            hasName ? '$greeting,' : 'Welcome to',
            style: theme.textTheme.titleSmall?.copyWith(
              color: fgMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasName ? fname : 'RecapCoach',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displaySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 34,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _Stat(
                  value: '${stats.count}',
                  label: stats.count == 1
                      ? 'recording\nthis week'
                      : 'recordings\nthis week',
                  fg: fg,
                  fgMuted: fgMuted,
                ),
              ),
              _Divider(isDark: isDark),
              Expanded(
                child: _Stat(
                  value: '${stats.minutes}',
                  label: stats.minutes == 1
                      ? 'minute\ncaptured'
                      : 'minutes\ncaptured',
                  fg: fg,
                  fgMuted: fgMuted,
                ),
              ),
              _Divider(isDark: isDark),
              SizedBox(
                width: 96,
                child: Center(
                  child: ArcUsageRing(
                    progress: progress,
                    color: ringColor,
                    trackColor: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppColors.slate200,
                    size: 84,
                    strokeWidth: 9,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          atCap
                              ? 'CAP'
                              : isPro
                                  ? 'PRO'
                                  : '${(progress * 100).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.0,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          atCap
                              ? 'reached'
                              : isPro
                                  ? 'plan'
                                  : 'used',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: fgMuted,
                            fontSize: 10,
                            height: 1.0,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.fg,
    required this.fgMuted,
  });

  final String value;
  final String label;
  final Color fg;
  final Color fgMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 36,
            height: 1.0,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: fgMuted,
            fontSize: 10.5,
            height: 1.2,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }
}
