// Tests for the `WeeklyStatsCard` -- the hero card on the home screen.
//
// IMPORTANT: despite the name, this card now shows MONTHLY usage from
// the server-backed `UsageSnapshot`, not weekly counts from local
// Hive. The rename was deferred to avoid an even larger diff in the
// commit that introduced the redesign. Earlier iterations showed
// "19 recordings this week" alongside "5/5 cap reached this month",
// which was confusing -- the numbers on the card now tie directly to
// the same caps the server-side `quota.ts` enforces.
//
// Two layers under test:
//
//   1. Pure-logic helper: `firstName()`. Static so we can hammer it
//      without a widget pump.
//   2. Widget rendering: greeting branches (signed-in vs anonymous),
//      monthly stat values + labels, arc-center copy across plan +
//      cap states, developer bypass rendering, and settings callback
//      wiring.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/weekly_stats_card.dart';
import 'package:recapcoach/features/usage/usage.dart';

UsageSnapshot _usage({
  String plan = 'free',
  int usedSeconds = 0,
  int usedRecordings = 0,
  bool isDeveloper = false,
}) {
  final isPro = plan == 'pro';
  return UsageSnapshot(
    plan: plan,
    monthKey: '2026-05',
    usedSeconds: usedSeconds,
    usedRecordings: usedRecordings,
    limitSeconds: isPro
        ? UsageSnapshot.proLimitSeconds
        : UsageSnapshot.freeLimitSeconds,
    limitRecordings: isPro
        ? UsageSnapshot.proLimitRecordings
        : UsageSnapshot.freeLimitRecordings,
    limitPerRecordingSeconds: isPro
        ? UsageSnapshot.proLimitPerRecordingSeconds
        : UsageSnapshot.freeLimitPerRecordingSeconds,
    isDeveloper: isDeveloper,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  String? displayName,
  String? email,
  String? photoUrl,
  required DateTime now,
  UsageSnapshot? usage,
  VoidCallback? onSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: WeeklyStatsCard(
          displayName: displayName,
          email: email,
          photoUrl: photoUrl,
          onSettings: onSettings ?? () {},
          usage: usage,
          now: now,
        ),
      ),
    ),
  );
  // Let the arc-ring TweenAnimationBuilder settle.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('WeeklyStatsCard.firstName (static)', () {
    test('Returns the first whitespace-separated token', () {
      expect(WeeklyStatsCard.firstName('Ketan Shukla'), 'Ketan');
    });

    test('Single-token name returns the whole token', () {
      expect(WeeklyStatsCard.firstName('Cher'), 'Cher');
    });

    test('Null and blank inputs return null', () {
      expect(WeeklyStatsCard.firstName(null), isNull);
      expect(WeeklyStatsCard.firstName(''), isNull);
      expect(WeeklyStatsCard.firstName('   '), isNull);
    });
  });

  group('WeeklyStatsCard widget', () {
    final now = DateTime(2026, 5, 18, 9); // 9 a.m. -> Good morning

    testWidgets('Signed-in user shows greeting + first name', (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan Shukla',
        email: 'k@e.com',
        now: now,
        usage: _usage(),
      );
      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Ketan'), findsOneWidget);
    });

    testWidgets('Anonymous user falls back to "Welcome to / RecapCoach"',
        (tester) async {
      await _pump(tester, now: now, usage: _usage());
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('RecapCoach'), findsOneWidget);
      expect(find.text('Good morning,'), findsNothing);
    });

    testWidgets(
        'Free user stats row shows monthly recordings/cap and minutes/cap',
        (tester) async {
      // 2 recordings, 4 minutes (240 seconds) used on the free plan.
      // Free caps come from UsageSnapshot.freeLimitRecordings (5) and
      // freeLimitSeconds (900s = 15 min).
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(usedRecordings: 2, usedSeconds: 240),
      );

      // Big stat values render as "used/cap".
      expect(
        find.text('2/${UsageSnapshot.freeLimitRecordings}'),
        findsOneWidget,
        reason: 'Recordings stat should be "2/5" on free plan',
      );
      expect(
        find.text('4/${UsageSnapshot.freeLimitSeconds ~/ 60}'),
        findsOneWidget,
        reason: 'Minutes stat should be "4/15" on free plan',
      );

      // Stat sub-labels say "this month", not "this week", so the card
      // is unambiguous about which window it covers.
      expect(find.text('recordings\nthis month'), findsOneWidget);
      expect(find.text('minutes\nthis month'), findsOneWidget);
    });

    testWidgets('Free user under cap: arc center shows "X% used"',
        (tester) async {
      // 50% of free seconds cap used.
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(
          usedSeconds: UsageSnapshot.freeLimitSeconds ~/ 2,
          usedRecordings: 0,
        ),
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('used'), findsOneWidget);
    });

    testWidgets('Pro user: arc center shows PRO / plan', (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(plan: 'pro', usedSeconds: 100, usedRecordings: 1),
      );
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('plan'), findsOneWidget);
    });

    testWidgets('At-cap free user: arc center shows CAP / reached',
        (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(
          usedSeconds: UsageSnapshot.freeLimitSeconds,
          usedRecordings: UsageSnapshot.freeLimitRecordings,
        ),
      );
      expect(find.text('CAP'), findsOneWidget);
      expect(find.text('reached'), findsOneWidget);
    });

    testWidgets(
        'Developer bypass: arc shows DEV / unlimited and labels drop "/cap"',
        (tester) async {
      // Developer flag short-circuits caps server-side; the card has
      // to mirror that or the user sees "5/5 cap reached" while the
      // server happily accepts more recordings.
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(
          usedRecordings: 19,
          usedSeconds: 4 * 60,
          isDeveloper: true,
        ),
      );

      // Arc center.
      expect(find.text('DEV'), findsOneWidget);
      expect(find.text('unlimited'), findsAtLeastNWidgets(1));

      // Stat values: counts only, NO "/cap" suffix.
      expect(find.text('19'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('19/5'), findsNothing);

      // Stat labels: plural forms with "unlimited" sub-label, not
      // "this month / cap".
      expect(find.text('recordings\nunlimited'), findsOneWidget);
      expect(find.text('minutes\nunlimited'), findsOneWidget);
      expect(find.text('recordings\nthis month'), findsNothing);
    });

    testWidgets(
        'Developer bypass with single recording uses singular labels',
        (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(
          usedRecordings: 1,
          usedSeconds: 60, // 1 minute exactly
          isDeveloper: true,
        ),
      );
      expect(find.text('recording\nunlimited'), findsOneWidget);
      expect(find.text('minute\nunlimited'), findsOneWidget);
    });

    testWidgets('Settings icon button fires onSettings callback',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        usage: _usage(),
        onSettings: () => taps++,
      );
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
