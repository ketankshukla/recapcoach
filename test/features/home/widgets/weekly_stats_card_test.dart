// Tests for the `WeeklyStatsCard` -- the new hero card that replaces
// the old AppBar + Account card + horizontal usage meter combo.
//
// Two layers under test:
//
//   1. Pure-logic helpers: `firstName()` and `weeklyStats()`. These
//      are exposed as static methods so we can hammer them without a
//      widget pump.
//   2. Widget rendering: greeting branches (signed-in vs anonymous),
//      stats labels (singular vs plural), settings callback wiring.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/weekly_stats_card.dart';
import 'package:recapcoach/features/notes/note.dart';
import 'package:recapcoach/features/usage/usage.dart';

Note _note({required DateTime createdAt, int durationMs = 60000}) {
  return Note(
    id: 'n-${createdAt.microsecondsSinceEpoch}',
    audioFilePath: '/tmp/x.aac',
    createdAt: createdAt,
    durationMs: durationMs,
  );
}

UsageSnapshot _usage({
  String plan = 'free',
  int usedSeconds = 0,
  int usedRecordings = 0,
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
  );
}

Future<void> _pump(
  WidgetTester tester, {
  String? displayName,
  String? email,
  String? photoUrl,
  required DateTime now,
  required List<Note> notes,
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
          notes: notes,
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

  group('WeeklyStatsCard.weeklyStats (static)', () {
    final now = DateTime.utc(2026, 5, 18, 12);

    test('Counts only notes created in the last 7 days', () {
      final notes = [
        _note(createdAt: now.subtract(const Duration(days: 1))),
        _note(createdAt: now.subtract(const Duration(days: 6))),
        _note(createdAt: now.subtract(const Duration(days: 8))), // out
        _note(createdAt: now.subtract(const Duration(days: 30))), // out
      ];
      final stats = WeeklyStatsCard.weeklyStats(notes, now);
      expect(stats.count, 2);
    });

    test('Sums durations only for in-window notes, in whole minutes', () {
      final notes = [
        _note(
          createdAt: now.subtract(const Duration(days: 1)),
          durationMs: 120000, // 2 min
        ),
        _note(
          createdAt: now.subtract(const Duration(days: 3)),
          durationMs: 180000, // 3 min
        ),
        _note(
          createdAt: now.subtract(const Duration(days: 9)),
          durationMs: 600000, // 10 min, OUT of window
        ),
      ];
      final stats = WeeklyStatsCard.weeklyStats(notes, now);
      expect(stats.count, 2);
      expect(stats.minutes, 5);
    });

    test('Empty list returns zeros', () {
      final stats = WeeklyStatsCard.weeklyStats([], now);
      expect(stats.count, 0);
      expect(stats.minutes, 0);
    });

    test('Boundary: a note exactly 7 days ago is OUT of the window', () {
      // The cutoff uses `>` (isAfter), which matches the user's
      // expectation that "this week" means strictly less than 7 days.
      final notes = [
        _note(createdAt: now.subtract(const Duration(days: 7))),
      ];
      final stats = WeeklyStatsCard.weeklyStats(notes, now);
      expect(stats.count, 0);
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
        notes: [],
      );
      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Ketan'), findsOneWidget);
    });

    testWidgets('Anonymous user falls back to "Welcome to / RecapCoach"',
        (tester) async {
      await _pump(tester, now: now, notes: []);
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('RecapCoach'), findsOneWidget);
      expect(find.text('Good morning,'), findsNothing);
    });

    testWidgets('Stats row shows weekly recording count + minutes',
        (tester) async {
      final notes = [
        _note(
          createdAt: now.subtract(const Duration(days: 1)),
          durationMs: 240000, // 4 min
        ),
        _note(
          createdAt: now.subtract(const Duration(days: 2)),
          durationMs: 180000, // 3 min
        ),
      ];
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        notes: notes,
      );
      // 2 recordings, 7 minutes total
      expect(find.text('2'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('recordings\nthis week'), findsOneWidget);
      expect(find.text('minutes\ncaptured'), findsOneWidget);
    });

    testWidgets('Single-recording label uses the singular form',
        (tester) async {
      final notes = [
        _note(
          createdAt: now.subtract(const Duration(days: 1)),
          durationMs: 60000, // 1 min
        ),
      ];
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        notes: notes,
      );
      expect(find.text('recording\nthis week'), findsOneWidget);
      expect(find.text('minute\ncaptured'), findsOneWidget);
    });

    testWidgets('Free user under cap: arc center shows "X% used"',
        (tester) async {
      // 50% of free seconds cap (15 min) used.
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        notes: [],
        usage: _usage(
          usedSeconds: UsageSnapshot.freeLimitSeconds ~/ 2,
          usedRecordings: 0,
        ),
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('used'), findsOneWidget);
    });

    testWidgets('Pro user: arc center shows PRO / plan',
        (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        notes: [],
        usage: _usage(plan: 'pro', usedSeconds: 100, usedRecordings: 1),
      );
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('plan'), findsOneWidget);
    });

    testWidgets('At-cap user: arc center shows CAP / reached',
        (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        notes: [],
        usage: _usage(
          usedSeconds: UsageSnapshot.freeLimitSeconds,
          usedRecordings: UsageSnapshot.freeLimitRecordings,
        ),
      );
      expect(find.text('CAP'), findsOneWidget);
      expect(find.text('reached'), findsOneWidget);
    });

    testWidgets('Settings icon button fires onSettings callback',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: now,
        notes: [],
        onSettings: () => taps++,
      );
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
