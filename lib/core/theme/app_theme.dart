import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Light + dark Material 3 themes for RecapCoach.
///
/// This is the only file that should be wiring [ColorScheme] and
/// [ThemeData]. Screens read colors via `Theme.of(context).colorScheme`
/// and app-specific tokens via `Theme.of(context).extension<AppSemanticColors>()`.
///
/// Aesthetic direction: Direction A -- Deep navy + warm amber.
/// See `docs/13-ui-design-system.md` for the design rationale.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Public entry points
  // ---------------------------------------------------------------------------

  static ThemeData light() => _build(_lightColorScheme, Brightness.light);
  static ThemeData dark() => _build(_darkColorScheme, Brightness.dark);

  // ---------------------------------------------------------------------------
  // ColorSchemes (Material 3)
  // ---------------------------------------------------------------------------

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.navy800,
    onPrimary: Colors.white,
    primaryContainer: AppColors.navy100,
    onPrimaryContainer: AppColors.navy900,
    secondary: AppColors.amber600,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.amber100,
    onSecondaryContainer: AppColors.amber900,
    tertiary: AppColors.sage500,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFD9E8E1),
    onTertiaryContainer: AppColors.sage700,
    error: AppColors.error600,
    onError: Colors.white,
    errorContainer: AppColors.error100,
    onErrorContainer: AppColors.error700,
    surface: Colors.white,
    onSurface: AppColors.navy900,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.cream50,
    surfaceContainer: AppColors.cream100,
    surfaceContainerHigh: AppColors.cream200,
    surfaceContainerHighest: AppColors.cream200,
    surfaceTint: AppColors.navy800,
    onSurfaceVariant: AppColors.slate500,
    outline: AppColors.slate300,
    outlineVariant: AppColors.slate200,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.navy900,
    onInverseSurface: AppColors.cream50,
    inversePrimary: AppColors.navy200,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.navy200,
    onPrimary: AppColors.navy900,
    primaryContainer: AppColors.navy800,
    onPrimaryContainer: AppColors.navy100,
    secondary: AppColors.amber400,
    onSecondary: AppColors.amber900,
    secondaryContainer: AppColors.amber700,
    onSecondaryContainer: AppColors.amber100,
    tertiary: AppColors.sage300,
    onTertiary: AppColors.sage700,
    tertiaryContainer: AppColors.sage700,
    onTertiaryContainer: Color(0xFFD9E8E1),
    error: AppColors.error300,
    onError: AppColors.error700,
    errorContainer: AppColors.error700,
    onErrorContainer: AppColors.error100,
    surface: AppColors.ink800,
    onSurface: AppColors.cream50Dark,
    surfaceContainerLowest: AppColors.ink900,
    surfaceContainerLow: AppColors.ink800,
    surfaceContainer: AppColors.ink700,
    surfaceContainerHigh: AppColors.navy800,
    surfaceContainerHighest: AppColors.navy700,
    surfaceTint: AppColors.navy200,
    onSurfaceVariant: AppColors.slate400,
    outline: AppColors.navy700,
    outlineVariant: AppColors.navy800,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.cream50Dark,
    onInverseSurface: AppColors.navy900,
    inversePrimary: AppColors.navy800,
  );

  // ---------------------------------------------------------------------------
  // ThemeData builder
  // ---------------------------------------------------------------------------

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final textTheme = AppTypography.textTheme(brightness);
    final semanticColors = brightness == Brightness.light
        ? AppSemanticColors.light
        : AppSemanticColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      extensions: <ThemeExtension<dynamic>>[semanticColors],

      // -- AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
        toolbarHeight: 64,
      ),

      // -- Filled buttons (primary CTAs)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.all(AppRadii.md),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      // -- Outlined buttons (secondary actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.all(AppRadii.md),
          ),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outline),
        ),
      ),

      // -- Text buttons (tertiary actions)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),

      // -- Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: AppRadii.all(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.all(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.all(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // -- Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.all(AppRadii.lg),
        ),
        color: scheme.surface,
        margin: EdgeInsets.zero,
      ),

      // -- Snackbars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.all(AppRadii.md),
        ),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),

      // -- Dialogs
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.all(AppRadii.lg),
        ),
        backgroundColor: scheme.surface,
        elevation: 4,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // -- Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outline,
      ),

      // -- Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.all(AppRadii.xs),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // -- Dividers
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // -- Progress
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
      ),

      // -- FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.all(AppRadii.pill),
        ),
      ),
    );
  }
}
