// Unit + widget tests for the RecapCoach design system.
//
// These tests guard the design-token vocabulary. If anyone accidentally
// changes a token value, deletes a token, or breaks the light/dark
// ColorScheme symmetry, these tests catch it before it lands on `main`.
//
// Test catalogue: `docs/13-ui-design-system.md` references this file as
// the "is the theme actually wired correctly" check.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_colors.dart';
import 'package:recapcoach/core/theme/app_radii.dart';
import 'package:recapcoach/core/theme/app_semantic_colors.dart';
import 'package:recapcoach/core/theme/app_spacing.dart';
import 'package:recapcoach/core/theme/app_theme.dart';

void main() {
  group('AppColors -- palette constants', () {
    test('Navy scale exposes the expected tones', () {
      // If any of these change without a deliberate design review, the
      // entire app's primary color drifts. Catch the drift here.
      expect(AppColors.navy900, const Color(0xFF0F1E3D));
      expect(AppColors.navy800, const Color(0xFF1B2A4E));
      expect(AppColors.navy700, const Color(0xFF2D4373));
      expect(AppColors.navy500, const Color(0xFF7B9FE0));
      expect(AppColors.navy200, const Color(0xFFA8C0E8));
      expect(AppColors.navy100, const Color(0xFFD8E0F0));
    });

    test('Amber scale exposes the expected tones', () {
      expect(AppColors.amber900, const Color(0xFF78350F));
      expect(AppColors.amber700, const Color(0xFF92400E));
      expect(AppColors.amber600, const Color(0xFFD97706));
      expect(AppColors.amber400, const Color(0xFFF4A261));
      expect(AppColors.amber100, const Color(0xFFFEF3C7));
    });

    test('Semantic aliases route to the right scale', () {
      // `success` should map onto sage (calm), not navy or amber.
      expect(AppColors.success, AppColors.sage500);
      expect(AppColors.successDark, AppColors.sage300);

      // `warning` should align with amber so the UI doesn't fight itself.
      expect(AppColors.warning, AppColors.amber600);
      expect(AppColors.warningDark, AppColors.amber400);
    });
  });

  group('AppSpacing -- 4pt scale', () {
    test('All tokens are multiples of 4', () {
      // The whole point of a 4pt scale is that you can't accidentally
      // ship a 7px gap that breaks the rhythm.
      final values = [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.huge,
      ];

      for (final v in values) {
        expect(
          v % 4,
          0,
          reason: 'AppSpacing token $v is not a multiple of 4',
        );
      }
    });

    test('Scale is strictly monotonically increasing', () {
      // A scale that isn't monotonic is broken: if `lg < md` then a
      // designer's mental model breaks down immediately.
      final ordered = <double>[
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.huge,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i] > ordered[i - 1],
          isTrue,
          reason: 'Spacing token at index $i (${ordered[i]}) '
              'is not greater than its predecessor (${ordered[i - 1]})',
        );
      }
    });

    test('md is 16 -- the most-used default', () {
      // Documented contract: AppSpacing.md is the default card padding
      // across the entire app. Locking the value here.
      expect(AppSpacing.md, 16);
    });
  });

  group('AppRadii -- border radius tokens', () {
    test('Scale is strictly monotonically increasing', () {
      final ordered = <double>[
        AppRadii.xs,
        AppRadii.sm,
        AppRadii.md,
        AppRadii.lg,
        AppRadii.xl,
        AppRadii.pill,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i] > ordered[i - 1], isTrue);
      }
    });

    test('md is 12 (default radius across cards/buttons/inputs)', () {
      expect(AppRadii.md, 12);
    });

    test('full is effectively-infinite for pill / circle shapes', () {
      expect(AppRadii.full, greaterThanOrEqualTo(9999));
    });

    test('all() returns a BorderRadius with the right radius value', () {
      expect(AppRadii.all(16), BorderRadius.circular(16));
    });
  });

  group('AppSemanticColors -- usage meter color logic', () {
    test('Progress < 0.5 returns the low (sage) color', () {
      const tokens = AppSemanticColors.light;
      expect(tokens.usageMeterColorFor(0.0), tokens.usageMeterLow);
      expect(tokens.usageMeterColorFor(0.25), tokens.usageMeterLow);
      expect(tokens.usageMeterColorFor(0.49), tokens.usageMeterLow);
    });

    test('Progress in [0.5, 0.8) returns the mid (amber) color', () {
      const tokens = AppSemanticColors.light;
      expect(tokens.usageMeterColorFor(0.5), tokens.usageMeterMid);
      expect(tokens.usageMeterColorFor(0.65), tokens.usageMeterMid);
      expect(tokens.usageMeterColorFor(0.79), tokens.usageMeterMid);
    });

    test('Progress >= 0.8 returns the high (red) color', () {
      const tokens = AppSemanticColors.light;
      expect(tokens.usageMeterColorFor(0.8), tokens.usageMeterHigh);
      expect(tokens.usageMeterColorFor(0.95), tokens.usageMeterHigh);
      expect(tokens.usageMeterColorFor(1.0), tokens.usageMeterHigh);
    });

    test('lerp between two identical instances returns equivalent fields', () {
      const a = AppSemanticColors.light;
      final lerped = a.lerp(a, 0.5);
      expect(lerped.usageMeterLow, a.usageMeterLow);
      expect(lerped.recordingPulse, a.recordingPulse);
      expect(lerped.proBadge, a.proBadge);
    });

    test('copyWith preserves untouched fields and overrides specified ones', () {
      const base = AppSemanticColors.light;
      final next = base.copyWith(recordingPulse: const Color(0xFF000000));

      expect(next.recordingPulse, const Color(0xFF000000));
      expect(next.usageMeterLow, base.usageMeterLow);
      expect(next.proBadge, base.proBadge);
    });
  });

  group('AppTheme -- ThemeData wiring', () {
    test('light() returns a Material 3 theme', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('dark() returns a Material 3 theme', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('light primary is navy800; dark primary is navy200', () {
      // Locks the brand color so a future refactor can't accidentally
      // change the entire app's primary tone.
      expect(AppTheme.light().colorScheme.primary, AppColors.navy800);
      expect(AppTheme.dark().colorScheme.primary, AppColors.navy200);
    });

    test('light secondary is amber600; dark secondary is amber400', () {
      expect(AppTheme.light().colorScheme.secondary, AppColors.amber600);
      expect(AppTheme.dark().colorScheme.secondary, AppColors.amber400);
    });

    test('Both themes expose the AppSemanticColors extension', () {
      final lightExt = AppTheme.light().extension<AppSemanticColors>();
      final darkExt = AppTheme.dark().extension<AppSemanticColors>();
      expect(lightExt, isNotNull);
      expect(darkExt, isNotNull);
      expect(lightExt, AppSemanticColors.light);
      expect(darkExt, AppSemanticColors.dark);
    });

    testWidgets(
      'extension<AppSemanticColors>() is reachable from a widget context',
      (tester) async {
        AppSemanticColors? captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) {
                captured = Theme.of(context).extension<AppSemanticColors>();
                return const SizedBox();
              },
            ),
          ),
        );
        expect(captured, isNotNull);
        expect(captured, AppSemanticColors.light);
      },
    );
  });
}
