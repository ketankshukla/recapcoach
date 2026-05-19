// Tests for `GlassPillButton` -- the low-key glass pill used for
// tertiary actions (Paywall "Restore", future Settings rows, etc.).
//
// Distinct from `GradientPillButton`, which is the loud amber CTA;
// `GlassPillButton` is the quiet sibling. Both share the rounded
// pill silhouette so they read as a coherent button family.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_colors.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/core/widgets/glass/glass_pill_button.dart';

void main() {
  group('GlassPillButton', () {
    testWidgets('Renders label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: GlassPillButton(
                label: 'Restore',
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Restore'), findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('Renders an optional leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: GlassPillButton(
                label: 'Upgrade',
                icon: Icons.workspace_premium_rounded,
                tint: AppColors.amber600,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Upgrade'), findsOneWidget);
      expect(
        find.byIcon(Icons.workspace_premium_rounded),
        findsOneWidget,
      );
      // The tint should be applied to both the icon and text.
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.workspace_premium_rounded),
      );
      expect(icon.color, AppColors.amber600);
    });

    testWidgets('Builds in dark theme without exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: GlassPillButton(
                label: 'Restore',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Restore'), findsOneWidget);
    });
  });
}
