import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live snapshot of the `/config/global` Firestore document.
///
/// This is the same document the Vercel backend reads in
/// `api/_lib/quota.ts`. The client mirrors the fields it cares about
/// so quota meters and the developer-bypass logic don't need a
/// network round-trip every time the UI rebuilds.
///
/// Fields:
///
///  - `transcriptionEnabled`: kill switch. Currently informational on
///    the client (the server is the source of truth) but we read it
///    so we can grey out the FAB if it ever flips off.
///  - `developerUids`: caller UIDs that bypass every quota check.
///    Admin-only writable per `firestore.rules`. To add yourself, open
///    the Firebase Console -> Firestore -> `/config/global` and add a
///    `developerUids: [<your-uid>]` array field. Your UID is printed
///    on app launch when running in debug builds (see
///    `lib/main.dart`).
class GlobalConfigSnapshot {
  const GlobalConfigSnapshot({
    required this.transcriptionEnabled,
    required this.developerUids,
  });

  final bool transcriptionEnabled;
  final List<String> developerUids;

  static const empty = GlobalConfigSnapshot(
    transcriptionEnabled: true,
    developerUids: <String>[],
  );

  factory GlobalConfigSnapshot.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return empty;
    final rawDevs = data['developerUids'];
    final devs = <String>[];
    if (rawDevs is Iterable) {
      for (final v in rawDevs) {
        if (v is String && v.isNotEmpty) devs.add(v);
      }
    }
    return GlobalConfigSnapshot(
      // `transcriptionEnabled` defaults to true if absent or non-bool.
      transcriptionEnabled: data['transcriptionEnabled'] != false,
      developerUids: devs,
    );
  }
}

/// Live stream of `/config/global`. Yields `GlobalConfigSnapshot.empty`
/// while loading (kill switch off, no developers) so the rest of the
/// app can read it synchronously without null-checks on first frame.
final globalConfigProvider = StreamProvider<GlobalConfigSnapshot>((ref) async* {
  yield GlobalConfigSnapshot.empty;
  final doc = FirebaseFirestore.instance.doc('config/global');
  await for (final snap in doc.snapshots()) {
    yield GlobalConfigSnapshot.fromFirestore(snap.data());
  }
});
