import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

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
  StreamSubscription<Amplitude>? _ampSub;

  /// Returns false if mic permission was denied.
  Future<bool> start() async {
    if (!await _svc.hasPermission()) return false;
    await _svc.start();
    state = const RecordingState(
      isRecording: true,
      elapsedMs: 0,
      amplitudeDb: -160,
    );
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      state = state.copyWith(elapsedMs: state.elapsedMs + 200);
    });
    _ampSub = _svc.amplitudeStream().listen((a) {
      state = state.copyWith(amplitudeDb: a.current);
    });
    return true;
  }

  Future<RecordingResult?> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    final result = await _svc.stop();
    state = const RecordingState();
    return result;
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    await _svc.cancel();
    state = const RecordingState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    super.dispose();
  }
}

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingState>(
  (ref) => RecordingController(ref.watch(audioRecorderProvider)),
);
