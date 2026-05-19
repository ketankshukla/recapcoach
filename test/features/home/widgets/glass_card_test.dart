// Smoke tests for `GlassCard`. The visual treatment (BackdropFilter
// blur, hairline border, drop shadow) can't really be asserted with
// `find.*` queries -- they're rendered to a layer tree, not to the
// widget tree. Instead we check structural invariants: the child is
// reachable, the tap callback fires when set, and the widget builds
// without exceptions in both light + dark themes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/glass_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  ThemeData? theme,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: GlassCard(onTap: onTap, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('GlassCard', () {
    testWidgets('Renders the child widget', (tester) async {
      await _pump(tester, child: const Text('hello'));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('Builds without exceptions in dark theme too',
        (tester) async {
      await _pump(
        tester,
        child: const Text('hi'),
        theme: AppTheme.dark(),
      );
      expect(find.text('hi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onTap fires when the card is tapped', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        child: const Text('tappable'),
        onTap: () => taps++,
      );
      await tester.tap(find.text('tappable'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('No InkWell wrapping when onTap is null', (tester) async {
      // Defensive: when there's no callback we don't want to build
      // an InkWell that swallows pointer events meant for children.
      await _pump(tester, child: const Text('static'));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('InkWell present only when onTap is set', (tester) async {
      await _pump(
        tester,
        child: const Text('tappable'),
        onTap: () {},
      );
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
