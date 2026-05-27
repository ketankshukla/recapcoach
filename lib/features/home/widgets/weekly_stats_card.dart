import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
///  3. Shows three at-a-glance stats: this-MONTH recordings, this-month
///     minutes used, and a circular usage arc with the percent used
///     in the center. All three come from the server-backed
///     `UsageSnapshot` so they tie directly to the quota that the
///     "plan cap reached" dialog enforces -- earlier iterations
///     showed weekly counts from local Hive, which led to confusing
///     screens like "19 recordings this week" alongside "5/5 cap
///     reached this month."
///
/// Developer accounts (`usage.isDeveloper == true`) get a special
/// rendering: caps disappear, the arc shows "DEV / unlimited" instead
/// of a percent, and the stat labels drop the "/cap" suffix.
///
/// Designed to be the visual focal point of the screen. Built on top
/// of [GlassCard] so it sits over the mesh-gradient background with a
/// frosted-glass feel.
///
/// `now` is overridable for tests so we can deterministically
/// exercise greeting branches without time-of-day flakiness.
class WeeklyStatsCard extends StatelessWidget {
  const WeeklyStatsCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onSettings,
    required this.usage,
    this.now,
  });

  final String? displayName;
  final String? email;
  final String? photoUrl;
  final VoidCallback onSettings;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    final t = now ?? DateTime.now();
    final greeting = TimeBasedGreeting.forTime(t);
    final fname = firstName(displayName);
    final hasName = fname != null;

    final progress = (usage?.worstProgress ?? 0).clamp(0.0, 1.0);
    final isPro = usage?.plan == 'pro';
    final isDeveloper = usage?.isDeveloper ?? false;
    final atCap = usage?.isAtCap ?? false;
    final ringColor = isDeveloper
        ? AppColors.amber400
        : semantic.usageMeterColorFor(progress);

    // Monthly usage from the server-backed UsageSnapshot. These tie
    // directly to the caps in the "plan limit reached" dialog so the
    // numbers on screen are the same numbers the server enforces.
    final usedRecordings = usage?.usedRecordings ?? 0;
    final limitRecordings = usage?.limitRecordings ?? 0;
    final usedSeconds = usage?.usedSeconds ?? 0;
    final limitSeconds = usage?.limitSeconds ?? 0;

    // Format exact time as "Xm Ys" for precision.
    String fmtTime(int totalSec) {
      final m = totalSec ~/ 60;
      final s = totalSec % 60;
      if (m == 0 && s == 0) return '0m 0s';
      if (m == 0) return '${s}s';
      if (s == 0) return '${m}m';
      return '${m}m ${s}s';
    }

    final usedTimeLabel = fmtTime(usedSeconds);
    final limitTimeLabel = fmtTime(limitSeconds);

    // Remaining values for non-developer accounts.
    final remainingRecordings =
        (limitRecordings - usedRecordings).clamp(0, limitRecordings);
    final remainingSeconds =
        (limitSeconds - usedSeconds).clamp(0, limitSeconds);
    final remainingTimeLabel = fmtTime(remainingSeconds);

    // Stat row labels adapt to dev vs free vs pro.
    //
    //  - Developer: just the count, no "/cap" suffix, "unlimited"
    //    sub-label.
    //  - Free / Pro: "used / cap" big text with exact time, plus a
    //    clear "remaining" summary below the stats row.
    final recordingsValue =
        isDeveloper ? '$usedRecordings' : '$usedRecordings/$limitRecordings';
    final recordingsLabel = isDeveloper
        ? (usedRecordings == 1 ? 'recording\nunlimited' : 'recordings\nunlimited')
        : 'recordings\nused this month';
    final minutesLabel = isDeveloper
        ? 'time\nunlimited'
        : 'time\nused this month';

    // Arc center: percent / PRO / CAP / DEV depending on plan + state.
    final String arcHead;
    final String arcSub;
    if (isDeveloper) {
      arcHead = 'DEV';
      arcSub = 'unlimited';
    } else if (atCap) {
      arcHead = 'CAP';
      arcSub = 'reached';
    } else if (isPro) {
      arcHead = 'PRO';
      arcSub = 'plan';
    } else {
      arcHead = '${(progress * 100).round()}%';
      arcSub = 'used';
    }

    // Remaining summary line for non-developer accounts.
    final trialExhausted = usage?.trialExhausted ?? false;
    final String? remainingSummary;
    if (isDeveloper) {
      remainingSummary = null;
    } else if (trialExhausted && !isPro) {
      remainingSummary = 'Your free trial has been used. '
          'Upgrade to Pro to continue recording.';
    } else if (atCap) {
      remainingSummary = 'You have reached your monthly cap. '
          'Upgrade to Pro for more recordings.';
    } else {
      remainingSummary = '$remainingRecordings recordings and '
          '$remainingTimeLabel remaining this month. '
          'Deleted recordings still count toward your cap.';
    }

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
                  value: recordingsValue,
                  label: recordingsLabel,
                  fg: fg,
                  fgMuted: fgMuted,
                ),
              ),
              _Divider(isDark: isDark),
              Expanded(
                child: _TimeStat(
                  value: isDeveloper ? usedTimeLabel : usedTimeLabel,
                  ofValue: isDeveloper ? null : limitTimeLabel,
                  label: minutesLabel,
                  fg: fg,
                  fgMuted: fgMuted,
                ),
              ),
              _Divider(isDark: isDark),
              SizedBox(
                width: 96,
                child: Center(
                  child: ArcUsageRing(
                    // Developers see a full amber ring as a visual
                    // "you've got everything" signal rather than an
                    // empty meter.
                    progress: isDeveloper ? 1.0 : progress,
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
                          arcHead,
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
                          arcSub,
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

          // Remaining summary — only for non-developer accounts.
          if (remainingSummary != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? (atCap
                        ? Colors.red.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05))
                    : (atCap
                        ? Colors.red.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? (atCap
                          ? Colors.red.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08))
                      : (atCap
                          ? Colors.red.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              child: Text(
                remainingSummary,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: atCap
                      ? (isDark ? Colors.red.shade200 : Colors.red.shade700)
                      : fgMuted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
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

class _TimeStat extends StatelessWidget {
  const _TimeStat({
    required this.value,
    this.ofValue,
    required this.label,
    required this.fg,
    required this.fgMuted,
  });

  final String value;
  final String? ofValue;
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
            fontSize: 24,
            height: 1.0,
            letterSpacing: -0.4,
          ),
        ),
        if (ofValue != null) ...[
          const SizedBox(height: 2),
          Text(
            'of $ofValue',
            style: theme.textTheme.labelSmall?.copyWith(
              color: fgMuted,
              fontSize: 11,
              height: 1.0,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
