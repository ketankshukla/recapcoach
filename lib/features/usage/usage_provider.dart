import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/developer.dart';
import '../auth/auth_providers.dart';
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
