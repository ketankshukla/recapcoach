import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Premium amber-on-navy mic disc that pulses with the live amplitude
/// feed coming off `AudioRecorderService`.
///
/// Layout:
///
///  - Outer halo  (0.45 * loudness alpha, 60-100 dp blur, 0-30 dp spread)
///  - Inner halo  (0.35 * loudness alpha, 24-48 dp blur, 0-12 dp spread)
///  - Mic disc    (140-200 dp, amber-600 → amber-400 gradient,
///                 1 px white-low-alpha hairline)
///  - Mic glyph   (white, 56 dp)
///
/// `amplitudeDb` is the dBFS value coming from the recorder. We clamp
/// it to [-60, 0] (silence to clipping) and remap to [0, 1] so the
/// halo and disc size respond linearly.
///
/// The disc is tweened over 120 ms so amplitude noise doesn't make it
/// jitter. Halos use the same animation so they breathe in sync.
class AmplitudePulseMic extends StatelessWidget {
  const AmplitudePulseMic({
    super.key,
    required this.amplitudeDb,
    this.icon = Icons.mic_rounded,
  });

  final double amplitudeDb;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // [-60, 0] -> [0, 1]
    final loudness = ((amplitudeDb.clamp(-60.0, 0.0)) + 60) / 60;
    final size = 140.0 + (loudness * 60.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amber600, AppColors.amber400],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          // Outer atmospheric bloom -- visible even at silence so the
          // disc never looks "cold".
          BoxShadow(
            color: AppColors.amber400.withValues(
              alpha: 0.20 + 0.25 * loudness,
            ),
            blurRadius: 60 + 40 * loudness,
            spreadRadius: 4 + 26 * loudness,
          ),
          // Inner punchy ring -- this is the part that visually
          // "pumps" with each spoken syllable.
          BoxShadow(
            color: AppColors.amber600.withValues(
              alpha: 0.20 + 0.30 * loudness,
            ),
            blurRadius: 24 + 24 * loudness,
            spreadRadius: 1 + 11 * loudness,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 56),
    );
  }
}
