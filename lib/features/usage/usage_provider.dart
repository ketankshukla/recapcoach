import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/developer.dart';
import '../auth/auth_providers.dart';
import '../notes/note_providers.dart';
import '../paywall/entitlement_provider.dart';
import 'usage.dart';

/// `YYYY-MM` UTC key. Must match `currentMonthKey()` in `api/_lib/limits.ts`.
String currentUtcMonthKey([DateTime? now]) {
  final n = (now ?? DateTime.now()).toUtc();
  final y = n.year.toString().padLeft(4, '0');
  final m = n.month.toString().padLeft(2, '0');
  return '$y-$m';
}

/// Live stream of the signed-in user's monthly transcription usage.
///
/// Emits an `UsageSnapshot.empty(...)` while loading or when the user is
/// signed out / has no usage doc yet. The document is written by the backend
/// only; clients have read-only access via firestore.rules.
///
/// Developer accounts (debug builds OR UID listed in
/// `/config/global.developerUids`) get the same snapshot but with
/// `isDeveloper = true`, which makes every cap-related getter
/// (`isAtCap`, `worstProgress`, `secondsProgress`,
/// `recordingsProgress`) effectively a no-op. The server applies the
/// same bypass.
final monthlyUsageProvider = StreamProvider<UsageSnapshot>((ref) async* {
  final user = ref.watch(currentUserProvider);
  final isPro = ref.watch(entitlementProvider).value ?? false;
  final isDeveloper = ref.watch(isDeveloperProvider);
  final plan = isPro ? 'pro' : 'free';
  final monthKey = currentUtcMonthKey();

  if (user == null) {
    yield UsageSnapshot.empty(
      plan: plan,
      monthKey: monthKey,
      isDeveloper: isDeveloper,
    );
    return;
  }

  final doc = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('usage')
      .doc(monthKey);

  yield UsageSnapshot.empty(
    plan: plan,
    monthKey: monthKey,
    isDeveloper: isDeveloper,
  );

  await for (final snap in doc.snapshots()) {
    yield UsageSnapshot.fromFirestore(
      plan: plan,
      monthKey: monthKey,
      data: snap.data(),
      isDeveloper: isDeveloper,
    );
  }
});

/// Real-time usage for the hero card.
///
/// **Developer accounts** — usage is computed from local notes so
/// the hero updates instantly on every add / delete. Developers have
/// no caps, so showing the live local count is the right UX.
///
/// **Non-developer accounts** — usage comes from the server-side
/// Firestore counters, which are incremented on every recording and
/// **never decremented** on delete. This prevents users from gaming
/// the quota by deleting and re-recording. The hero accurately
/// reflects cumulative usage against the monthly cap.
///
/// Quota enforcement (pre-flight cap check on the record screen)
/// always uses [monthlyUsageProvider] directly.
final liveUsageProvider = Provider<UsageSnapshot?>((ref) {
  final serverUsage = ref.watch(monthlyUsageProvider).value;
  if (serverUsage == null) return null;

  // Non-developers: always show server-side cumulative counters.
  // These never decrease, so the hero correctly reflects cap usage
  // even after the user deletes recordings.
  if (!serverUsage.isDeveloper) return serverUsage;

  // Developers: compute from local notes for instant feedback.
  final notes = ref.watch(notesStreamProvider).value;
  if (notes == null) return serverUsage;

  final now = DateTime.now().toUtc();
  final thisMonth = notes.where((n) {
    final c = n.createdAt.toUtc();
    return c.year == now.year && c.month == now.month;
  }).toList();

  final localCount = thisMonth.length;
  final localSeconds =
      thisMonth.fold<int>(0, (acc, n) => acc + (n.durationMs ~/ 1000));

  return UsageSnapshot(
    plan: serverUsage.plan,
    monthKey: serverUsage.monthKey,
    usedSeconds: localSeconds,
    usedRecordings: localCount,
    limitSeconds: serverUsage.limitSeconds,
    limitRecordings: serverUsage.limitRecordings,
    limitPerRecordingSeconds: serverUsage.limitPerRecordingSeconds,
    isDeveloper: serverUsage.isDeveloper,
  );
});
