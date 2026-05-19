// Widget tests for `HomeAppBar`. Verifies the greeting selection, the
// no-user fallback copy, and the settings callback wiring.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/home_app_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? displayName,
  String? email,
  String? photoUrl,
  required DateTime now,
  VoidCallback? onSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        appBar: HomeAppBar(
          displayName: displayName,
          email: email,
          photoUrl: photoUrl,
          now: now,
          onSettings: onSettings ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('HomeAppBar', () {
    testWidgets('Morning + signed-in user shows "Good morning, Ketan"',
        (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan Shukla',
        email: 'ketan@example.com',
        now: DateTime(2026, 5, 18, 9), // 9 a.m. -> morning
      );
      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Ketan'), findsOneWidget);
    });

    testWidgets('Afternoon shows "Good afternoon"', (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: DateTime(2026, 5, 18, 14),
      );
      expect(find.text('Good afternoon,'), findsOneWidget);
    });

    testWidgets('Evening shows "Good evening"', (tester) async {
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: DateTime(2026, 5, 18, 21),
      );
      expect(find.text('Good evening,'), findsOneWidget);
    });

    testWidgets('No display name falls back to "Welcome to RecapCoach"',
        (tester) async {
      await _pump(
        tester,
        now: DateTime(2026, 5, 18, 9),
      );
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('RecapCoach'), findsOneWidget);
      // Still no "Good morning" greeting -- the welcome line replaces it.
      expect(find.text('Good morning,'), findsNothing);
    });

    testWidgets('Settings icon button fires onSettings callback',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        displayName: 'Ketan',
        email: 'k@e.com',
        now: DateTime(2026, 5, 18, 9),
        onSettings: () => taps++,
      );
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('Uses only the first whitespace-separated token of the name',
        (tester) async {
      // Avoids "Good morning, Ketan Shukla Long Last Name" overflowing
      // the title row on small phones.
      await _pump(
        tester,
        displayName: 'Ketan Shukla',
        email: 'k@e.com',
        now: DateTime(2026, 5, 18, 9),
      );
      expect(find.text('Ketan'), findsOneWidget);
      expect(find.text('Ketan Shukla'), findsNothing);
    });
  });
}
