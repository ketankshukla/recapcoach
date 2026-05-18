# 06 — Cloud sync

> **Commit:** `3c5a817` *(Cloud sync: notes (text) follow user across devices via Firestore)*

The problem this phase solved: **a user who uninstalls the app and reinstalls it (or installs on a new device) lost all of their notes**, because Hive lives in the app's private data directory which Android wipes on uninstall.

## What's in scope vs deferred

| In scope (shipped) | Deferred to Pro feature |
|---|---|
| Note **text** (transcript, summary, action items, metadata) sync to Firestore | Audio file upload to Firebase Storage |
| Per-user data isolation via Firestore security rules | Selective sync over Wi-Fi only |
| One-shot pull-down sync on every sign-in | Real-time multi-device live sync |
| Catch-up push for notes recorded while offline / signed out | Conflict resolution UI |

The shipping decision was driven by cost + complexity. Audio files are ~30× the size of text (a 10-min call is ~5 MB of audio vs. ~5 KB of text). Auto-uploading every recording over cellular is bad UX. Better positioning: **"never lose your recordings"** becomes a clear Pro-tier upgrade reason later.

## Architecture

```
+--------------------+          +--------------------+
|        UI          | <------- |  Hive (notes_v1)   |  <-- single source of truth for display
+--------------------+   read   +--------------------+
                                       ^  ^
                                       |  |
                            write-through (sync)
                                       |  |
+----------------------+               |  |
| NoteRepository       | ---> upsert ---  |
| (.upsert / .delete)  | ---> delete -----+
+----------+-----------+
           |
           | best-effort, async, may fail silently
           v
+----------------------+               +-----------------------+
| NoteCloudRepository  |  <---------   |  Firestore            |
| (users/{uid}/notes)  |               |  (per-user collection)|
+----------+-----------+               +-----------------------+
           ^
           | initial pull + catch-up push on sign-in
           |
+----------+-----------+
| NoteSyncService      |  <-- listens to authStateProvider via
| .syncForUser(uid)    |      noteSyncBootstrapProvider
+----------------------+
```

## Files added

```
lib/features/notes/note_cloud_repository.dart   Firestore CRUD
lib/features/notes/note_sync_service.dart       Pull + merge + catch-up push logic
firestore.rules                                 Per-user isolation rules
```

## Files modified

```
lib/features/notes/note_repository.dart   Added optional cloud write-through
lib/features/notes/note_providers.dart    New providers + sync bootstrap
lib/main.dart                             Wires cloud repo + uid getter
lib/app.dart                              Keeps the sync bootstrap alive
```

## The data model

**Firestore path:** `users/{uid}/notes/{noteId}`

**Document shape:**

```json
{
  "id": "uuid-v4",
  "audioFilePath": "/data/.../recordings/rec_1755000000.m4a",
  "createdAt": "2026-05-18T01:12:34.567Z",
  "durationMs": 12345,
  "title": null,
  "transcript": "Full transcript text...",
  "summary": "Two sentence summary...",
  "actionItems": ["...", "..."],
  "isProcessing": false,
  "processingError": null,
  "updatedAt": "<server timestamp>"
}
```

Note that `audioFilePath` syncs to the cloud but is meaningless on a different device — it points to a path under the original device's data directory. After a fresh install, the file at that path doesn't exist, and the `NotePlayer` widget gracefully shows *"Audio file not found"*.

## The sync algorithm

`NoteSyncService.syncForUser(uid)` does the following on every sign-in:

```
1. If the last UID we synced for differs from `uid`:
     -> someone else used this phone
     -> wipe the local Hive cache (`clearAllLocalOnly()`)
     -> remember the new UID in SharedPreferences

2. Fetch ALL cloud notes for `uid`:
     `users/{uid}/notes`.get() -> List<Note>

3. For each cloud note:
     -> upsert into Hive (cloud wins; this is a no-op for unchanged notes)
     -> count `pulled++` if it wasn't in Hive before

4. For each local Hive note whose ID isn't in the cloud:
     -> push to Firestore (catch-up for notes recorded while offline / signed out)
     -> count `pushed++`

5. Persist `uid` as the "last synced" UID.
```

This is **last-write-wins, cloud-canonical**. There's no conflict resolution — if both devices edit the same note, the latest cloud write survives.

## The bootstrap: triggering sync at the right time

Sync should run when (and only when) Firebase Auth confirms a signed-in user. Implementation in `note_providers.dart`:

```dart
final noteSyncBootstrapProvider = Provider<void>((ref) {
  final syncedUids = <String>{};
  ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
    final user = next.value;
    if (user == null) return;
    final uid = user.uid;
    if (syncedUids.contains(uid)) return; // already synced this session
    syncedUids.add(uid);
    final svc = ref.read(noteSyncServiceProvider);
    svc.syncForUser(uid).then(...).catchError(...);
  }, fireImmediately: true);
});
```

`fireImmediately: true` ensures we sync even if auth had already settled before the listener was registered. The `syncedUids` set makes the bootstrap idempotent within a single app session.

`app.dart` keeps the bootstrap alive for the lifetime of the app:

```dart
class RecapCoachApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(noteSyncBootstrapProvider);
    // ...
  }
}
```

Without that `watch`, Riverpod would garbage-collect the unused provider and the listener would never fire.

## Write-through pattern

`NoteRepository.upsert(note)` was extended to mirror writes to the cloud:

```dart
Future<void> upsert(Note n) async {
  await _box.put(n.id, n.toJsonString());        // 1. Hive (sync, immediate)
  final cloud = _cloud;
  final uid = _uidGetter?.call();
  if (cloud != null && uid != null) {
    try {
      await cloud.upsert(uid, n);                // 2. Firestore (async, best-effort)
    } catch (e) {
      logger.warning('Cloud upsert failed for note ${n.id}: $e');
      // Hive write succeeded - UI is still consistent. Sync will catch up next time.
    }
  }
}
```

A few things to notice:

- **Hive write always happens first** — the UI never blocks on the network
- **Cloud failures are logged, never thrown** — a flaky network doesn't break the app
- **The next sign-in's catch-up push** will mop up any local-only notes that failed to upload

The same pattern applies to `delete()`. There's also a private `upsertLocalOnly()` used by the sync service to **avoid recursive cloud writes** when pulling notes down.

## Firestore security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

Every other path is denied by default. No cross-user reads or writes are possible.

## Wiring up `main.dart`

The `NoteRepository` is constructed with a closure that reads the current Firebase user lazily:

```dart
final noteCloudRepo = NoteCloudRepository();
final noteRepo = await NoteRepository.open(
  cloud: noteCloudRepo,
  uidGetter: () => FirebaseAuth.instance.currentUser?.uid,
);
```

`uidGetter` is a closure rather than a snapshotted value because:

- The repo is created **before** the user signs in
- The current user changes over time (sign-in, sign-out, account switch)
- We want every call to `upsert/delete` to use the **current** uid

## Verification flow

The full test that proved the system works:

1. **Record 2 notes** on the original install. Wait for them to process.
2. **Confirm Firestore has 2 documents** under `users/{uid}/notes/` with full transcript/summary fields.
3. **Uninstall the APK** (long-press → Uninstall on the device).
4. **Reinstall** via `flutter run`. Walk through onboarding + sign-in with the same Google account.
5. **Home screen populates** with the 2 historical notes within ~1 second of landing.
6. **Tap a resurrected note** → summary, action items, and transcript intact.
7. **Audio player shows "Audio file not found"** — expected; audio cloud sync is deferred.

This was confirmed working end-to-end on a real Samsung Galaxy device.

## Privacy implications

User data (call transcripts and summaries) now leaves the device permanently and lives in Firebase. This means:

- Privacy policy must disclose Firebase as a sub-processor
- Account deletion (`AuthRepository.deleteAccount()`) needs to also nuke `users/{uid}/**` — currently does **not**. Tracked as a Roadmap item.
- Right-to-export (GDPR) needs to be a feature eventually — currently not built

## Cost back-of-envelope

Firestore free tier:

- 1 GiB stored
- 50K reads / day
- 20K writes / day
- 20K deletes / day

A user generates roughly 5 KB of text per call. 200 calls/user = 1 MB. **1 GiB free tier = ~1,000 users worth of data.**

Per-call reads/writes:

- 1 write on note creation
- 1 write on transcription completion
- 1 read on sign-in sync

Even with 10,000 daily active users syncing twice each, we're at 20K reads/day = at the free tier limit. Past that, $0.06 per 100K reads — negligible.

## Next chapter

[07 — Architecture](07-architecture.md) — putting it all together: full data-flow diagram, layer responsibilities, and the design philosophy.
