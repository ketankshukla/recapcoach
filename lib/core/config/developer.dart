import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';
import 'global_config.dart';

/// True when the **signed-in** user should bypass quota enforcement.
///
/// The check is purely UID-based: the current Firebase UID must appear
/// in the `/config/global.developerUids` array in Firestore.  The same
/// array is read by the Vercel backend (`api/_lib/quota.ts`), so the
/// bypass is consistent across client + server.
///
/// Earlier versions had a `kDebugMode` short-circuit that returned
/// `true` for ALL accounts in debug builds.  That was wrong: a second
/// Gmail account running under `flutter run` would also see
/// "DEV / unlimited" in the hero card despite having a free plan on
/// the server.  Now only UIDs in the Firestore allowlist (or the
/// server-side `DEVELOPER_UIDS` env var) get developer treatment.
///
/// The server is the ultimate source of truth: even if a tampered
/// client returned `true` from this provider, the backend would still
/// 429 on quota. So this provider is safe to consume in dialogs,
/// meters, and pre-flight checks without further authorization.
final isDeveloperProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final cfg = ref.watch(globalConfigProvider).value;
  if (cfg == null) return false;
  return cfg.developerUids.contains(user.uid);
});
