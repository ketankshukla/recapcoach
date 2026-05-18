import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingResult {
  RecordingResult({required this.filePath, required this.durationMs});
  final String filePath;
  final int durationMs;
}

/// Thin wrapper around `package:record` so the rest of the app deals only
/// in start/stop/cancel and gets a [RecordingResult] back.
///
/// Audio is encoded as **AAC-LC mono @ 16 kHz, 64 kbps** to:
///   - keep file sizes small (~480 KB / minute) for cheap upload;
///   - match what OpenAI Whisper accepts (m4a container, AAC content).
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> isRecording() => _recorder.isRecording();

  /// Begin recording into the app's documents directory.
  Future<void> start() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/recordings');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final filename = 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${folder.path}/$filename';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _startedAt = DateTime.now();
  }

  /// Stop and keep the file. Returns null if no recording was in progress.
  Future<RecordingResult?> stop() async {
    final path = await _recorder.stop();
    final start = _startedAt;
    _startedAt = null;
    if (path == null || start == null) return null;
    final durationMs = DateTime.now().difference(start).inMilliseconds;
    return RecordingResult(filePath: path, durationMs: durationMs);
  }

  /// Stop and delete the file (user pressed cancel during recording).
  Future<void> cancel() async {
    final path = await _recorder.stop();
    _startedAt = null;
    final p = path;
    if (p != null) {
      try {
        final f = File(p);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {
        // best-effort cleanup
      }
    }
  }

  /// One-shot amplitude read. Call from a periodic timer at the polling
  /// rate you want (e.g. every 200ms) instead of using the package's
  /// `onAmplitudeChanged` stream, which closes for good when the recorder
  /// stops and never re-emits on a subsequent recording with the same
  /// `AudioRecorder` instance.
  Future<Amplitude> getAmplitude() => _recorder.getAmplitude();

  void dispose() {
    _recorder.dispose();
  }
}
