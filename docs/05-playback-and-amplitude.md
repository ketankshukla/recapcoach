# 05 — Playback + amplitude bug fix

> **Commit:** `739bed9` *(Audio playback + fix amplitude meter dying after first recording)*

Two things shipped together in this phase:

1. **Audio playback** in the note detail screen (a real omission from Phase 3 — recordings could be created but never listened to)
2. **Fix for a subtle bug**: the amplitude meter only animated for the **first** recording per app session

## Part 1: Audio playback

### Why `just_audio`?

| Package | Pros | Cons |
|---|---|---|
| `just_audio` | Mature, great seek/scrub support, good docs | Slightly heavier |
| `audioplayers` | Lighter | Worse seek precision, more buggy on Android |
| Built-in Android `MediaPlayer` via platform channel | No deps | Significant work, no benefit |

**Chose `just_audio: ^0.9.41`.** No special Android config needed for AAC playback (built into the OS).

### `lib/features/notes/note_player.dart`

New widget: `NotePlayer({required String audioFilePath})`. Behavior:

- Loads the file on `initState`
- Subscribes to three streams from `just_audio`:
  - `positionStream` (for the scrubber + current-time label)
  - `durationStream` (for the total-time label)
  - `playerStateStream` (for the play/pause icon, and to auto-rewind on completion)
- Renders a `Card` containing a big play/pause `IconButton`, a `Slider`, and `m:ss` labels
- Disposes the player on `dispose`
- Shows a friendly `"Audio file not found"` error message if the file doesn't exist (relevant after cloud-sync resurrected notes from a different device — see [06](06-cloud-sync.md))

### Wired into `NoteDetailScreen`

Sits right below the metadata card:

```dart
_MetadataCard(note: note),
const SizedBox(height: 12),
NotePlayer(
  key: ValueKey(note.audioFilePath),
  audioFilePath: note.audioFilePath,
),
```

The `ValueKey` ensures Flutter rebuilds the player (loading a fresh file) if the note's audio path ever changes.

## Part 2: The amplitude meter bug

### Symptom

The user reported: *"The wave animation works for the first recording I make, but stops working on subsequent recordings. After I restart the app, it works for the next first recording then breaks again."*

A clear pattern: **once per app session, then dead**.

### Root cause

The original `RecordingController` subscribed to a `Stream<Amplitude>` from `package:record`:

```dart
_ampSub = _svc.amplitudeStream().listen((a) {
  state = state.copyWith(amplitudeDb: a.current);
});
```

Internally, `record`'s `onAmplitudeChanged` creates a periodic stream tied to the lifecycle of **that specific recording session**. When the recorder stops:

1. The stream's internal `StreamController` is **closed permanently**.
2. Calling `onAmplitudeChanged` again on the **same `AudioRecorder` instance** returns either the same dead stream or a new one that never emits.

Because we use a singleton `audioRecorderProvider` (the `AudioRecorder` instance is shared across all recording sessions), every recording after the first got a dead amplitude stream.

### Fix: poll-based amplitude

Instead of relying on the package's stream, we now **poll** `getAmplitude()` from the same 200ms `Timer.periodic` that's already running for the elapsed-time counter. One timer drives both:

```dart
_ticker = Timer.periodic(
  const Duration(milliseconds: 200),
  (_) => _onTick(),
);

Future<void> _onTick() async {
  if (!state.isRecording) return;
  final nextElapsed = state.elapsedMs + 200;
  try {
    final amp = await _svc.getAmplitude();
    if (!state.isRecording) return; // stopped while awaiting
    state = state.copyWith(
      elapsedMs: nextElapsed,
      amplitudeDb: amp.current,
    );
  } catch (e) {
    // Polling can fail transiently; still advance the clock so the UI
    // doesn't appear frozen.
    state = state.copyWith(elapsedMs: nextElapsed);
  }
}
```

The `AudioRecorderService` exposes `Future<Amplitude> getAmplitude()` directly — bypassing the broken stream entirely.

### Why this works

The timer is **created fresh on every `start()`** and disposed on every `stop()`. There's no shared state that survives between recordings. `getAmplitude()` is a simple one-shot call to Android's `MediaRecorder.getMaxAmplitude()` under the hood — no lifecycle, no stream closure, no surprises.

### Diagnostic logging added

For future debugging, the controller logs the current amplitude once per second:

```
[info] | mic amp=-12.4dB (max=-8.1dB)
[info] | mic amp=-50.1dB (max=-8.1dB)
```

If amplitude is ever broken again, these lines tell you whether the issue is in the mic polling (no logs) or in the UI rendering (logs present but no animation).

## Bonus: cleaner subscription/dispose code

The old code had two periodic engines (the elapsed-time `Timer` and the `_ampSub` `StreamSubscription`) racing each other. State updates from one could clobber the other. The single-timer design eliminates that whole class of bugs.

## Lessons learned

| Lesson | Where it applies elsewhere |
|---|---|
| **Treat package streams with suspicion across sessions.** If a stream is implemented as `Stream.periodic` or a `StreamController` inside a package, its lifecycle is whatever the package author decided — and they may not have tested re-subscription. | Any `package:foo` that exposes `Stream<T>` for periodic events. |
| **One timer is better than two.** When two engines need to fire at the same cadence, share them. Easier to reason about, no clock skew. | Anywhere the UI animates and updates derived state on the same tick. |
| **Log before you guess.** The `mic amp=...` log line we added makes future regressions in this exact area instant to diagnose. | Subtle reactive bugs across the app. |

## Next chapter

[06 — Cloud sync](06-cloud-sync.md) — making notes survive uninstall and follow the user across devices via Firestore.
