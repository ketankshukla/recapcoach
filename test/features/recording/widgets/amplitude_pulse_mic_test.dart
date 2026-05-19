// Tests for the `AmplitudePulseMic` -- the hero amber-on-glass mic
// disc that breathes with the live amplitude feed on the Record
// screen.
//
// The disc must:
//   1. Render at a baseline size when the recorder reports silence
//      (-60 dB or lower).
//   2. Grow to a maximum size when the recorder reports clipping
//      (0 dB or higher).
//   3. Defensively clamp dB values OUTSIDE [-60, 0] -- a recorder
//      misreport must never produce a negative-sized box (which
//      Flutter would assert on).
//   4. Be rebuildable in both light and dark themes without
//      exceptions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/recording/widgets/amplitude_pulse_mic.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double amplitudeDb,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: AmplitudePulseMic(amplitudeDb: amplitudeDb),
        ),
      ),
    ),
  );
  // Settle the AnimatedContainer.
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('AmplitudePulseMic', () {
    testWidgets('Renders mic glyph at silence (-60 dB)', (tester) async {
      await _pump(tester, amplitudeDb: -60);

      // The mic icon is the focal element; if it's missing the
      // user-visible affordance is gone.
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('Sizes up at loud amplitude (-10 dB)', (tester) async {
      // We compare the rendered width across two amplitudes; the
      // disc should grow with loudness. AnimatedContainer animates
      // toward the target size, so we settle one frame and pull the
      // box's size from the rendered tree.
      await _pump(tester, amplitudeDb: -60);
      final quietSize = tester.getSize(
        find.byType(AmplitudePulseMic),
      );

      await _pump(tester, amplitudeDb: -10);
      // Allow the AnimatedContainer to settle to the new target.
      await tester.pump(const Duration(milliseconds: 300));
      final loudSize = tester.getSize(
        find.byType(AmplitudePulseMic),
      );

      expect(
        loudSize.width,
        greaterThan(quietSize.width),
        reason: 'Loud disc must be bigger than quiet disc',
      );
    });

    testWidgets('Defensive clamp: amplitudes outside [-60, 0] do not crash',
        (tester) async {
      // -100 dB (silence below clamp) and +10 dB (over-clip) are
      // physically impossible but a misbehaving recorder might emit
      // them. The widget must not throw.
      await _pump(tester, amplitudeDb: -100);
      expect(tester.takeException(), isNull);

      await _pump(tester, amplitudeDb: 10);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Builds clean in dark theme', (tester) async {
      await _pump(
        tester,
        amplitudeDb: -30,
        theme: AppTheme.dark(),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
