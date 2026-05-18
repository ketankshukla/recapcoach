import 'dart:convert';

/// Local representation of a recorded note. Persisted as JSON in Hive.
///
/// Lifecycle:
///   1. User finishes recording -> Note is created with `isProcessing = true`,
///      transcript/summary/actionItems = null.
///   2. Backend (`/transcribe` + `/summarize`) returns -> Note is updated via
///      [copyWith] with `isProcessing = false` and the populated AI fields.
///   3. If the backend fails, [processingError] is set.
class Note {
  Note({
    required this.id,
    required this.audioFilePath,
    required this.createdAt,
    required this.durationMs,
    this.title,
    this.transcript,
    this.summary,
    this.actionItems,
    this.isProcessing = false,
    this.processingError,
  });

  final String id;
  final String audioFilePath;
  final DateTime createdAt;
  final int durationMs;
  final String? title;
  final String? transcript;
  final String? summary;
  final List<String>? actionItems;
  final bool isProcessing;
  final String? processingError;

  Note copyWith({
    String? title,
    String? transcript,
    String? summary,
    List<String>? actionItems,
    bool? isProcessing,
    String? processingError,
    bool clearError = false,
  }) {
    return Note(
      id: id,
      audioFilePath: audioFilePath,
      createdAt: createdAt,
      durationMs: durationMs,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      actionItems: actionItems ?? this.actionItems,
      isProcessing: isProcessing ?? this.isProcessing,
      processingError:
          clearError ? null : (processingError ?? this.processingError),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'audioFilePath': audioFilePath,
        'createdAt': createdAt.toIso8601String(),
        'durationMs': durationMs,
        'title': title,
        'transcript': transcript,
        'summary': summary,
        'actionItems': actionItems,
        'isProcessing': isProcessing,
        'processingError': processingError,
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        audioFilePath: m['audioFilePath'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        durationMs: m['durationMs'] as int,
        title: m['title'] as String?,
        transcript: m['transcript'] as String?,
        summary: m['summary'] as String?,
        actionItems: (m['actionItems'] as List?)?.cast<String>(),
        isProcessing: m['isProcessing'] as bool? ?? false,
        processingError: m['processingError'] as String?,
      );

  String toJsonString() => jsonEncode(toMap());

  factory Note.fromJsonString(String s) =>
      Note.fromMap(jsonDecode(s) as Map<String, dynamic>);

  /// User-visible title. Falls back to the timestamp.
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!;
    final d = createdAt;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} \u2022 $hh:$mm';
  }

  Duration get duration => Duration(milliseconds: durationMs);

  /// "1:23" or "12:34" formatted from the recording's duration.
  String get durationLabel {
    final d = duration;
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
