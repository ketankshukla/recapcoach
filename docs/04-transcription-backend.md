# 04 — Transcription backend

> **Commits:** `ee3261d` _(Phase 2D: Vercel /api/transcribe (Whisper + gpt-4o-mini) + Flutter wiring)_ and `c8d7841` _(Add public/index.html landing page so Vercel build does not fail)_

This chapter covers the **Vercel serverless backend** that turns an uploaded `.m4a` file into a transcript + summary + action items, and the **Flutter client** that talks to it.

## Why a backend at all?

The OpenAI API key must never live on-device. If we shipped it inside the Flutter app, any user could decompile the APK, extract the key, and run up arbitrary OpenAI charges. The fix is a thin proxy server that:

1. Holds the OpenAI key in server-side env vars
2. Accepts the audio upload from the app
3. Calls Whisper + gpt-4o-mini
4. Returns the structured result

We host on **Vercel** because:

- Free tier covers a single endpoint indefinitely
- Zero ops (no servers, no Docker, no CI/CD)
- Pushes to `main` auto-deploy
- Cold starts are sub-second for a Node function

## What was built

### Backend files (added to the same repo)

```
api/
├─ transcribe.ts        The serverless function (POST /api/transcribe)
├─ delete-account.ts    Account deletion + trial-abuse hash (POST /api/delete-account)
├─ _lib/
│  ├─ firebase-admin.ts Auth verification helper
│  ├─ quota.ts          Quota context, enforcement, usage recording
│  ├─ limits.ts         Plan limit constants
│  └─ audio-meta.ts     Audio duration probe
└─ README.md            Operator notes
package.json            Backend deps (openai, formidable, @vercel/node)
tsconfig.json           TypeScript config for the function
vercel.json             Output dir + function timeout + per-endpoint config
public/index.html       Tiny landing page so Vercel's "Other" preset finds an output dir
.vercelignore           Excludes the Flutter project from the build
```

### Flutter files (new)

```
lib/core/config/env.dart                           Exposes BACKEND_URL injected via --dart-define
lib/features/transcription/transcription_service.dart   Dio multipart POST + JSON parsing
lib/features/transcription/transcription_providers.dart Riverpod wiring
```

### Note repository updated to kick off transcription

After `record_screen.dart` saves a new `Note`, it spawns a fire-and-forget call to `TranscriptionService.transcribe()`. The result is merged into the note via `Note.copyWith(...)`. Errors set `processingError` instead of crashing.

## The backend: `api/transcribe.ts`

A single Node serverless function. Key design choices:

### Multipart parsing with `formidable`

Vercel's default JSON body parser is disabled:

```ts
export const config = { api: { bodyParser: false } };
```

`formidable` parses the upload, with a 25 MB size cap (Whisper's hard limit). The audio file lands in a tmp path that we then stream to OpenAI.

### Whisper-1 for transcription

```ts
const transcription = await openai.audio.transcriptions.create({
  file: fs.createReadStream(audioPath),
  model: "whisper-1",
  response_format: "json",
});
```

Tradeoffs considered:

| Choice                   | Pros                                  | Cons                                                             | Verdict                         |
| ------------------------ | ------------------------------------- | ---------------------------------------------------------------- | ------------------------------- |
| `whisper-1`              | Best accuracy, broad language support | $0.006 / minute                                                  | **Used** — quality matters most |
| `gpt-4o-transcribe`      | Newer, sometimes faster               | More expensive, less battle-tested                               | Skipped                         |
| On-device speech-to-text | Free, private                         | Quality is much worse, Android STT requires Google Play Services | Skipped                         |

### gpt-4o-mini for summary + action items

Why gpt-4o-mini specifically:

- $0.15/M input tokens, $0.60/M output tokens — pennies per call
- `response_format: { type: 'json_object' }` guarantees parseable JSON
- Fast enough that the user sees results within ~5 seconds of transcript completion

The system prompt enforces a strict two-key schema:

```json
{
  "summary": "...",
  "actionItems": ["...", "..."]
}
```

If the LLM call fails mid-pipeline, we **still return the transcript with 200** so the user doesn't lose their text. The frontend handles this gracefully (shows transcript section, empty summary, with a warning).

### Error envelope

| HTTP | When                                                                                                 |
| ---- | ---------------------------------------------------------------------------------------------------- |
| 200  | Happy path or transcript-only-fallback. Frontend reads `summary`, `actionItems`, optional `warning`. |
| 400  | Missing or corrupt `audio` field.                                                                    |
| 405  | Wrong HTTP method (anything other than POST).                                                        |
| 500  | `OPENAI_API_KEY` missing, or Whisper itself errored.                                                 |

## The frontend: `TranscriptionService`

A thin `Dio` wrapper that:

1. Reads `Env.backendUrl` from `--dart-define=BACKEND_URL=...`
2. Builds a `FormData` with the audio file under the field name `audio`
3. POSTs to `${BACKEND_URL}/api/transcribe`
4. Parses the JSON response into a typed `TranscriptionResult`

Timeouts chosen for real-world calls:

- Connect: 15 s
- Send: 60 s (multi-MB upload over LTE)
- Receive: 90 s (Whisper can take a while on multi-minute audio)

## Vercel deploy setup

### Initial deploy gotchas

Two issues hit during the first deploy:

1. **No `public/` directory** → Vercel failed with _"No Output Directory named 'public' found"_. Fix: added a tiny `public/index.html` landing page (commit `c8d7841`). Side benefit: visiting the bare URL now shows a polished "RecapCoach API — ONLINE" page.
2. **`.vercelignore`** had to be added to exclude the Flutter project (Android/iOS/lib) from the build context — otherwise Vercel would try to "build" Flutter assets.

### Env vars to set in Vercel project settings

| Key              | Value    | Encrypted? |
| ---------------- | -------- | ---------- |
| `OPENAI_API_KEY` | `sk-...` | Yes        |

### Deployment URL

Production: **`https://recapcoach.vercel.app`**

There are also auto-aliases like `recapcoach-git-main-<username>.vercel.app` and immutable per-deployment URLs. Use the bare one — it's stable.

### How to deploy

The repo is connected to Vercel via GitHub. Pushing to `main` auto-deploys. No CLI needed. The `vercel.json` declares:

```json
{
  "buildCommand": "echo 'No build step needed - functions are auto-detected'",
  "outputDirectory": "public"
}
```

## End-to-end flow at the end of this phase

```
User taps Stop & Save in RecordScreen
   |
   v
NoteRepository.upsert(note with isProcessing=true)  -> Hive write -> UI updates
   |
   v   (fire-and-forget)
TranscriptionService.transcribe(file)
   |
   v
POST https://recapcoach.vercel.app/api/transcribe
   |
   v
Vercel function:
  1. formidable parses multipart
  2. openai.audio.transcriptions.create -> transcript
  3. openai.chat.completions.create (gpt-4o-mini) -> {summary, actionItems}
  4. JSON response
   |
   v
TranscriptionService parses JSON -> TranscriptionResult
   |
   v
note.copyWith(transcript, summary, actionItems, isProcessing: false)
   |
   v
NoteRepository.upsert(updated note) -> Hive change -> UI rebuilds
   |
   v
User sees populated summary + action items + transcript in the detail screen
```

## Cost back-of-envelope

For one 10-minute call:

| Step                                                         | Cost                                          |
| ------------------------------------------------------------ | --------------------------------------------- |
| Whisper-1 transcription                                      | 10 min × $0.006 = **$0.06**                   |
| gpt-4o-mini summary (~3000 input tokens, ~300 output tokens) | ~3000 × $0.15/M + 300 × $0.60/M = **$0.0006** |
| **Total per call**                                           | **~$0.06**                                    |

A user doing 5 calls/day @ 10 min each = $9/month in OpenAI costs. At a $19/month subscription price, gross margin is ~50%. The math works.

## Open problems (deferred)

| Problem                                                    | Fix planned                                                                             |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Endpoint is **anonymous** — anyone with the URL can hit it | Add Firebase ID token verification on the function (see [08-roadmap.md](08-roadmap.md)) |
| No rate limiting                                           | After auth lockdown, add per-uid quota                                                  |
| 25 MB hard cap means ~50 min of audio max                  | Chunk audio client-side before upload for longer calls                                  |

## Next chapter

[05 — Playback + amplitude bug fix](05-playback-and-amplitude.md) — adding audio playback to the detail screen and fixing a subtle bug where the amplitude meter died after the first recording.
