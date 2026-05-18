import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';
import 'audio_recorder_service.dart';

final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  final svc = AudioRecorderService();
  ref.onDispose(svc.dispose);
  return svc;
});

class RecordingState {
  const RecordingState({
    this.isRecording = false,
    this.elapsedMs = 0,
    this.amplitudeDb = -160,
  });

  final bool isRecording;
  final int elapsedMs;
  final double amplitudeDb;

  RecordingState copyWith({
    bool? isRecording,
    int? elapsedMs,
    double? amplitudeDb,
  }) =>
      RecordingState(
        isRecording: isRecording ?? this.isRecording,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        amplitudeDb: amplitudeDb ?? this.amplitudeDb,
      );

  String get elapsedLabel {
    final total = Duration(milliseconds: elapsedMs);
    final m = total.inMinutes;
    final s = total.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class RecordingController extends StateNotifier<RecordingState> {
  RecordingController(this._svc) : super(const RecordingState());

  final AudioRecorderService _svc;
  Timer? _ticker;
  int _ampSamples = 0;

  /// Returns false if mic permission was denied.
  Future<bool> start() async {
    if (!await _svc.hasPermission()) return false;
    await _svc.start();
    _ampSamples = 0;
    state = const RecordingState(
      isRecording: true,
      elapsedMs: 0,
      amplitudeDb: -160,
    );
    // Single timer drives both elapsed-time and amplitude polling. We avoid
    // the `record` package's `onAmplitudeChanged` stream because it closes
    // permanently when the recorder stops, breaking amplitude on every
    // subsequent recording in the same app session.
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onTick(),
    );
    return true;
  }

  Future<void> _onTick() async {
    if (!state.isRecording) return;
    final nextElapsed = state.elapsedMs + 200;
    try {
      final amp = await _svc.getAmplitude();
      if (!state.isRecording) return; // stopped while awaiting
      // Log once per second so we can verify the mic is reporting amplitude.
      if (_ampSamples++ % 5 == 0) {
        logger.info('mic amp=${amp.current.toStringAsFixed(1)}dB '
            '(max=${amp.max.toStringAsFixed(1)}dB)');
      }
      state = state.copyWith(
        elapsedMs: nextElapsed,
        amplitudeDb: amp.current,
      );
    } catch (e) {
      // Amplitude polling can fail transiently; still advance the clock so
      // the UI doesn't appear frozen.
      logger.warning('getAmplitude failed: $e');
      state = state.copyWith(elapsedMs: nextElapsed);
    }
  }

  Future<RecordingResult?> stop() async {
    _ticker?.cancel();
    _ticker = null;
    final result = await _svc.stop();
    state = const RecordingState();
    return result;
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker = null;
    await _svc.cancel();
    state = const RecordingState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingState>(
  (ref) => RecordingController(ref.watch(audioRecorderProvider)),
);
