/// Snapshot of a user's monthly transcription usage as read from Firestore
/// (`/users/{uid}/usage/{YYYY-MM}`) plus the limits that apply to their plan.
///
/// The limits mirror the server-side defaults in `api/_lib/limits.ts` so the
/// UI can show "X / Y minutes left" without making a network round-trip.
/// The server is the source of truth -- these client-side numbers are only
/// used to render meters and pre-flight checks.
class UsageSnapshot {
  const UsageSnapshot({
    required this.plan,
    required this.monthKey,
    required this.usedSeconds,
    required this.usedRecordings,
    required this.limitSeconds,
    required this.limitRecordings,
    required this.limitPerRecordingSeconds,
  });

  /// 'free' or 'pro'.
  final String plan;

  /// `YYYY-MM` UTC key the counters reset on.
  final String monthKey;

  final int usedSeconds;
  final int usedRecordings;

  final int limitSeconds;
  final int limitRecordings;
  final int limitPerRecordingSeconds;

  /// Free plan defaults — must stay in sync with `api/_lib/limits.ts`.
  static const freeLimitSeconds = 900;        // 15 min
  static const freeLimitRecordings = 5;
  static const freeLimitPerRecordingSeconds = 180; // 3 min

  /// Pro plan defaults — must stay in sync with `api/_lib/limits.ts`.
  static const proLimitSeconds = 28800;       // 8 hr
  static const proLimitRecordings = 100;
  static const proLimitPerRecordingSeconds = 1200; // 20 min

  factory UsageSnapshot.empty({
    required String plan,
    required String monthKey,
  }) {
    final isPro = plan == 'pro';
    return UsageSnapshot(
      plan: plan,
      monthKey: monthKey,
      usedSeconds: 0,
      usedRecordings: 0,
      limitSeconds: isPro ? proLimitSeconds : freeLimitSeconds,
      limitRecordings: isPro ? proLimitRecordings : freeLimitRecordings,
      limitPerRecordingSeconds:
          isPro ? proLimitPerRecordingSeconds : freeLimitPerRecordingSeconds,
    );
  }

  factory UsageSnapshot.fromFirestore({
    required String plan,
    required String monthKey,
    required Map<String, dynamic>? data,
  }) {
    final isPro = plan == 'pro';
    return UsageSnapshot(
      plan: plan,
      monthKey: monthKey,
      usedSeconds: (data?['transcriptionSeconds'] as num?)?.toInt() ?? 0,
      usedRecordings: (data?['recordingsCount'] as num?)?.toInt() ?? 0,
      limitSeconds: isPro ? proLimitSeconds : freeLimitSeconds,
      limitRecordings: isPro ? proLimitRecordings : freeLimitRecordings,
      limitPerRecordingSeconds:
          isPro ? proLimitPerRecordingSeconds : freeLimitPerRecordingSeconds,
    );
  }

  /// 0.0 .. 1.0 progress against the monthly seconds cap (clamped).
  double get secondsProgress {
    if (limitSeconds <= 0) return 0;
    final p = usedSeconds / limitSeconds;
    return p.isNaN ? 0 : p.clamp(0.0, 1.0);
  }

  /// 0.0 .. 1.0 progress against the monthly recordings cap (clamped).
  double get recordingsProgress {
    if (limitRecordings <= 0) return 0;
    final p = usedRecordings / limitRecordings;
    return p.isNaN ? 0 : p.clamp(0.0, 1.0);
  }

  /// True when either the minute cap or the recording-count cap is exhausted.
  bool get isAtCap =>
      usedSeconds >= limitSeconds || usedRecordings >= limitRecordings;

  /// Worst-case "highest of the two meters" progress, for a single meter UI.
  double get worstProgress =>
      secondsProgress > recordingsProgress ? secondsProgress : recordingsProgress;

  int get remainingSeconds =>
      (limitSeconds - usedSeconds).clamp(0, limitSeconds);
  int get remainingRecordings =>
      (limitRecordings - usedRecordings).clamp(0, limitRecordings);

  String get remainingMinutesLabel {
    final s = remainingSeconds;
    if (s >= 3600) {
      final h = s ~/ 3600;
      final m = (s % 3600) ~/ 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    final m = s ~/ 60;
    final sec = s % 60;
    if (m == 0) return '${sec}s';
    return sec == 0 ? '${m}m' : '${m}m ${sec}s';
  }
}
