# RecapCoach Documentation

This folder holds everything you need to understand, develop, and ship RecapCoach.

The documents are split into two groups:

1. **Development chapters** — a chronological build log of how the app was constructed. Read these in order if you want to understand the codebase from scratch.
2. **Operational guides** — setup, publishing, and legal templates you reach for when shipping.

---

## Development chapters (read in order)

| #   | Chapter                                                      | Summary                                                                                                                        |
| --- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| 01  | [Overview](01-overview.md)                                   | What RecapCoach is, who it's for, the stack, current status, and what works end-to-end today.                                  |
| 02  | [Initial scaffold](02-scaffold.md)                           | The starter project (Flutter + Riverpod + Firebase + RevenueCat) — what came pre-wired before feature work began.              |
| 03  | [Audio recording + local notes](03-audio-recording.md)       | The `record` package, amplitude meter, Hive-backed `NoteRepository`, and the record/detail UI.                                 |
| 04  | [Transcription backend](04-transcription-backend.md)         | The Vercel serverless `/api/transcribe` endpoint (Whisper + gpt-4o-mini) and the Flutter `TranscriptionService` that calls it. |
| 05  | [Playback + amplitude bug fix](05-playback-and-amplitude.md) | Adding `just_audio` playback to the detail screen and fixing the amplitude meter dying after the first recording.              |
| 06  | [Cloud sync](06-cloud-sync.md)                               | Firestore-backed text sync so notes survive uninstall/reinstall and follow the user across devices.                            |
| 07  | [Architecture](07-architecture.md)                           | Full data-flow diagram, layer responsibilities, and the rationale for major decisions.                                         |
| 08  | [Roadmap](08-roadmap.md)                                     | What's still open, prioritized, with effort estimates.                                                                         |
| 09  | [Quotas & safety](09-quotas-and-safety.md)                   | Hybrid pricing model, per-plan caps, server-side quota enforcement, Firestore data model, kill switch.                         |

## Operational guides

| Doc                                                      | Use it when                                                                             |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [SETUP.md](SETUP.md)                                     | Setting up the Windows toolchain (Flutter, JDK, Android SDK, FlutterFire) from scratch. |
| [PUBLISH.md](PUBLISH.md)                                 | Publishing to Google Play closed testing / production.                                  |
| [PRIVACY_POLICY_TEMPLATE.md](PRIVACY_POLICY_TEMPLATE.md) | Drafting the privacy policy you must host before Play submission.                       |
| [TERMS_TEMPLATE.md](TERMS_TEMPLATE.md)                   | Drafting the terms of service.                                                          |

---

## Quick reference

- **Codebase root:** `e:\recapcoach`
- **Production backend URL:** `https://recapcoach.vercel.app`
- **GitHub:** [ketankshukla/recapcoach](https://github.com/ketankshukla/recapcoach)
- **Firebase project:** `recapcoach-dev`
- **App ID (Android):** `com.ketankshukla.recapcoach`

---

## Last updated

This snapshot reflects the state of `main` after the **monetization safety net** milestone:

- Firebase ID token auth on `/api/transcribe` (chapter 04 + 08).
- Hybrid pricing model with server-side quotas, kill switch, and live usage meter in the app (chapter 09).

Update this doc when you ship the next significant milestone (RevenueCat product wiring, UI overhaul, Play Store closed testing, etc.).
