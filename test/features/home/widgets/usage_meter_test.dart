// Widget tests for the redesigned `UsageMeter`. Verifies the headline
// + plan badge + Upgrade CTA show up correctly across the four
// (plan, threshold) combinations.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/usage_meter.dart';
import 'package:recapcoach/features/usage/usage.dart';

UsageSnapshot _free({required int usedSeconds, required int usedRecordings}) {
  return UsageSnapshot(
    plan: 'free',
    monthKey: '2026-05',
    usedSeconds: usedSeconds,
    usedRecordings: usedRecordings,
    limitSeconds: UsageSnapshot.freeLimitSeconds,
    limitRecordings: UsageSnapshot.freeLimitRecordings,
    limitPerRecordingSeconds: UsageSnapshot.freeLimitPerRecordingSeconds,
  );
}

UsageSnapshot _pro({required int usedSeconds, required int usedRecordings}) {
  return UsageSnapshot(
    plan: 'pro',
    monthKey: '2026-05',
    usedSeconds: usedSeconds,
    usedRecordings: usedRecordings,
    limitSeconds: UsageSnapshot.proLimitSeconds,
    limitRecordings: UsageSnapshot.proLimitRecordings,
    limitPerRecordingSeconds: UsageSnapshot.proLimitPerRecordingSeconds,
  );
}

Future<void> _pump(WidgetTester tester, UsageSnapshot usage) async {
  // We wrap in a tiny GoRouter so the inline "Upgrade" button (which
  // calls `context.push`) doesn't blow up when present. Tapping is not
  // exercised here -- the Upgrade route belongs to Phase 4 -- so a
  // single placeholder route is sufficient.
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(body: UsageMeter(usage: usage)),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
  // Settle the entry transition.
  await tester.pumpAndSettle();
}

void main() {
  group('UsageMeter', () {
    testWidgets('Free user well under cap shows "This month" + FREE badge',
        (tester) async {
      await _pump(tester, _free(usedSeconds: 60, usedRecordings: 1));
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      // No Upgrade button while well under cap.
      expect(find.text('Upgrade'), findsNothing);
    });

    testWidgets('Free user at >= 80% shows "Almost out" + Upgrade CTA',
        (tester) async {
      await _pump(
        tester,
        _free(
          usedSeconds: (UsageSnapshot.freeLimitSeconds * 0.85).round(),
          usedRecordings: 4,
        ),
      );
      expect(find.text('Almost out this month'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('Free user at cap shows "Monthly limit reached" + Upgrade',
        (tester) async {
      await _pump(
        tester,
        _free(
          usedSeconds: UsageSnapshot.freeLimitSeconds,
          usedRecordings: UsageSnapshot.freeLimitRecordings,
        ),
      );
      expect(find.text('Monthly limit reached'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('Pro user shows PRO badge and never an Upgrade button',
        (tester) async {
      // Even at 50% of cap a Pro user should never see an Upgrade CTA.
      await _pump(
        tester,
        _pro(
          usedSeconds: UsageSnapshot.proLimitSeconds ~/ 2,
          usedRecordings: 50,
        ),
      );
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Pro plan'), findsOneWidget);
      expect(find.text('Upgrade'), findsNothing);
    });

    testWidgets('Renders the recordings + minutes summary line',
        (tester) async {
      await _pump(tester, _free(usedSeconds: 240, usedRecordings: 2));
      // 240 seconds = 4 min; free cap = 15 min.
      expect(find.textContaining('2 of 5 recordings'), findsOneWidget);
      expect(find.textContaining('4 / 15 min'), findsOneWidget);
    });
  });
}
