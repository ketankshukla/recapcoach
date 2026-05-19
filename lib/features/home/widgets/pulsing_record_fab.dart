import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Premium gradient "Record call" button with a slow heartbeat halo.
///
/// Replaces the stock `FloatingActionButton.extended` with a pill
/// rendered from an `amber600 → amber400` linear gradient and an
/// outer pulsing glow. The halo is implemented as a `BoxShadow`
/// whose alpha + blurRadius + spreadRadius are driven by an
/// `AnimationController` repeating every 1.6 seconds.
///
/// Visuals:
///
///  - Pill shape, 56 dp tall.
///  - Gradient fill: amber-600 (top-left) → amber-400 (bottom-right).
///  - White text + mic icon for maximum contrast.
///  - Heartbeat halo: amber-400 at 35% peak alpha, 14-32 dp blur,
///    1-6 dp spread. Subtle but present.
///  - Inner highlight: a 1 px white-with-low-alpha ring at the top
///    edge that catches the eye and gives a "polished metal" feel.
class PulsingRecordFab extends StatefulWidget {
  const PulsingRecordFab({
    super.key,
    required this.onPressed,
    this.label = 'Record call',
    this.icon = Icons.mic_rounded,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  State<PulsingRecordFab> createState() => _PulsingRecordFabState();
}

class _PulsingRecordFabState extends State<PulsingRecordFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final eased = Curves.easeOut.transform(t);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Heartbeat halo.
              BoxShadow(
                color: AppColors.amber400.withValues(alpha: 0.35 * (1 - eased)),
                blurRadius: 14 + 18 * eased,
                spreadRadius: 1 + 5 * eased,
              ),
              // Constant amber drop shadow under the pill so it feels
              // grounded even at the dim end of the heartbeat cycle.
              BoxShadow(
                color: AppColors.amber700.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.amber600,
                  AppColors.amber400,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
