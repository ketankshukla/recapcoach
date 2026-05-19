import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';
import 'global_config.dart';

/// True when the current user should bypass quota enforcement.
///
/// Two independent escape hatches:
///
///  1. **Debug builds (`kDebugMode`)** — every debug build is treated
///     as developer mode. This unblocks `flutter run` workflows
///     without any Firestore config. Release builds (`flutter build
///     appbundle --release`) ignore this branch entirely.
///
///  2. **Production allowlist** — for testing release builds against
///     the production backend, add the caller's Firebase UID to
///     `/config/global.developerUids` in Firestore. The same array is
///     read by the Vercel backend (`api/_lib/quota.ts`), so the
///     bypass is consistent across client + server.
///
/// The server is the ultimate source of truth: even if a tampered
/// client returned `true` from this provider, the backend would still
/// 429 on quota. So this provider is safe to consume in dialogs,
/// meters, and pre-flight checks without further authorization.
final isDeveloperProvider = Provider<bool>((ref) {
  if (kDebugMode) return true;
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final cfg = ref.watch(globalConfigProvider).value;
  if (cfg == null) return false;
  return cfg.developerUids.contains(user.uid);
});
