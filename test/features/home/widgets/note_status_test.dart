// Unit tests for the `NoteStatusX` extension that maps a `Note` to a
// user-facing `NoteStatus`. Pure-logic, no widget infra.
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/features/home/widgets/note_status.dart';
import 'package:recapcoach/features/notes/note.dart';

Note _baseNote({
  bool isProcessing = false,
  String? processingError,
  String? transcript,
  String? summary,
}) {
  return Note(
    id: 'n1',
    audioFilePath: '/tmp/x.aac',
    createdAt: DateTime.utc(2026, 5, 18, 12),
    durationMs: 60000,
    isProcessing: isProcessing,
    processingError: processingError,
    transcript: transcript,
    summary: summary,
  );
}

void main() {
  group('NoteStatusX.status', () {
    test('Returns `failed` when processingError is set', () {
      final n = _baseNote(processingError: 'Whisper failed');
      expect(n.status, NoteStatus.failed);
    });

    test('Returns `processing` when isProcessing is true and no error', () {
      final n = _baseNote(isProcessing: true);
      expect(n.status, NoteStatus.processing);
    });

    test('Returns `done` when summary is non-empty', () {
      final n = _baseNote(summary: 'Discussed Q3 launch.');
      expect(n.status, NoteStatus.done);
    });

    test('Returns `done` when only transcript is set (no summary yet)', () {
      final n = _baseNote(transcript: 'Hello world');
      expect(n.status, NoteStatus.done);
    });

    test('Returns `pending` when nothing is set', () {
      final n = _baseNote();
      expect(n.status, NoteStatus.pending);
    });

    test('processingError takes precedence over isProcessing', () {
      // Edge case: the backend errored after we flagged the note as
      // in-flight. The user sees Failed, not Transcribing.
      final n = _baseNote(isProcessing: true, processingError: 'timeout');
      expect(n.status, NoteStatus.failed);
    });

    test('Empty-string summary is not treated as `done`', () {
      // Defensive: Firestore round-trips occasionally produce empty
      // strings when a doc lands mid-write. We treat that as pending,
      // not done.
      final n = _baseNote(summary: '');
      expect(n.status, NoteStatus.pending);
    });
  });
}
