/// Spacing tokens for RecapCoach, built on a 4pt scale.
///
/// All padding / margin / gap values in the app should reference one of
/// these constants. The 4pt base gives us pixel-perfect alignment on all
/// reasonable device DPIs while keeping the vocabulary small enough to
/// memorise.
///
/// Use as: `EdgeInsets.all(AppSpacing.md)` or `SizedBox(height: AppSpacing.lg)`.
class AppSpacing {
  AppSpacing._();

  /// 4 -- micro spacing (icon-to-text in compact chips, etc.)
  static const double xxs = 4;

  /// 8 -- tight spacing (between related elements)
  static const double xs = 8;

  /// 12 -- small spacing (between paragraphs in a card)
  static const double sm = 12;

  /// 16 -- default spacing (the most-used value; standard card padding)
  static const double md = 16;

  /// 20 -- comfortable spacing (between major card elements)
  static const double lg = 20;

  /// 24 -- section spacing (between sections within a screen)
  static const double xl = 24;

  /// 32 -- generous spacing (between screen regions)
  static const double xxl = 32;

  /// 48 -- hero spacing (top of major screens, around hero elements)
  static const double xxxl = 48;

  /// 64 -- maximal spacing (rarely needed; large empty states)
  static const double huge = 64;
}
