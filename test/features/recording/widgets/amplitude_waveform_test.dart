// Tests for `AmplitudeWaveform` -- the 20-bar amber-gradient
// waveform that visualises live mic loudness on the Record screen.
//
// We test:
//   1. Default barCount (20) renders 20 children.
//   2. Custom barCount is honoured.
//   3. Defensive clamping for amplitudes outside [-60, 0].
//   4. Dark-mode build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/recording/widgets/amplitude_waveform.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double amplitudeDb,
  int? barCount,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: AmplitudeWaveform(
            amplitudeDb: amplitudeDb,
            barCount: barCount ?? 20,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('AmplitudeWaveform', () {
    testWidgets('Renders 20 bars by default', (tester) async {
      await _pump(tester, amplitudeDb: -30);

      // Each bar is one `AnimatedContainer`, wrapped in a `Padding`
      // for spacing. We count AnimatedContainers because Padding
      // can also be inserted internally by AnimatedContainer's
      // implementation, leading to false positives.
      final bars = find.descendant(
        of: find.byType(AmplitudeWaveform),
        matching: find.byType(AnimatedContainer),
      );
      expect(bars.evaluate().length, 20);
    });

    testWidgets('Honours custom barCount', (tester) async {
      await _pump(tester, amplitudeDb: -30, barCount: 10);

      final bars = find.descendant(
        of: find.byType(AmplitudeWaveform),
        matching: find.byType(AnimatedContainer),
      );
      expect(bars.evaluate().length, 10);
    });

    testWidgets('Defensive clamp: amplitudes outside [-60, 0] do not crash',
        (tester) async {
      await _pump(tester, amplitudeDb: -100);
      expect(tester.takeException(), isNull);

      await _pump(tester, amplitudeDb: 20);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Builds clean in dark theme', (tester) async {
      await _pump(
        tester,
        amplitudeDb: -10,
        theme: AppTheme.dark(),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
