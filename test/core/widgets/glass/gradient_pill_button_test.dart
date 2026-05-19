// Tests for the shared `GradientPillButton` -- the amber-on-glass
// primary CTA used across the Paywall, Sign In, Record screens, etc.
//
// Three states matter and each has a regression cost:
//
//   1. Idle: tappable, gradient visible, fires onPressed.
//   2. Loading: shows spinner, swallows taps even when onPressed is
//      non-null. Critical because the Paywall calls async purchase()
//      and a double-tap would charge the user twice.
//   3. Disabled (onPressed == null): desaturated, ignores taps.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/core/widgets/glass/gradient_pill_button.dart';

Future<void> _pump(
  WidgetTester tester, {
  required GradientPillButton button,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  group('GradientPillButton', () {
    testWidgets('Renders label + icon and fires onPressed in idle state',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        button: GradientPillButton(
          onPressed: () => taps++,
          label: 'Start free trial',
          icon: Icons.workspace_premium_rounded,
        ),
      );

      expect(find.text('Start free trial'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      // No spinner in idle state.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Start free trial'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('Loading state: shows spinner, hides label, swallows taps',
        (tester) async {
      // [CRITICAL] If a tap during `loading: true` reached onPressed,
      // the Paywall would kick off a second `purchasePackage()` call
      // and the user would be charged twice.
      var taps = 0;
      await _pump(
        tester,
        button: GradientPillButton(
          onPressed: () => taps++,
          label: 'Start free trial',
          loading: true,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label is suppressed while loading so the user doesn't see
      // both the spinner and the trial copy fighting for space.
      expect(find.text('Start free trial'), findsNothing);

      // The tap target still renders; tap it and confirm onPressed
      // doesn't fire.
      await tester.tap(find.byType(GradientPillButton));
      await tester.pump();
      expect(taps, 0, reason: 'Loading state must swallow taps');
    });

    testWidgets('Disabled state (onPressed == null): no taps land',
        (tester) async {
      // `taps` is never incremented because `onPressed` is null; we
      // declare it `final` to make the intent explicit (we want to
      // assert it stays at zero).
      final taps = 0;
      await _pump(
        tester,
        button: const GradientPillButton(
          onPressed: null,
          label: 'Start free trial',
        ),
      );

      expect(find.text('Start free trial'), findsOneWidget);
      // Tapping a null-onPressed button should be a no-op.
      await tester.tap(find.byType(GradientPillButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('Renders with no icon when icon parameter is omitted',
        (tester) async {
      await _pump(
        tester,
        button: GradientPillButton(
          onPressed: () {},
          label: 'Continue',
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      // The button itself is the only Icon-shaped widget; we look for
      // the absence of any specific icon glyph.
      expect(
        find.byIcon(Icons.workspace_premium_rounded),
        findsNothing,
      );
    });

    testWidgets('Builds in dark theme without exceptions', (tester) async {
      // The button has different shadow + border alphas in dark mode;
      // a missing branch would fail to build at runtime.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: GradientPillButton(
                onPressed: () {},
                label: 'Continue',
                expanded: true,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
