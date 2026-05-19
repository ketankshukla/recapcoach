// Widget tests for `PulsingRecordFab`. Verifies the FAB renders, fires
// its onPressed callback, and survives a pump that crosses the pulse
// animation boundary (catches stale-controller / dispose bugs).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/pulsing_record_fab.dart';

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        floatingActionButton: PulsingRecordFab(onPressed: onPressed),
      ),
    ),
  );
}

void main() {
  group('PulsingRecordFab', () {
    testWidgets('Renders the default label "Record call" with mic icon',
        (tester) async {
      await _pump(tester, onPressed: () {});
      expect(find.text('Record call'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('Tap fires the onPressed callback', (tester) async {
      var taps = 0;
      await _pump(tester, onPressed: () => taps++);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('Pulse animation runs without exceptions across a full cycle',
        (tester) async {
      await _pump(tester, onPressed: () {});
      // Pump well past one full pulse period (1.6s) to make sure the
      // controller's repeat() loop, the AnimatedBuilder rebuilds, and
      // the Container shadow re-evaluation all stay healthy.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1200));
      // No exceptions == pass; explicit assertion just for clarity.
      expect(tester.takeException(), isNull);
    });

    testWidgets('Disposing the widget cancels the controller cleanly',
        (tester) async {
      await _pump(tester, onPressed: () {});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      // If the controller wasn't disposed in dispose(), a "ticker was
      // active when its widget was disposed" assertion would fire here.
      expect(tester.takeException(), isNull);
    });
  });
}
