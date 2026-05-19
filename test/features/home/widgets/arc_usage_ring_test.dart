// Smoke + behavior tests for `ArcUsageRing`. The actual arc geometry
// is painted via CustomPainter so we can't query it with `find.*`;
// instead we verify that the widget builds, animates, accepts an
// optional center widget, and respects clamped progress bounds.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/arc_usage_ring.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double progress,
  Widget? center,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: ArcUsageRing(
            progress: progress,
            color: Colors.amber,
            trackColor: Colors.grey,
            center: center,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ArcUsageRing', () {
    testWidgets('Builds at zero progress without exceptions',
        (tester) async {
      await _pump(tester, progress: 0);
      expect(tester.takeException(), isNull);
      expect(find.byType(ArcUsageRing), findsOneWidget);
    });

    testWidgets('Builds at full progress without exceptions',
        (tester) async {
      await _pump(tester, progress: 1.0);
      // Pump animation forward so the Tween completes.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders the optional center child', (tester) async {
      await _pump(
        tester,
        progress: 0.4,
        center: const Text('40%'),
      );
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('Tolerates over-1 progress values (defensive clamp)',
        (tester) async {
      // worstProgress on UsageSnapshot is already clamped, but a
      // direct caller might pass anything. The widget should not
      // throw when handed e.g. 1.5.
      await _pump(tester, progress: 1.5);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tolerates negative progress values (defensive clamp)',
        (tester) async {
      await _pump(tester, progress: -0.3);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
