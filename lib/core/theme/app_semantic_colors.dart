import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-specific semantic colors exposed via a [ThemeExtension] so widget
/// code can read them off `Theme.of(context).extension<AppSemanticColors>()`
/// instead of importing [AppColors] directly.
///
/// Why a [ThemeExtension] instead of a singleton?
/// - These values legitimately differ between light and dark mode.
/// - It plays nicely with `Theme.of(context)` so widgets re-build when
///   the theme changes.
/// - It enables Flutter's `lerp` between themes for animated transitions.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.usageMeterLow,
    required this.usageMeterMid,
    required this.usageMeterHigh,
    required this.usageMeterTrack,
    required this.recordingPulse,
    required this.proBadge,
    required this.proBadgeOn,
    required this.shimmer,
  });

  /// Color for the usage meter when used < 50% of cap. (Sage / calm.)
  final Color usageMeterLow;

  /// Color for the usage meter when 50%-80% of cap. (Amber / approaching.)
  final Color usageMeterMid;

  /// Color for the usage meter when >= 80% of cap. (Warm red / at-cap.)
  final Color usageMeterHigh;

  /// Background of the usage meter track behind the progress fill.
  final Color usageMeterTrack;

  /// Color used for the recording-screen pulsing indicator + waveform.
  final Color recordingPulse;

  /// Background of the "PRO" badge on the home screen and paywall tiles.
  final Color proBadge;

  /// Foreground (text/icon) color used on top of [proBadge].
  final Color proBadgeOn;

  /// Shimmer base color for skeleton loading states.
  final Color shimmer;

  /// Light-mode preset. Used by [AppTheme.light].
  static const AppSemanticColors light = AppSemanticColors(
    usageMeterLow: AppColors.sage500,
    usageMeterMid: AppColors.amber600,
    usageMeterHigh: AppColors.error600,
    usageMeterTrack: AppColors.cream200,
    recordingPulse: AppColors.amber600,
    proBadge: AppColors.navy800,
    proBadgeOn: AppColors.amber400,
    shimmer: AppColors.cream200,
  );

  /// Dark-mode preset. Used by [AppTheme.dark].
  static const AppSemanticColors dark = AppSemanticColors(
    usageMeterLow: AppColors.sage300,
    usageMeterMid: AppColors.amber400,
    usageMeterHigh: AppColors.error300,
    usageMeterTrack: AppColors.ink700,
    recordingPulse: AppColors.amber400,
    proBadge: AppColors.amber400,
    proBadgeOn: AppColors.navy900,
    shimmer: AppColors.ink700,
  );

  @override
  AppSemanticColors copyWith({
    Color? usageMeterLow,
    Color? usageMeterMid,
    Color? usageMeterHigh,
    Color? usageMeterTrack,
    Color? recordingPulse,
    Color? proBadge,
    Color? proBadgeOn,
    Color? shimmer,
  }) {
    return AppSemanticColors(
      usageMeterLow: usageMeterLow ?? this.usageMeterLow,
      usageMeterMid: usageMeterMid ?? this.usageMeterMid,
      usageMeterHigh: usageMeterHigh ?? this.usageMeterHigh,
      usageMeterTrack: usageMeterTrack ?? this.usageMeterTrack,
      recordingPulse: recordingPulse ?? this.recordingPulse,
      proBadge: proBadge ?? this.proBadge,
      proBadgeOn: proBadgeOn ?? this.proBadgeOn,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      usageMeterLow: Color.lerp(usageMeterLow, other.usageMeterLow, t)!,
      usageMeterMid: Color.lerp(usageMeterMid, other.usageMeterMid, t)!,
      usageMeterHigh: Color.lerp(usageMeterHigh, other.usageMeterHigh, t)!,
      usageMeterTrack: Color.lerp(usageMeterTrack, other.usageMeterTrack, t)!,
      recordingPulse: Color.lerp(recordingPulse, other.recordingPulse, t)!,
      proBadge: Color.lerp(proBadge, other.proBadge, t)!,
      proBadgeOn: Color.lerp(proBadgeOn, other.proBadgeOn, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }

  /// Pick the usage-meter color for a given fractional progress in [0, 1].
  ///
  /// - `< 0.5` -> [usageMeterLow]
  /// - `0.5 <= p < 0.8` -> [usageMeterMid]
  /// - `>= 0.8` -> [usageMeterHigh]
  ///
  /// This is the single source of truth used by both the home-screen
  /// meter and the record-screen quota indicator so the two stay in
  /// lockstep.
  Color usageMeterColorFor(double progress) {
    if (progress >= 0.8) return usageMeterHigh;
    if (progress >= 0.5) return usageMeterMid;
    return usageMeterLow;
  }
}
