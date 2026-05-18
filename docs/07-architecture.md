# 07 — Architecture

A consolidated view of the system after all phases shipped. Read this when you come back to the codebase after a break, or when you're onboarding a contractor.

## System diagram

```
+--------------------------------------------------------------------------+
|                              ANDROID DEVICE                              |
|                                                                          |
|   +-------------------------------+    +-----------------------------+   |
|   |    UI (Flutter + Material)    |    |        Riverpod graph       |   |
|   |  HomeScreen, RecordScreen,    |<-->|  providers, controllers,    |   |
|   |  NoteDetailScreen, SignIn,    |    |  StateNotifiers             |   |
|   |  Onboarding, Paywall, etc.    |    +--------------+--------------+   |
|   +---------------+---------------+                   |                  |
|                   |                                   |                  |
|                   v                                   v                  |
|   +---------------+---------------+    +--------------+--------------+   |
|   | RecordingController           |    | NoteRepository (Hive +      |   |
|   | (start/stop, amp polling)     |    |  cloud write-through)       |   |
|   +---------------+---------------+    +--------------+--------------+   |
|                   |                                   |                  |
|                   v                                   |                  |
|   +-------------------------------+                   |                  |
|   | AudioRecorderService          |                   |                  |
|   | (package:record wrapper)      |                   |                  |
|   +---------------+---------------+                   |                  |
|                   |                                   |                  |
|                   v                                   |                  |
|   +-------------------------------+    +--------------v--------------+   |
|   |  /data/.../rec_*.m4a          |    |  Hive box `notes_v1`        |   |
|   |  (audio files, device-only)   |    |  (JSON Note records)        |   |
|   +---------------+---------------+    +-----------------------------+   |
|                   |                                                      |
|                   v                                                      |
|   +-------------------------------+                                      |
|   | TranscriptionService (Dio)    |                                      |
|   +---------------+---------------+                                      |
|                   |                                                      |
|                   |  multipart POST /api/transcribe                      |
|                   |                                                      |
|   ----------------|---------------- HTTPS ------------------             |
|                   v                                                      |
+--------------------------------------------------------------------------+
                    |
                    v
+--------------------------------------------------------------------------+
|                     VERCEL (recapcoach.vercel.app)                       |
|                                                                          |
|   +-------------------------------+                                      |
|   | api/transcribe.ts             |                                      |
|   |   1. formidable parses upload |                                      |
|   |   2. openai Whisper-1         |                                      |
|   |   3. openai gpt-4o-mini       |                                      |
|   |   4. JSON response            |                                      |
|   +---------------+---------------+                                      |
|                   |                                                      |
+-------------------|------------------------------------------------------+
                    |
                    v
+--------------------------------------------------------------------------+
|                          OpenAI API                                      |
|   whisper-1 (audio -> transcript)                                        |
|   gpt-4o-mini (transcript -> summary + actionItems JSON)                 |
+--------------------------------------------------------------------------+


   (in parallel with the above transcription flow:)

+--------------------------------------------------------------------------+
|                       FIREBASE (recapcoach-dev)                          |
|                                                                          |
|   +-------------------------------+    +-----------------------------+   |
|   | Firebase Auth                 |    | Cloud Firestore             |   |
|   | Google + email/password +     |    | users/{uid}/notes/{id}      |   |
|   | anonymous                     |    | (per-user isolation rules)  |   |
|   +-------------------------------+    +-----------------------------+   |
|                                                                          |
|   +-------------------------------+    +-----------------------------+   |
|   | Crashlytics                   |    | Analytics                   |   |
|   +-------------------------------+    +-----------------------------+   |
|                                                                          |
|   +-------------------------------+                                      |
|   | Remote Config                 |                                      |
|   +-------------------------------+                                      |
+--------------------------------------------------------------------------+
```

## Layer responsibilities

### Presentation (`features/*/...screen.dart`)

- Pure UI. Reads state from Riverpod providers. Dispatches actions back to controllers.
- Never talks to Hive, Firestore, or OpenAI directly.
- Examples: `RecordScreen`, `NoteDetailScreen`, `HomeScreen`, `SignInScreen`.

### Application logic (`features/*/`_providers.dart`, `*_controller.dart`)

- Coordinates between services and UI.
- Manages screen-specific state via Riverpod `StateNotifier`s or simple `Provider`s.
- Examples: `RecordingController`, `noteSyncBootstrapProvider`, `goRouterProvider`.

### Domain / models (`features/*/note.dart`, etc.)

- Immutable data classes. `toMap` / `fromMap` for persistence. `copyWith` for partial updates.
- No I/O. Pure Dart.

### Infrastructure / repositories (`features/*/_repository.dart`, `*_service.dart`)

- Owns I/O. Hive, Firestore, Dio, the `record` package, `just_audio`, Firebase Auth.
- Stateless services where possible; otherwise hold platform handles (e.g. `AudioRecorder`).
- Examples: `NoteRepository`, `NoteCloudRepository`, `NoteSyncService`, `AudioRecorderService`, `TranscriptionService`, `AuthRepository`.

### Cross-cutting (`core/`)

- Analytics wrapper, logger, theme, router, env config.
- Used by all layers; depends on nothing in `features/`.

## Data flow: the canonical "record a call" trace

1. **User taps Record button** on `HomeScreen` → `context.go('/record')`
2. **`RecordScreen.initState`** calls `recordingControllerProvider.notifier.start()`
3. **`RecordingController.start()`**
   - Asks `AudioRecorderService.hasPermission()`; if false, returns and shows snackbar
   - Calls `AudioRecorderService.start()` which writes audio to `/data/.../rec_TS.m4a`
   - Starts a 200 ms `Timer.periodic`
   - Updates `RecordingState(isRecording: true, ...)` → UI rebuilds
4. **Every 200 ms**: timer fires, calls `_svc.getAmplitude()`, updates `RecordingState` → mic icon pulses, bar animates
5. **User taps Stop & Save**
   - `RecordingController.stop()` → `AudioRecorderService.stop()` → returns `RecordingResult { filePath, durationMs }`
   - `RecordScreen._stopAndSave` constructs a `Note` with `isProcessing: true`, then `NoteRepository.upsert(note)`
6. **`NoteRepository.upsert`**
   - Hive write (synchronous, immediate)
   - Best-effort `NoteCloudRepository.upsert(uid, note)` — fires `setDoc` to Firestore
   - Returns; UI doesn't wait for the cloud write
7. **Hive watch triggers** → `notesStreamProvider` re-emits → `HomeScreen` rebuilds with the new note tile showing "Processing..."
8. **In parallel**: `RecordScreen` fires-and-forgets `TranscriptionService.transcribe(File(filePath))`
9. **Dio uploads** the m4a as multipart to `https://recapcoach.vercel.app/api/transcribe`
10. **Vercel function** parses the upload, calls Whisper, then gpt-4o-mini, returns JSON
11. **`TranscriptionService` parses response** → `TranscriptionResult`
12. **`record_screen.dart` callback** constructs `note.copyWith(transcript, summary, actionItems, isProcessing: false)` → `NoteRepository.upsert(updated)`
13. **`upsert` again** writes Hive + best-effort Firestore mirror
14. **Hive watch triggers** → all subscribed widgets rebuild → user sees populated summary, action items, transcript

## Data flow: the canonical "uninstall and reinstall" recovery

1. **Fresh install**, app launches → `main()` opens Hive (empty), creates `NoteRepository` + `NoteCloudRepository`
2. **`RecapCoachApp` builds**, watches `noteSyncBootstrapProvider` → registers a `ref.listen` on `authStateProvider` with `fireImmediately: true`
3. **Onboarding** completes → user lands on `/sign-in`
4. **User signs in with Google** → `AuthRepository.signInWithGoogle()` → Firebase emits new `User?` event
5. **`noteSyncBootstrapProvider` listener fires** with the new user
6. **`NoteSyncService.syncForUser(uid)`** runs:
   - Compares last-known UID in SharedPreferences; if different, wipes Hive
   - `NoteCloudRepository.all(uid)` fetches every cloud doc
   - For each: `NoteRepository.upsertLocalOnly(note)` (bypasses cloud write-through)
7. **Hive changes propagate** through `notesStreamProvider` → `HomeScreen` populates within ~1 second of sign-in
8. **User taps a note** → detail screen renders summary/transcript/action items
9. **Audio player** tries to load `audioFilePath` (e.g. `/data/.../rec_1755000000.m4a`) — this path doesn't exist on the new device, so the player shows "Audio file not found". All text content is intact.

## Key design decisions and their tradeoffs

### Decision: Hive is the single source of truth for the UI

| Alternative | Why we didn't pick it |
|---|---|
| Firestore directly | Adds 50–500 ms of network latency to every read; offline UX is worse; UI is coupled to Firebase. |
| SQLite (drift) | Overkill for a flat list of JSON records; schema migrations are needless friction. |

### Decision: Best-effort cloud writes (no retries, no queue)

| Alternative | Why we didn't pick it |
|---|---|
| Workmanager-based retry queue | Complexity dwarfs the benefit for our scale. The catch-up push on next sign-in handles the failure case. |
| Block UI until cloud write succeeds | Awful UX on flaky networks. |

### Decision: One backend endpoint that does both transcription and summarization

| Alternative | Why we didn't pick it |
|---|---|
| Two endpoints (`/transcribe`, `/summarize`) | Doubles round-trips, doubles complexity in the client. |
| Streaming transcription | Whisper-1 doesn't stream. Whisper streaming requires the (more expensive) `gpt-4o-transcribe` model. Defer until UX feedback demands it. |

### Decision: Audio stays device-local (for now)

| Alternative | Why we didn't pick it (yet) |
|---|---|
| Auto-upload to Firebase Storage | Storage costs scale linearly with usage; ~$0.026/GB/month. Better packaged as a Pro upgrade. |
| Manual export (share sheet) | Doesn't survive uninstall; still requires a deliberate user action. Useful eventually but not the priority. |

### Decision: Riverpod over Provider/Bloc

| Alternative | Why we didn't pick it |
|---|---|
| `provider` (the original package) | Less type-safe; harder to compose. |
| `flutter_bloc` | More ceremony per feature; the team prefers Riverpod's `ref.watch` pattern. |
| `GetIt` + Streams | Manual; no compile-time safety. |

## Threading / concurrency model

- **All app code runs on the main isolate.** No `compute()` or `Isolate.spawn()` is used.
- **Long-running operations (network, file I/O) are awaited on the main isolate.** This works because Dart's I/O is non-blocking — the event loop continues running, the UI stays responsive.
- **No mutexes / locks are required.** Hive's API is async but serialized internally.
- **Background processing (transcription) is fire-and-forget Futures.** The `Note` record's `isProcessing` flag is the user-visible state; we don't await the Future from the UI.

## Trust boundaries

| Boundary | Risk | Mitigation |
|---|---|---|
| Device storage | App can read its own audio files only (Android sandbox) | Standard Android isolation |
| Vercel function | Anyone with the URL can hit OpenAI | **NOT YET MITIGATED** — see [08-roadmap.md](08-roadmap.md). Plan: verify Firebase ID token. |
| Firestore | A user could try to read another user's notes | Mitigated by `firestore.rules` — denies unless `request.auth.uid == uid` |
| OpenAI key | Could leak from the backend | Set as encrypted env var in Vercel; never returned in responses; not logged |

## Next chapter

[08 — Roadmap](08-roadmap.md) — what's still open, prioritized with effort estimates.
