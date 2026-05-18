# RecapCoach

**Record consulting calls, instantly get a clean transcript, summary, and action items.**

Built for solo consultants and coaches who want their post-call admin done before the call ends.

## Status

🚧 In active development. Phase 2A (scaffold) — first closed-testing build targeted Q3 2026.

## Stack

- **Mobile**: Flutter (Android first; iOS later)
- **State**: Riverpod
- **Routing**: go_router
- **Backend**: Vercel serverless (Node) → OpenAI Whisper + GPT-4o-mini
- **Persistence**: Firestore (notes), Hive (local cache), SharedPreferences (settings)
- **Auth**: Firebase Auth + Google Sign-In
- **Monetization**: RevenueCat over Play Billing
- **Analytics / Crash**: Firebase Analytics + Crashlytics
- **Foundation**: scaffolded from a private starter (`flutter_app_kit`)

## Project layout

```
lib/
├─ main.dart                  Entry; wires Firebase, Hive, Riverpod, RevenueCat
├─ app.dart                   Root MaterialApp.router
├─ core/
│  ├─ analytics/              Firebase Analytics wrapper
│  ├─ config/                 env vars, app config
│  ├─ logging/                talker logger
│  ├─ router/                 go_router config
│  ├─ theme/                  light/dark Material theme
│  └─ widgets/                feature_gate, loading_view, error_view
├─ features/
│  ├─ auth/                   sign-in, auth providers
│  ├─ home/                   home screen
│  ├─ legal/                  terms / privacy viewer
│  ├─ onboarding/             first-run flow
│  ├─ paywall/                RevenueCat-backed paywall + entitlements
│  └─ settings/               settings screen
└─ shared/                    cross-feature providers + services
```

## Local setup

Prerequisites: Flutter 3.24+, JDK 17, Android SDK 36 (see `docs/SETUP.md` for full toolchain install on Windows).

```powershell
git clone https://github.com/ketankshukla/recapcoach.git
cd recapcoach
flutter pub get
flutter analyze
```

To actually launch the app you need to:

1. Run `flutterfire configure` to overwrite `lib/firebase_options.dart` with real Firebase project values.
2. Provide an OpenAI API key on the **Vercel backend** (not in the app — see backend repo, separate).
3. (Pro features) provide a RevenueCat Android key via `--dart-define=REVENUECAT_ANDROID_KEY=...`.

## Build & run

```powershell
# Web (smoke test, no native plugins)
flutter run -d chrome

# Android (real device or emulator)
flutter run -d <device-id>

# Release AAB for Play Store
flutter build appbundle --release
```

See `docs/PUBLISH.md` for the full Play Store closed-testing checklist.

## License

All rights reserved © Ketan Shukla. Not open source.
