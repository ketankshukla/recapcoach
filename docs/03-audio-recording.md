# 03 — Audio recording + local notes

> **Commits:** `c533fc2` *(feat(2C): audio recording + local notes storage)* and `a60d935` *(Phase 2C: working audio recording on device + Firebase wired)*

This chapter covers the first user-visible feature: tapping a mic button, recording audio, and saving it as a "note" with a stable record on disk.

## Goals of this phase

1. Capture audio cleanly on Android with permission handling
2. Encode at a size + format compatible with OpenAI Whisper
3. Show a live amplitude meter while recording (UX confidence)
4. Persist a `Note` record locally with a path to the audio file
5. Show the user a list of past notes and a detail screen per note
6. **No transcription yet** — that comes in [04-transcription-backend.md](04-transcription-backend.md)

## Dependencies added

```yaml
# pubspec.yaml
record: ^5.1.2
permission_handler: ^11.3.1
uuid: ^4.5.1
```

A `dependency_override` was also needed for `record_linux: ^1.3.0` because `record 5.1.2` pulls in an incompatible `record_linux 0.7.2` that breaks Dart's cross-platform compilation (even when only targeting Android):

```yaml
dependency_overrides:
  record_linux: ^1.3.0
```

## Audio format choice

The `AudioRecorderService` encodes to **AAC-LC mono @ 16 kHz, 64 kbps** inside an MP4 container (`.m4a`). The reasoning:

| Constraint | Implication |
|---|---|
| Must be Whisper-compatible | Whisper accepts m4a/AAC, mp3, mp4, mpeg, mpga, wav, webm. |
| Bandwidth-cheap for upload | 64 kbps = ~480 KB/min. A 30-min call is ~14 MB. |
| Speech-only — no need for fidelity | 16 kHz mono is plenty for intelligible voice; doubling sample rate would just bloat the file with frequencies humans can't produce. |
| Native Android codec, no extra deps | AAC-LC ships in Android's `MediaCodec`; no FFmpeg needed. |

## Components built

### `lib/features/recording/audio_recorder_service.dart`

Thin wrapper around `package:record`. Exposes:

- `hasPermission()` — proxies to the package
- `start()` — picks a path under `${docs}/recordings/rec_{epoch}.m4a` and starts recording
- `stop()` — returns `RecordingResult(filePath, durationMs)`
- `cancel()` — stops AND deletes the file
- `getAmplitude()` — one-shot read of current dBFS (the package's stream API is fragile across sessions — see [05](05-playback-and-amplitude.md))

### `lib/features/recording/recording_providers.dart`

The `RecordingController` is a `StateNotifier<RecordingState>` that:

- Maps high-level `start/stop/cancel` into the service
- Runs a single 200 ms `Timer.periodic` that does double-duty: advances the elapsed-time counter **and** polls the current amplitude
- Exposes `RecordingState { isRecording, elapsedMs, amplitudeDb, elapsedLabel }` for the UI

### `lib/features/recording/record_screen.dart`

The record UI:

- A pulsing mic icon whose size is proportional to amplitude (`_PulsingMic` widget)
- A horizontal amplitude bar (`_AmplitudeBar`)
- Big elapsed-time display
- Stop & Save / Cancel buttons
- Rejects recordings shorter than 3 seconds (Whisper has trouble with very short clips and the UX of "I just tapped record and stop accidentally" is best served by a quiet abort)

### `lib/features/notes/note.dart`

Immutable model with `toMap` / `fromMap` for JSON, `copyWith` for partial updates, and computed getters (`displayTitle`, `durationLabel`).

Fields:
- `id` — UUID v4
- `audioFilePath` — absolute device path
- `createdAt` — recording start time
- `durationMs` — recording length
- `title` — user-editable, falls back to formatted date
- `transcript`, `summary`, `actionItems` — null until backend fills them
- `isProcessing` — true while transcription runs
- `processingError` — populated if backend call failed

### `lib/features/notes/note_repository.dart`

Hive-backed CRUD. The Hive box is `notes_v1`, storing JSON strings keyed by note ID. Methods:

- `all()` — newest-first list
- `byId(id)` — lookup
- `upsert(note)` — write
- `delete(id)` — delete record AND its audio file (best-effort)
- `watchAll()` — `Stream<List<Note>>` that re-emits on every box change

> Cloud write-through was added later in [06-cloud-sync.md](06-cloud-sync.md).

### `lib/features/notes/note_providers.dart`

Three providers:

- `noteRepositoryProvider` — throws unless overridden in `main.dart` after Hive opens
- `notesStreamProvider` — wraps `repo.watchAll()`
- `noteByIdProvider.family(id)` — single-note lookup

### `lib/features/notes/note_detail_screen.dart`

Renders a note with three "sections" (Summary, Action items, Transcript) plus a metadata card. Each section handles three states: processing (spinner), error (red text), populated (real content with copy-to-clipboard button).

## Android permission setup

`android/app/src/main/AndroidManifest.xml` was updated to include:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

The `record` package requests the runtime permission automatically on first `start()`. The user sees the standard "Allow RecapCoach to record audio?" system dialog.

## End-to-end flow at the end of this phase

```
HomeScreen "Record" button
   |
   v
RecordScreen -> RecordingController.start()
   |
   v
AudioRecorderService.start() -> writes to /data/data/.../recordings/rec_TS.m4a
   |
   v   (user speaks; 200ms ticker polls amplitude)
   |
RecordScreen "Stop & Save"
   |
   v
RecordingController.stop() -> returns RecordingResult
   |
   v
RecordScreen builds a Note { id, audioFilePath, createdAt, durationMs, isProcessing: true }
   |
   v
NoteRepository.upsert(note)
   |
   v   (Hive box emits change -> notesStreamProvider updates -> HomeScreen rebuilds)
   |
   v
HomeScreen tile shows the new note with "Processing..."  (no actual transcription yet)
   |
   v   (user taps tile)
   |
NoteDetailScreen shows placeholder sections
```

The note record exists but its transcript/summary/action items are permanently null because there's no backend yet. That's what [Chapter 4](04-transcription-backend.md) fixes.

## Known issues at end of this phase (fixed later)

| Issue | Fixed in |
|---|---|
| Amplitude meter only animated on the **first** recording per session | [05-playback-and-amplitude.md](05-playback-and-amplitude.md) — switched from the package's stream to timer-based polling |
| No way to actually play back the audio | [05](05-playback-and-amplitude.md) — added `just_audio` + `NotePlayer` widget |
| Notes lost on uninstall | [06](06-cloud-sync.md) — Firestore text sync |

## Next chapter

[04 — Transcription backend](04-transcription-backend.md) — the Vercel serverless function that turns an `.m4a` file into a transcript + summary + action items.
