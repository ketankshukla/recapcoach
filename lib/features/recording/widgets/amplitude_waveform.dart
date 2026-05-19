import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 20-bar amplitude waveform.
///
/// Lit bars use the amber gradient that matches the rest of the
/// glass-themed surfaces; unlit bars use a low-alpha white in dark
/// mode and a low-alpha slate in light mode. Each bar's MAX height is
/// driven by a phase-shifted sin so the row reads as a stylised
/// waveform even before the user starts talking.
///
/// `amplitudeDb` is clamped to [-60, 0] (silence to clipping) and
/// remapped to [0, 1] -- the result is the fraction of bars (left to
/// right) that "light up".
class AmplitudeWaveform extends StatelessWidget {
  const AmplitudeWaveform({
    super.key,
    required this.amplitudeDb,
    this.barCount = 20,
    this.height = 32,
  });

  final double amplitudeDb;
  final int barCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loudness = ((amplitudeDb.clamp(-60.0, 0.0)) + 60) / 60;
    final unlit = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.slate300.withValues(alpha: 0.55);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final threshold = (i + 1) / barCount;
          final lit = threshold <= loudness;
          final h = (height * 0.30) + (math.sin(i * 0.6) + 1) * (height * 0.30);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 6,
              height: h,
              decoration: BoxDecoration(
                gradient: lit
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.amber400, AppColors.amber600],
                      )
                    : null,
                color: lit ? null : unlit,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
