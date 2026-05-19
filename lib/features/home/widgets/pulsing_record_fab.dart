import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Floating action button that gently pulses to draw the user's eye to
/// "Record call".
///
/// The pulse is implemented as an outer colored shadow that grows from
/// a tight, opaque-ish glow to a wide, faded one over 1.6 seconds, then
/// loops. We deliberately keep the amplitude small (a few extra pixels
/// of blur, ~30% peak alpha) so it reads as an inviting heartbeat
/// rather than a jittery distraction.
///
/// The animation is driven by an [AnimationController] that we dispose
/// in [dispose]; widget tests can verify the controller is set up via
/// `tester.pump(Duration)`.
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
    final pulseColor = Theme.of(context).extension<AppSemanticColors>()!.recordingPulse;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        // t ∈ [0,1]: at t=0 the pulse is tight + visible, by t=1 it's
        // wide + transparent. Curves.easeOut feels like a heartbeat;
        // a strict linear t looks robotic.
        final eased = Curves.easeOut.transform(t);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: pulseColor.withValues(alpha: 0.32 * (1 - eased)),
                blurRadius: 12 + 18 * eased,
                spreadRadius: 1 + 4 * eased,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon),
        label: Text(widget.label),
      ),
    );
  }
}
