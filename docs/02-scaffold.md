# 02 — Initial scaffold

> **Commit:** `54a4e41` — *chore: initial scaffold of RecapCoach (Flutter + Riverpod + Firebase + RevenueCat starter)*

This chapter documents what came pre-wired in the project **before any RecapCoach-specific features were built**. It saved roughly 1–2 weeks of plumbing work that every modern Flutter app needs.

## What the scaffold provided

### Boilerplate already wired

| Concern | How it was wired |
|---|---|
| **App entry** | `lib/main.dart` initializes Firebase, Hive, SharedPreferences, RevenueCat, Remote Config, Crashlytics — all behind a single `runZonedGuarded` for top-level error capture. |
| **Routing** | `go_router` configured with redirect-based auth gating in `lib/core/router/app_router.dart`. Routes: `/onboarding`, `/sign-in`, `/`, `/paywall`, `/settings`, `/legal/:doc`. |
| **Theme** | Light + dark Material 3 themes in `lib/core/theme/app_theme.dart`. Dark-mode-first design. |
| **Analytics** | `core/analytics/analytics.dart` wraps Firebase Analytics with typed event helpers. |
| **Logging** | `core/logging/logger.dart` provides a global `talker` instance. |
| **Auth** | `features/auth/auth_repository.dart` + `auth_providers.dart` — Google + email/password + anonymous sign-in via Firebase Auth. |
| **Paywall** | `features/paywall/` — RevenueCat configuration, entitlement check (`isProActiveProvider`), and a styled paywall screen. |
| **Onboarding** | `features/onboarding/onboarding_screen.dart` — 3-page intro with `smooth_page_indicator`. |
| **Legal viewer** | `features/legal/legal_viewer_screen.dart` — renders Markdown for terms / privacy. |
| **Settings** | `features/settings/settings_screen.dart` — sign-out, delete account, version info. |
| **Feature gate widget** | `core/widgets/feature_gate.dart` — drops a paywall in front of Pro features with one widget wrap. |
| **Loading + error views** | `core/widgets/loading_view.dart`, `error_view.dart` — consistent fallback UI. |

### Already-installed dependencies

The starter's `pubspec.yaml` included:

- `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` — state + DI + codegen
- `go_router` — navigation
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`, `firebase_messaging`
- `google_sign_in` — OAuth
- `purchases_flutter` — RevenueCat
- `hive`, `hive_flutter`, `shared_preferences`, `path_provider` — local storage
- `dio` — HTTP client
- `talker_flutter`, `talker_riverpod_logger` — observability
- `intl`, `collection`, `freezed_annotation`, `json_annotation`, `uuid` — utilities
- `flutter_launcher_icons`, `flutter_native_splash` — branding tooling

The starter did **not** include `record`, `just_audio`, or `permission_handler` — those were added in subsequent feature phases.

## What was missing (and we added later)

- The **`record` package** for audio recording (added in Phase 2A — see [03-audio-recording.md](03-audio-recording.md))
- The **`just_audio` package** for playback (added in Phase 2E — see [05-playback-and-amplitude.md](05-playback-and-amplitude.md))
- The **`permission_handler` package** for mic permissions (Phase 2A)
- A **`Note` model** + repository — there was no concept of "notes" in the starter
- A **transcription backend** — no AI integration in the starter
- A **recording UI** — the home screen was an empty placeholder
- **Firestore data model + security rules** — Firestore was a dependency but no rules or collections existed

## Build config baked in

| File | What it does |
|---|---|
| `analysis_options.yaml` | Strict lint set: `require_trailing_commas`, `prefer_const_constructors`, `use_build_context_synchronously`, etc. |
| `android/app/build.gradle.kts` | Min SDK 23, target SDK 34, Multidex enabled, signing config wired for release variant. |
| `firebase.json` | Firestore + Storage references. |
| `flutter_launcher_icons:` block | Generates Android launcher icons from `assets/icons/app_icon.png` on `dart run flutter_launcher_icons`. |
| `flutter_native_splash:` block | Generates splash from `assets/icons/splash.png`. |

## Riverpod patterns used

The starter established two patterns that all subsequent feature code follows:

### Pattern 1: Override-after-init providers

For services that need async setup (Hive box, SharedPreferences), the provider declares a throwing default and `main.dart` overrides it after init:

```dart
// In features/notes/note_providers.dart
final noteRepositoryProvider = Provider<NoteRepository>((_) {
  throw UnimplementedError('Override in main.dart');
});

// In main.dart
final noteRepo = await NoteRepository.open(...);
final container = ProviderContainer(
  overrides: [
    noteRepositoryProvider.overrideWithValue(noteRepo),
  ],
);
```

### Pattern 2: Auth-driven redirects via `goRouterProvider`

`go_router`'s `redirect:` reads `authStateProvider` and reroutes unauthenticated users to `/sign-in`. This keeps gating declarative — no manual guards in each screen.

## Next chapter

[03 — Audio recording + local notes](03-audio-recording.md) — adding the `record` package, building the `Note` model, persisting to Hive, and wiring the record/detail UI.
