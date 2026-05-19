import '../../notes/note.dart';

/// User-facing lifecycle states for a [Note]. The UI displays these via
/// the `NoteStatusChip` widget; mapping is centralised here so we don't
/// re-derive it in every render path.
enum NoteStatus {
  /// The note was just created and is currently being transcribed +
  /// summarised by the backend. Shows a spinner / hourglass.
  processing,

  /// Transcription succeeded and we have at least a transcript or
  /// summary. The default "happy path" state.
  done,

  /// The transcription pipeline failed. The error message is exposed
  /// via [Note.processingError]. The UI shows a "Failed" chip and (in a
  /// later phase) lets the user retry.
  failed,

  /// Audio was captured but the transcription request hasn't been kicked
  /// off yet (e.g. the user paused recording on a network failure and
  /// has not retried). Rare but possible.
  pending,
}

/// Maps a [Note] to its [NoteStatus] using the same rules the rest of
/// the app uses to drive UI affordances.
extension NoteStatusX on Note {
  NoteStatus get status {
    if (processingError != null && processingError!.isNotEmpty) {
      return NoteStatus.failed;
    }
    if (isProcessing) return NoteStatus.processing;
    final hasTranscript = transcript != null && transcript!.isNotEmpty;
    final hasSummary = summary != null && summary!.isNotEmpty;
    if (hasTranscript || hasSummary) return NoteStatus.done;
    return NoteStatus.pending;
  }
}
