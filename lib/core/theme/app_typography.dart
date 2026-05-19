import 'package:flutter/material.dart';

/// Material 3 typography scale for RecapCoach.
///
/// All text in the app should use one of the [TextTheme] styles wired up
/// here. Avoid hard-coding `fontSize` or `fontWeight` in widget code;
/// instead use `Theme.of(context).textTheme.headlineSmall` (etc.).
///
/// Font choice
/// -----------
/// We declare a preferred font family of [_preferredFontFamily] (Inter).
/// If Inter is bundled in `assets/fonts/` and declared in `pubspec.yaml`
/// under `flutter.fonts`, Flutter uses it automatically. If not, Flutter
/// silently falls back to the platform system font (Roboto on Android,
/// San Francisco on iOS) -- both excellent and indistinguishable from
/// Inter to most users.
///
/// To upgrade to bundled Inter later: download the TTF files from
/// <https://rsms.me/inter/>, drop them in `assets/fonts/Inter/`, and add
/// the family declaration to `pubspec.yaml`. No widget code changes
/// required.
///
/// Weight rationale (Material 3 defaults, tightened for our
/// professional/consultant aesthetic):
/// - Display + headline weights bumped from w400 -> w600/w700 for impact.
/// - Title weights kept at w600 for hierarchy.
/// - Body weights at w400; labels at w500 for buttons/chips.
class AppTypography {
  AppTypography._();

  /// Preferred font family. If a font with this name is registered (via
  /// `pubspec.yaml` assets), it's used; otherwise the platform default
  /// applies. Setting this on every style is harmless when the family
  /// isn't registered -- Flutter just falls back.
  static const String _preferredFontFamily = 'Inter';

  /// The full Material 3 text scale.
  ///
  /// Called once by [AppTheme] for both light and dark themes; the
  /// per-style colors are applied later by Material via the [ColorScheme].
  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;

    TextStyle styled(TextStyle? source, FontWeight weight, {double? letterSpacing}) {
      return (source ?? const TextStyle()).copyWith(
        fontFamily: _preferredFontFamily,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );
    }

    return base.copyWith(
      // Display
      displayLarge: styled(base.displayLarge, FontWeight.w600, letterSpacing: -1.5),
      displayMedium: styled(base.displayMedium, FontWeight.w600, letterSpacing: -1.0),
      displaySmall: styled(base.displaySmall, FontWeight.w600, letterSpacing: -0.5),

      // Headline
      headlineLarge: styled(base.headlineLarge, FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: styled(base.headlineMedium, FontWeight.w700, letterSpacing: -0.25),
      headlineSmall: styled(base.headlineSmall, FontWeight.w600),

      // Title (used in cards / list tiles)
      titleLarge: styled(base.titleLarge, FontWeight.w600),
      titleMedium: styled(base.titleMedium, FontWeight.w600),
      titleSmall: styled(base.titleSmall, FontWeight.w600),

      // Body
      bodyLarge: styled(base.bodyLarge, FontWeight.w400),
      bodyMedium: styled(base.bodyMedium, FontWeight.w400),
      bodySmall: styled(base.bodySmall, FontWeight.w400),

      // Label (buttons, chips)
      labelLarge: styled(base.labelLarge, FontWeight.w600, letterSpacing: 0.25),
      labelMedium: styled(base.labelMedium, FontWeight.w500, letterSpacing: 0.4),
      labelSmall: styled(base.labelSmall, FontWeight.w500, letterSpacing: 0.5),
    );
  }

  /// Style modifier that enables tabular figures so numerals don't shift
  /// position when changing. Apply on top of any base style:
  ///
  /// ```dart
  /// Text(
  ///   '12:34',
  ///   style: theme.textTheme.displayMedium?.merge(
  ///     AppTypography.tabularNumberStyle,
  ///   ),
  /// )
  /// ```
  ///
  /// Used by the recording timer and any numeric counters.
  static const TextStyle tabularNumberStyle = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
