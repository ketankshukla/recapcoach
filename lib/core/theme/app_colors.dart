import 'package:flutter/material.dart';

/// Raw color tokens for RecapCoach's "deep navy + warm amber" palette.
///
/// These are the source-of-truth color constants. They are wired into
/// [ColorScheme]s by [AppTheme] in `app_theme.dart`; UI code should
/// consume colors via `Theme.of(context).colorScheme.*` rather than
/// reaching directly into [AppColors] except in extreme cases.
///
/// Aesthetic direction: Direction A (Deep navy + warm amber).
/// Target audience: professional consultants who value a "this looks
/// expensive enough to be serious" signal.
class AppColors {
  AppColors._();

  // ===========================================================================
  // PRIMARY -- Deep navy ("brand")
  // ===========================================================================

  /// Primary navy. Strong, readable, professional. Used for the AppBar,
  /// primary buttons (light mode), and prominent text.
  static const Color navy900 = Color(0xFF0F1E3D);
  static const Color navy800 = Color(0xFF1B2A4E);
  static const Color navy700 = Color(0xFF2D4373);
  static const Color navy500 = Color(0xFF7B9FE0);
  static const Color navy200 = Color(0xFFA8C0E8);
  static const Color navy100 = Color(0xFFD8E0F0);

  // ===========================================================================
  // SECONDARY -- Warm amber accent
  // ===========================================================================

  /// Primary amber. Used for accents, "Upgrade" CTAs, recording pulse,
  /// and the warm-glow moments in the UI.
  ///
  /// `amber600` is the accessible-on-white tone; `amber400` is the
  /// brighter pop used on dark surfaces.
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber700 = Color(0xFF92400E);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber400 = Color(0xFFF4A261);
  static const Color amber100 = Color(0xFFFEF3C7);

  // ===========================================================================
  // TERTIARY -- Sage (for success/positive states that need a non-amber accent)
  // ===========================================================================

  static const Color sage700 = Color(0xFF4A7264);
  static const Color sage500 = Color(0xFF5A8C7B);
  static const Color sage300 = Color(0xFF86B5A1);

  // ===========================================================================
  // NEUTRALS -- Warm off-whites + true blacks
  // ===========================================================================

  /// Warm off-white scaffold background. Slightly warmer than pure white
  /// to play well with the amber accents.
  static const Color cream50 = Color(0xFFFAFAF7);
  static const Color cream100 = Color(0xFFF4F3EE);
  static const Color cream200 = Color(0xFFEFEDE6);
  static const Color cream50Dark = Color(0xFFF5F1E8);

  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E0);
  static const Color slate500 = Color(0xFF4A5568);
  static const Color slate400 = Color(0xFFA0AEC0);

  static const Color ink900 = Color(0xFF080F1F);
  static const Color ink800 = Color(0xFF0F1E3D);
  static const Color ink700 = Color(0xFF152544);

  // ===========================================================================
  // SEMANTIC -- Error / success / warning tones tuned to the palette
  // ===========================================================================

  static const Color error700 = Color(0xFF7F1D1D);
  static const Color error600 = Color(0xFFB91C1C);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error100 = Color(0xFFFECACA);

  /// Success uses the sage family by default; this alias makes intent
  /// explicit at the call site.
  static const Color success = sage500;
  static const Color successDark = sage300;

  /// Warning aligns with the amber accent so the UI doesn't fight itself.
  static const Color warning = amber600;
  static const Color warningDark = amber400;
}

