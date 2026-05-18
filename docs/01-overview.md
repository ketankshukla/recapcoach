# 01 — Overview

## What is RecapCoach?

RecapCoach is an Android app for **solo consultants, coaches, and advisors** who want their post-call admin done before the call ends. The user records a call (in-person or over speakerphone), and the app produces:

- A **clean transcript**
- A **2-3 sentence summary**
- A **bullet list of action items** the user committed to during the call

Powered by OpenAI Whisper (transcription) and gpt-4o-mini (summarization + action extraction), delivered through a Vercel serverless backend so the OpenAI API key never lives on-device.

## Target user

A 1-to-many independent consultant who:

- Bills by the hour or by the engagement
- Does 5–20 client calls per week
- Currently scribbles handwritten notes mid-call or types into a doc afterwards
- Loses follow-ups to memory failure or sloppy note-taking
- Will happily pay $10–$20/month to make this pain go away

## Differentiation vs. Otter / Fireflies / Fathom

| | RecapCoach | Otter / Fireflies / Fathom |
|---|---|---|
| Primary device | Phone (in your pocket) | Laptop / browser meeting bot |
| Records what kind of call? | In-person + phone + speakerphone Zoom | Web meetings only (Zoom/Teams/Meet) |
| Setup time per call | Tap once | Schedule the bot, deal with consent prompts |
| Price point | $10–20/mo solo | $20–40+/mo, team-targeted |
| Pitch | "Solo consultant's post-call admin tool" | "Team meeting intelligence platform" |

The wedge is **in-person meetings** — a category the big players don't serve well because their entire architecture assumes a virtual meeting bot.

---

## Current status (as of commit `3c5a817`)

**What works end-to-end on a real device today:**

- Sign in with Google
- Onboarding flow
- Tap **Record** → record audio with live amplitude meter
- Tap **Stop & save** → audio file persisted locally, note appears in list
- Note auto-processes in background (uploads audio to backend → Whisper → gpt-4o-mini)
- Transcript, summary, and action items appear in note detail screen within ~15-30 seconds
- Audio playback with scrubber and play/pause
- All note text content syncs to Firestore — survives uninstall + reinstall + new device

**What's not built yet:**

- Audio file cloud upload (audio is device-local only; lost on uninstall)
- Auth-locked backend (anyone with the URL can hit `/api/transcribe`)
- "Reprocess" button on failed notes
- Polished home screen (empty state, search, filters)
- Play Store listing + closed testing distribution

See [08-roadmap.md](08-roadmap.md) for the full backlog with effort estimates.

---

## Stack

| Layer | Tech | Why |
|---|---|---|
| **Mobile** | Flutter 3.x | Cross-platform; ship to Android first, iOS later for free |
| **State** | Riverpod 2 | Compile-time-safe DI + reactive state |
| **Routing** | go_router | Declarative + deep-link-ready |
| **Local DB** | Hive | Fast, no schema migrations, sufficient for note metadata |
| **Audio recording** | `record` 5.x | Most mature Flutter recording package |
| **Audio playback** | `just_audio` 0.9.x | Most reliable playback; good seek support |
| **Auth** | Firebase Auth + Google Sign-In | Cheap, scales infinitely, identity provider already used |
| **Cloud DB** | Cloud Firestore | Sync-friendly, generous free tier for text |
| **Crash + analytics** | Firebase Crashlytics + Analytics | Standard Firebase observability |
| **Remote Config** | Firebase Remote Config | Toggle paywall features without re-shipping |
| **Monetization** | RevenueCat over Play Billing | Avoids re-implementing receipt validation |
| **Backend** | Vercel serverless (Node 20 / TypeScript) | Free tier + zero ops; ideal for a single OpenAI proxy endpoint |
| **AI** | OpenAI Whisper + gpt-4o-mini | Best-in-class transcription; cheap & fast LLM for summary/action extraction |

---

## Key project paths

| Path | What's there |
|---|---|
| `lib/main.dart` | App entry. Initializes Firebase, Hive, Riverpod, RevenueCat. |
| `lib/app.dart` | Root `MaterialApp.router`. Hosts the sync bootstrap listener. |
| `lib/core/` | Cross-cutting: analytics, logging, theme, router, config. |
| `lib/features/recording/` | The mic capture flow + amplitude polling. |
| `lib/features/notes/` | Note model, local repo, cloud repo, sync service, list/detail UI, player. |
| `lib/features/transcription/` | Client that calls the Vercel backend. |
| `lib/features/auth/` | Firebase Auth + Google Sign-In wrapper. |
| `lib/features/paywall/` | RevenueCat-backed paywall UI. |
| `lib/features/onboarding/` | First-run flow. |
| `api/transcribe.ts` | The Vercel serverless function that calls OpenAI. |
| `firestore.rules` | Per-user isolation rules. |
| `vercel.json`, `package.json`, `tsconfig.json` | Backend deploy config. |
| `public/index.html` | Tiny landing page Vercel serves at the root URL. |

---

## Next chapter

[02 — Initial scaffold](02-scaffold.md) — what was already in place before feature work started.
