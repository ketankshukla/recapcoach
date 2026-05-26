import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';
import 'env.dart';
import 'global_config.dart';

/// True when the **signed-in** user should bypass quota enforcement.
///
/// Three sources are checked (first match wins):
///
///  1. **`--dart-define=DEVELOPER_UID=<uid>`** — compiled into the
///     binary via `Env.developerUid`. Only the UID that matches gets
///     developer mode; other accounts signed in during `flutter run`
///     are unaffected.
///
///  2. **Firestore `/config/global.developerUids`** — for production
///     builds or when the dart-define isn't set. Admin-only writable.
///
///  3. **Server-side `DEVELOPER_UIDS` env var** — the Vercel backend
///     (`api/_lib/quota.ts`) merges this with the Firestore list, so
///     the server bypass works even without touching Firestore.
///
/// The server is the ultimate source of truth: even if a tampered
/// client returned `true` from this provider, the backend would still
/// 429 on quota. So this provider is safe to consume in dialogs,
/// meters, and pre-flight checks without further authorization.
final isDeveloperProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final uid = user.uid;

  // 1. Compile-time dart-define match (only YOUR UID, not everyone).
  if (Env.hasDeveloperUid && uid == Env.developerUid) return true;

  // 2. Firestore allowlist.
  final cfg = ref.watch(globalConfigProvider).value;
  if (cfg != null && cfg.developerUids.contains(uid)) return true;

  return false;
});
