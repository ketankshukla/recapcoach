import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../notes/note.dart';
import '../notes/note_providers.dart';
import 'recording_providers.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Auto-start when the screen opens. The user can stop or cancel.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
  }

  Future<void> _autoStart() async {
    if (_starting) return;
    _starting = true;
    final ok = await ref.read(recordingControllerProvider.notifier).start();
    if (!mounted) return;
    if (!ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Microphone access needed'),
          content: const Text(
            'RecapCoach needs permission to use your microphone to record calls. '
            'Please grant access in Settings and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    }
  }

  Future<void> _stopAndSave() async {
    final result = await ref.read(recordingControllerProvider.notifier).stop();
    if (!mounted) return;
    if (result == null) {
      context.pop();
      return;
    }
    if (result.durationMs < 1500) {
      // Too short to be useful — discard.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording too short. Try again.'),
        ),
      );
      context.pop();
      return;
    }
    final note = Note(
      id: const Uuid().v4(),
      audioFilePath: result.filePath,
      createdAt: DateTime.now(),
      durationMs: result.durationMs,
      isProcessing: false, // Will flip to true once we wire the backend.
    );
    await ref.read(noteRepositoryProvider).upsert(note);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _cancel() async {
    await ref.read(recordingControllerProvider.notifier).cancel();
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancel();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('Recording'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
            tooltip: 'Cancel',
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                _PulsingMic(amplitudeDb: state.amplitudeDb),
                const SizedBox(height: 32),
                Text(
                  state.elapsedLabel,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.isRecording ? 'Recording…' : 'Preparing…',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                _AmplitudeBar(amplitudeDb: state.amplitudeDb),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleButton(
                      icon: Icons.delete_outline,
                      label: 'Discard',
                      color: scheme.errorContainer,
                      iconColor: scheme.onErrorContainer,
                      onTap: _cancel,
                    ),
                    _CircleButton(
                      icon: Icons.stop_rounded,
                      label: 'Stop & save',
                      color: scheme.primary,
                      iconColor: scheme.onPrimary,
                      large: true,
                      onTap: _stopAndSave,
                    ),
                    const SizedBox(width: 64), // spacer for symmetry
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingMic extends StatelessWidget {
  const _PulsingMic({required this.amplitudeDb});

  final double amplitudeDb;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // amplitudeDb roughly ranges from -60 (quiet) to 0 (loud).
    final loudness = ((amplitudeDb.clamp(-60.0, 0.0)) + 60) / 60; // 0..1
    final size = 120.0 + (loudness * 60.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25 + loudness * 0.4),
            blurRadius: 32,
            spreadRadius: loudness * 12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.mic,
        size: 48,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}

class _AmplitudeBar extends StatelessWidget {
  const _AmplitudeBar({required this.amplitudeDb});

  final double amplitudeDb;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loudness = ((amplitudeDb.clamp(-60.0, 0.0)) + 60) / 60;
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (i) {
          final threshold = (i + 1) / 20;
          final lit = threshold <= loudness;
          final h = 8.0 + (math.sin(i * 0.6) + 1) * 8.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 6,
              height: h,
              decoration: BoxDecoration(
                color: lit
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final dim = large ? 88.0 : 64.0;
    final iconSize = large ? 40.0 : 28.0;
    return Column(
      children: [
        InkResponse(
          onTap: onTap,
          radius: dim,
          child: Container(
            width: dim,
            height: dim,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
