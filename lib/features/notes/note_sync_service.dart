import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/logger.dart';
import 'note_cloud_repository.dart';
import 'note_repository.dart';

/// Pulls cloud notes into the local Hive cache and pushes any local-only
/// notes back up. Called once per session when a user signs in.
///
/// Algorithm (last-write-wins, cloud-canonical):
///   1. If signed-in UID differs from the last UID we synced for, wipe the
///      local cache first (someone else used this phone).
///   2. Fetch all cloud notes.
///   3. For each cloud note: upsert into local Hive (cloud wins).
///   4. For each local note not in cloud: push it up (catches up writes that
///      happened while offline).
class NoteSyncService {
  NoteSyncService({
    required NoteRepository local,
    required NoteCloudRepository cloud,
    required SharedPreferences prefs,
  })  : _local = local,
        _cloud = cloud,
        _prefs = prefs;

  final NoteRepository _local;
  final NoteCloudRepository _cloud;
  final SharedPreferences _prefs;

  static const _lastUidKey = 'note_sync_last_uid_v1';

  /// Returns the number of cloud notes pulled into local storage. Throws on
  /// fatal Firestore errors (e.g. permission denied).
  Future<int> syncForUser(String uid) async {
    final lastUid = _prefs.getString(_lastUidKey);
    if (lastUid != null && lastUid != uid) {
      logger.info(
        'NoteSyncService: UID changed ($lastUid -> $uid). '
        'Clearing local cache before sync.',
      );
      await _local.clearAllLocalOnly();
    }

    logger.info('NoteSyncService: pulling cloud notes for uid=$uid');
    final cloudNotes = await _cloud.all(uid);
    final localById = {for (final n in _local.all()) n.id: n};

    var pulled = 0;
    for (final cn in cloudNotes) {
      // Cloud always wins. This is a no-op for notes that match exactly.
      await _local.upsertLocalOnly(cn);
      if (!localById.containsKey(cn.id)) pulled++;
    }

    final cloudIds = cloudNotes.map((n) => n.id).toSet();
    var pushed = 0;
    for (final ln in _local.all()) {
      if (!cloudIds.contains(ln.id)) {
        try {
          await _cloud.upsert(uid, ln);
          pushed++;
        } catch (e, st) {
          logger.warning('Push of local-only note ${ln.id} failed: $e\n$st');
        }
      }
    }

    await _prefs.setString(_lastUidKey, uid);
    logger.info(
      'NoteSyncService: sync complete. pulled=$pulled, pushed=$pushed.',
    );
    return pulled;
  }
}
