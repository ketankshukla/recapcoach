import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';
import 'global_config.dart';

/// True when the **signed-in** user should bypass quota enforcement.
///
/// Purely dynamic and UID-based: the signed-in user's Firebase UID
/// must appear in the `/config/global.developerUids` array in
/// Firestore. The same document is read by the Vercel backend
/// (`api/_lib/quota.ts`), so the bypass is consistent across client
/// and server.
///
/// To add yourself as a developer, add your UID to the
/// `developerUids` array in Firestore at `/config/global`. Your UID
/// is printed on app launch in debug builds (see `lib/main.dart`).
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
