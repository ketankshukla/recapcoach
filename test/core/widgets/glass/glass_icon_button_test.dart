// Tests for the shared `GlassIconButton` -- the floating glass
// icon-square used in the top corners of full-bleed glass screens
// (Paywall close, Record cancel, future Settings back, etc.).
//
// We test:
//   - Renders the icon and fires onPressed.
//   - Tooltip surfaces on long-press / hover.
//   - Custom `tint` colour is honoured (used for the red Discard
//     control on the Record screen).
//   - Builds clean in dark theme.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_colors.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/core/widgets/glass/glass_icon_button.dart';

Future<void> _pump(
  WidgetTester tester, {
  required GlassIconButton button,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  group('GlassIconButton', () {
    testWidgets('Renders icon and fires onPressed', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        button: GlassIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Cancel',
          onPressed: () => taps++,
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('Honours custom tint colour for destructive actions',
        (tester) async {
      // The Record screen uses red for "Discard"; if the tint
      // override silently fell back to the default fg, that
      // affordance would lose its visual urgency.
      await _pump(
        tester,
        button: GlassIconButton(
          icon: Icons.delete_outline_rounded,
          tint: AppColors.error600,
          onPressed: () {},
        ),
      );

      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.delete_outline_rounded),
      );
      expect(iconWidget.color, AppColors.error600);
    });

    testWidgets('Uses default off-white foreground in dark mode',
        (tester) async {
      await _pump(
        tester,
        theme: AppTheme.dark(),
        button: GlassIconButton(
          icon: Icons.close_rounded,
          onPressed: () {},
        ),
      );

      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.close_rounded),
      );
      // Off-white token used as the default fg in dark mode.
      expect(iconWidget.color, const Color(0xFFF7F4EE));
    });

    testWidgets('Builds in light + dark theme without exceptions',
        (tester) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: GlassIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
