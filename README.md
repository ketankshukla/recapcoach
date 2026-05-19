# RecapCoach

**Record consulting calls, instantly get a clean transcript, summary, and action items.**

Built for solo consultants and coaches who want their post-call admin done before the call ends.

## Status

🟢 **Working end-to-end on real Android hardware**, with the OpenAI key now protected behind Firebase auth **and** per-plan quotas. Notes are recorded, transcribed via OpenAI Whisper + gpt-4o-mini through a Vercel backend, and synced to Firestore so they survive uninstall and follow the user across devices.

Next milestone: **UI overhaul** in progress — Phase 0 (design system foundation) shipped; Phases 1-6 (home, record, detail, paywall, settings, auth+onboarding) next. Then RevenueCat product wiring, then Play Store closed testing.

See **[docs/](docs/README.md)** for the full chapter-by-chapter build log, architecture diagrams, and roadmap.

## What works today

- ✅ Onboarding + Google sign-in (Firebase Auth)
- ✅ Record audio with live amplitude meter (16 kHz mono AAC-LC, ~480 KB/min)
- ✅ Audio playback with scrubber, position, and duration display
- ✅ Background transcription via Vercel `/api/transcribe` (Whisper + gpt-4o-mini)
- ✅ Note list + detail screen with summary, action items, and full transcript
- ✅ Cloud sync of note text to Firestore — survives uninstall + new device
- ✅ Per-user data isolation via Firestore security rules
- ✅ **Backend protected by Firebase ID token verification** — no anonymous access
- ✅ **Server-side per-plan quotas** (Free: 5 recs / 15 min /mo · Pro: 100 recs / 8 hr /mo) with atomic monthly counters
- ✅ **Live usage meter on the home screen** + pre-flight paywall when at cap
- ✅ **Global kill switch** via `/config/global.transcriptionEnabled` for instant cost-leak response
- ✅ Paywall (RevenueCat) + Remote Config + Crashlytics + Analytics wired

## Monetization (Hybrid pricing)

| Tier        | Price  | Caps                                    | Worst-case cost / user / month |
| ----------- | ------ | --------------------------------------- | ------------------------------ |
| Free        | $0     | 5 recordings, 3 min each, 15 min total  | ~$0.09                         |
| Pro Monthly | $7.99  | 100 recordings, 20 min each, 8 hr total | ~$2.88                         |
| Pro Yearly  | $49.99 | same as Pro Monthly                     | ~$2.88 / mo equivalent         |

Margin per Pro user at maximum usage: ~58% after Google Play's 15% subscription fee. See [docs/09-quotas-and-safety.md](docs/09-quotas-and-safety.md) for the full design.

## Stack

- **Mobile:** Flutter 3.x (Android first; iOS later)
- **State:** Riverpod 2
- **Routing:** go_router
- **Local cache:** Hive
- **Cloud DB:** Cloud Firestore (text only — audio is device-local)
- **Auth:** Firebase Auth + Google Sign-In
- **Audio:** `record` (capture) + `just_audio` (playback)
- **Backend:** Vercel serverless (Node 20 / TypeScript) at `https://recapcoach.vercel.app`
- **AI:** OpenAI Whisper-1 + gpt-4o-mini
- **Monetization:** RevenueCat over Play Billing
- **Observability:** Firebase Analytics + Crashlytics + `talker_flutter`

## Documentation

The `docs/` folder contains a complete chapter-by-chapter build log plus operational guides.

| Doc                                                                      | Read it for                                                             |
| ------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| **[docs/README.md](docs/README.md)**                                     | Documentation index — start here                                        |
| [docs/01-overview.md](docs/01-overview.md)                               | What RecapCoach is, who it's for, current status                        |
| [docs/02-scaffold.md](docs/02-scaffold.md)                               | The starter project's pre-wired plumbing                                |
| [docs/03-audio-recording.md](docs/03-audio-recording.md)                 | Adding the mic capture + local notes                                    |
| [docs/04-transcription-backend.md](docs/04-transcription-backend.md)     | The Vercel + OpenAI pipeline                                            |
| [docs/05-playback-and-amplitude.md](docs/05-playback-and-amplitude.md)   | Adding playback; fixing the amplitude bug                               |
| [docs/06-cloud-sync.md](docs/06-cloud-sync.md)                           | Firestore-backed sync so notes survive uninstall                        |
| [docs/07-architecture.md](docs/07-architecture.md)                       | Full system diagram + design decisions                                  |
| [docs/08-roadmap.md](docs/08-roadmap.md)                                 | What's still open, prioritized                                          |
| [docs/09-quotas-and-safety.md](docs/09-quotas-and-safety.md)             | Hybrid pricing, per-plan caps, kill switch, Firestore usage model       |
| [docs/10-financial-projections.md](docs/10-financial-projections.md)     | Exact revenue + cost math at 1K / 10K / 100K / 1M users + safety levers |
| [docs/11-test-plan.md](docs/11-test-plan.md)                             | ~120 test catalogue across unit / widget / integration / backend layers |
| [docs/12-solo-developer-playbook.md](docs/12-solo-developer-playbook.md) | Realistic operational guide for running a paid app alone                |
| [docs/13-ui-design-system.md](docs/13-ui-design-system.md)               | UI design system foundation (navy + amber, M3, tokens)                  |
| [docs/14-vercel-cli-setup.md](docs/14-vercel-cli-setup.md)               | Local pre-deploy `vercel build` setup + the `npm run vercel:build` flow |
| [docs/SETUP.md](docs/SETUP.md)                                           | First-time Windows toolchain install                                    |
| [docs/PUBLISH.md](docs/PUBLISH.md)                                       | Play Store closed testing checklist                                     |
| [docs/PRIVACY_POLICY_TEMPLATE.md](docs/PRIVACY_POLICY_TEMPLATE.md)       | Privacy policy template                                                 |
| [docs/TERMS_TEMPLATE.md](docs/TERMS_TEMPLATE.md)                         | Terms of service template                                               |

## Project layout

```
recapcoach/
├─ api/                    Vercel serverless function (TypeScript)
│  ├─ transcribe.ts        POST /api/transcribe — auth + quota + Whisper + gpt-4o-mini
│  └─ _lib/
│     ├─ firebase-admin.ts Lazy-init Firebase Admin SDK + ID token verification
│     ├─ limits.ts         Plan limits (FREE / PRO) — single source of truth
│     ├─ quota.ts          Firestore quota counters + kill switch + assert helpers
│     └─ audio-meta.ts     Server-side duration probe (music-metadata)
├─ public/                 Static landing page served at the bare URL
├─ lib/
│  ├─ main.dart            App entry: Firebase, Hive, Riverpod, RevenueCat init
│  ├─ app.dart             Root MaterialApp.router + sync bootstrap
│  ├─ core/
│  │  ├─ analytics/        Firebase Analytics wrapper
│  │  ├─ config/           env vars (BACKEND_URL via --dart-define)
│  │  ├─ logging/          talker logger
│  │  ├─ router/           go_router config
│  │  ├─ theme/            Design system: app_colors, app_spacing, app_radii,
│  │  │                    app_typography, app_semantic_colors, app_theme
│  │  └─ widgets/          feature_gate, loading_view, error_view
│  ├─ features/
│  │  ├─ auth/             Firebase Auth + Google Sign-In
│  │  ├─ home/             home screen with note list
│  │  ├─ legal/            terms / privacy viewer
│  │  ├─ notes/            Note model, Hive + Firestore repos, sync, list/detail UI, player
│  │  ├─ onboarding/       first-run flow
│  │  ├─ paywall/          RevenueCat-backed paywall + entitlements
│  │  ├─ recording/        mic capture + amplitude polling + quota pre-flight
│  │  ├─ settings/         settings screen
│  │  ├─ transcription/    Dio client for /api/transcribe (typed errors)
│  │  └─ usage/            monthly UsageSnapshot model + live Firestore stream
│  └─ shared/              cross-feature providers + services
├─ docs/                   Documentation (see above)
├─ test/                   Flutter unit + widget tests (61 tests, all passing)
│  ├─ core/
│  │  └─ theme/            Design-system token + ThemeData wiring tests
│  └─ features/
│     ├─ usage/            UsageSnapshot math + currentUtcMonthKey UTC rollover tests
│     └─ transcription/    TranscriptionException / error-kind sanity tests
├─ firestore.rules         Per-user isolation + read-only usage docs + admin-only /config/global
├─ vercel.json             Backend deploy config
├─ package.json            Backend npm deps (openai, formidable, firebase-admin, music-metadata, @vercel/node)
├─ tsconfig.json           TypeScript config for the function
└─ pubspec.yaml            Flutter app deps
```

## Local setup

Prerequisites: Flutter 3.24+, JDK 17, Android SDK 36. See [docs/SETUP.md](docs/SETUP.md) for the full Windows toolchain install.

```powershell
git clone https://github.com/ketankshukla/recapcoach.git
cd recapcoach
flutter pub get
flutter analyze
```

To actually launch the app you need to:

1. Run `flutterfire configure` to overwrite `lib/firebase_options.dart` with **real** Firebase project values.
2. Set the OpenAI API key on the Vercel project (`OPENAI_API_KEY`, encrypted). The app does **not** hold the key.
3. (Pro features) Provide a RevenueCat Android key via `--dart-define=REVENUECAT_ANDROID_KEY=...`.

## Build & run

```powershell
# Real Android device (replace with your device ID from `flutter devices`)
flutter run -d <device-id> --dart-define=BACKEND_URL=https://recapcoach.vercel.app

# Release AAB for Play Store
flutter build appbundle --release --dart-define=BACKEND_URL=https://recapcoach.vercel.app
```

The `--dart-define=BACKEND_URL=...` flag is required for transcription to work. Without it, recordings are saved locally but never transcribed.

See [docs/PUBLISH.md](docs/PUBLISH.md) for the full Play Store closed-testing checklist.

## Tests

```powershell
# Flutter unit + widget tests (61 tests, runs in ~10 seconds)
flutter test

# Static analysis (zero issues in app code; existing infos are pre-existing)
flutter analyze --no-fatal-infos

# TypeScript type-check on the Vercel backend
npm run build

# Full Vercel build pipeline (run before pushing api/* or vercel.json changes).
# Cold ~60-120s, warm ~10-20s. Requires one-time CLI setup — see
# docs/14-vercel-cli-setup.md.
npm run vercel:build
```

The complete test catalogue (current + planned) lives in
[docs/11-test-plan.md](docs/11-test-plan.md). It enumerates ~120 tests
across unit / widget / integration / backend layers, with payment + quota
scenarios listed first because those guard real money.

## License

All rights reserved © Ketan Shukla. Not open source.
