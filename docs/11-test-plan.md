# 11 — Test Plan

This is the test contract for RecapCoach. Every user-facing behavior that
could plausibly go wrong is listed here, with a test that proves it
doesn't.

The goal is **deterministic confidence**: if every test in this document
passes, the app does not have a known way to fail. We add tests when we
find a new failure mode, and we never delete them.

---

## TL;DR — the test pyramid

```
                       /\
                      /  \    integration_test/   ← ~5 tests (slowest, most realistic)
                     /----\                         end-to-end flows on a real device
                    /      \  test/widget          ← ~20 tests (medium)
                   /--------\                        single screens with mocked providers
                  /          \ test/unit           ← ~80+ tests (fastest, run on every save)
                 /____________\                     pure functions, models, providers
                /              \ api/__tests__     ← ~15 tests
               /________________\                   Vercel backend (Jest)
```

Total target: **~120 tests**. Most are unit tests, which run in milliseconds.
The whole suite should complete in under 60 seconds on a laptop.

**Current state (after UI overhaul Phase 1 — glass dashboard):** 124
tests passing, ~13 seconds to run. Breakdown:

- 21 design-system token + theme-wiring tests (`test/core/theme/`)
- 40 monetization tests (`test/features/usage/` + `test/features/transcription/`)
- 63 glass-dashboard home widget tests (`test/features/home/widgets/`)
- 1 sanity smoke test (`test/widget_test.dart`)

Closing in on the ~120 target. The remaining gaps are mostly the
backend Jest layer (B1.\* tests), the in-progress UI overhaul phases
2-6, and a few integration tests for the recording → transcription
round-trip.

**Definition of done for any new feature:** ships with tests for the unit
layer at minimum. Widget tests for any new screen. Integration tests when
the feature crosses 3+ layers (e.g. paywall purchase flow).

---

## 1. Payment & quota test cases (priority #1)

These are the tests that protect your wallet. They're listed first because
this is the layer most likely to leak money if it breaks. Anything marked
**[CRITICAL]** must always pass before pushing to `main`.

### 1.1 Plan-limit math (unit, `test/features/usage/`)

Test the pure-Dart math in `UsageSnapshot`. No Flutter, no Firebase, just
calculations.

| #       | Test                                                                                  | Expected                                                       |
| ------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| U1.1.1  | **[CRITICAL]** Free plan defaults match server-side `api/_lib/limits.ts`              | 15 min, 5 recordings, 3 min/recording                          |
| U1.1.2  | **[CRITICAL]** Pro plan defaults match server-side `api/_lib/limits.ts`               | 8 hr (28,800 s), 100 recordings, 20 min/recording              |
| U1.1.3  | Empty snapshot has 0 used, 0% progress, not at cap                                    | usedSeconds = 0, secondsProgress = 0.0, isAtCap = false        |
| U1.1.4  | Snapshot at 50% returns 0.5 progress                                                  | secondsProgress = 0.5                                          |
| U1.1.5  | Snapshot at 100% returns 1.0 progress and isAtCap = true                              | secondsProgress = 1.0, isAtCap = true                          |
| U1.1.6  | Snapshot above 100% (defensive) clamps to 1.0                                         | secondsProgress = 1.0                                          |
| U1.1.7  | `worstProgress` returns the higher of the two meters                                  | max(secondsProgress, recordingsProgress)                       |
| U1.1.8  | **[CRITICAL]** `isAtCap = true` when recordings count >= limit, even if minutes are 0 | (you used 5/5 recordings of 0 min each → still capped)         |
| U1.1.9  | **[CRITICAL]** `isAtCap = true` when seconds >= limit, even if recordings are 0       | (1 recording of 16 min on free → still capped)                 |
| U1.1.10 | `remainingMinutesLabel` formats < 1 min as seconds                                    | "30s"                                                          |
| U1.1.11 | `remainingMinutesLabel` formats minutes correctly                                     | "7m 30s", "5m"                                                 |
| U1.1.12 | `remainingMinutesLabel` formats hours correctly                                       | "1h 15m", "8h"                                                 |
| U1.1.13 | `currentUtcMonthKey()` produces YYYY-MM in UTC                                        | "2026-05" regardless of local timezone                         |
| U1.1.14 | `currentUtcMonthKey()` rolls over at UTC midnight, not local midnight                 | Tested with a date forced to 11pm local / 2am UTC              |
| U1.1.15 | `isDeveloper` defaults to `false` on regular snapshots                                | New `UsageSnapshot(...)` without flag => `isDeveloper = false` |
| U1.1.16 | **[CRITICAL]** Developer bypass: `isAtCap == false` even with both caps exceeded      | 99 recordings / 9999 s on free => `isAtCap = false`            |
| U1.1.17 | Developer bypass: `secondsProgress`, `recordingsProgress`, `worstProgress` all = 0    | Hero arc renders empty / DEV ring                              |
| U1.1.18 | Developer bypass: `UsageSnapshot.empty()` propagates `isDeveloper`                    | `empty(isDeveloper: true).isAtCap == false`                    |
| U1.1.19 | Developer bypass: `UsageSnapshot.fromFirestore()` propagates `isDeveloper`            | Real Firestore payload + flag => bypass holds                  |
| U1.1.20 | Developer bypass intentionally does NOT alter `remaining*` getters                    | Documents the dead-code-path decision (see chapter 09)         |
| U1.1.21 | `GlobalConfigSnapshot.empty` defaults: transcription enabled, no developers           | `transcriptionEnabled = true`, `developerUids = []`            |
| U1.1.22 | `GlobalConfigSnapshot.fromFirestore(null)` returns the empty default                  | Same as `.empty`                                               |
| U1.1.23 | Parses `transcriptionEnabled = false` explicitly                                      | Kill-switch state mirrored                                     |
| U1.1.24 | Defensive: non-bool `transcriptionEnabled` defaults to `true`                         | Misconfigured field doesn't kill transcription                 |
| U1.1.25 | Parses `developerUids` as a list of strings                                           | `['uid-a', 'uid-b']` => same                                   |
| U1.1.26 | Drops empty strings, nulls, and non-strings from `developerUids`                      | Mixed list filtered to valid UIDs only                         |
| U1.1.27 | Non-iterable `developerUids` (e.g. raw string) falls back to empty list               | No accidental char-splitting / coercion                        |
| U1.1.28 | **[CRITICAL]** Absent `developerUids` => empty list (no accidental dev mode)          | Missing field never grants bypass                              |

### 1.2 Quota enforcement (backend, `api/__tests__/quota.test.ts`)

These run on the Vercel backend in Jest, mocking Firestore.

| #       | Test                                                                                                                   | Expected                                        |
| ------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| B1.2.1  | **[CRITICAL]** Missing `/users/{uid}` doc defaults plan to `free`                                                      | plan = 'free'                                   |
| B1.2.2  | **[CRITICAL]** `users/{uid}.plan = 'pro'` reads back as 'pro'                                                          | plan = 'pro'                                    |
| B1.2.3  | Missing `/config/global` doc treats transcription as enabled                                                           | enabled = true                                  |
| B1.2.4  | **[CRITICAL]** `/config/global.transcriptionEnabled = false` throws `TranscriptionDisabledError`                       | throws                                          |
| B1.2.5  | **[CRITICAL]** Free user uploading 4-min file (limit 3 min) throws QuotaExceededError with reason `recording_too_long` | throws, reason correct                          |
| B1.2.6  | **[CRITICAL]** Free user at 5/5 recordings throws QuotaExceededError with reason `monthly_recordings`                  | throws, reason correct                          |
| B1.2.7  | **[CRITICAL]** Free user at 14m used + 2m incoming (would be 16m > 15m cap) throws with reason `monthly_minutes`       | throws, reason correct                          |
| B1.2.8  | Pro user at 90 recordings can still upload                                                                             | passes                                          |
| B1.2.9  | Pro user uploading 20-min file (exactly at cap) passes                                                                 | passes                                          |
| B1.2.10 | Pro user uploading 21-min file throws `recording_too_long`                                                             | throws                                          |
| B1.2.11 | **[CRITICAL]** `recordUsage` atomically increments both counters via `FieldValue.increment`                            | Firestore mock verifies merge: true + increment |
| B1.2.12 | `recordUsage` failure does not throw (best-effort)                                                                     | resolves even if Firestore mock rejects         |
| B1.2.13 | **[CRITICAL]** `/config/global.freeOverride` is applied on top of `FREE_LIMITS`                                        | limits use override values                      |
| B1.2.14 | File size cap: 5 MB + 1 byte upload by free user throws `file_too_large`                                               | throws                                          |
| B1.2.15 | Month rollover: usage from May does not bleed into June counters                                                       | June read returns 0                             |

### 1.3 Transcription pipeline (backend, `api/__tests__/transcribe.test.ts`)

| #       | Test                                                                                                           | Expected                             |
| ------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| B1.3.1  | **[CRITICAL]** Missing Authorization header → 401                                                              | status 401                           |
| B1.3.2  | **[CRITICAL]** Invalid Firebase ID token → 401                                                                 | status 401                           |
| B1.3.3  | Valid token but kill switch on → 503                                                                           | status 503                           |
| B1.3.4  | Valid token, no audio field → 400                                                                              | status 400                           |
| B1.3.5  | **[CRITICAL]** Free user over monthly seconds → 429, reason `monthly_minutes`, body includes `limits` + `used` | status 429, body correct             |
| B1.3.6  | **[CRITICAL]** Free user over monthly recordings → 429, reason `monthly_recordings`                            | status 429                           |
| B1.3.7  | **[CRITICAL]** Free user uploading 6 MB → 413, reason `file_too_large`                                         | status 413                           |
| B1.3.8  | **[CRITICAL]** Successful transcription increments usage counters                                              | counters increment                   |
| B1.3.9  | **[CRITICAL]** Successful transcription returns `usage` payload in 200 body                                    | usage object present, correct values |
| B1.3.10 | Empty audio (no speech detected) returns 200 with empty transcript, still counts usage                         | counters increment                   |
| B1.3.11 | OpenAI 5xx failure → response 500 with helpful error                                                           | status 500, file cleanup happened    |
| B1.3.12 | GPT-4o-mini failure but Whisper succeeded → 200 with transcript and warning                                    | status 200, warning present          |

### 1.4 Client-side payment flow (widget, `test/features/paywall/`)

These use mock `purchases_flutter` and mock `entitlementProvider`.

| #      | Test                                                                                         | Expected            |
| ------ | -------------------------------------------------------------------------------------------- | ------------------- |
| W1.4.1 | Paywall screen shows monthly + yearly tiers                                                  | both visible        |
| W1.4.2 | **[CRITICAL]** Tapping "Subscribe Monthly" calls `PurchasesService.purchasePackage(monthly)` | mock invoked        |
| W1.4.3 | **[CRITICAL]** Tapping "Subscribe Yearly" calls `PurchasesService.purchasePackage(yearly)`   | mock invoked        |
| W1.4.4 | **[CRITICAL]** Purchase success updates entitlement provider to `true`                       | provider emits true |
| W1.4.5 | Purchase cancellation does NOT update entitlement                                            | provider unchanged  |
| W1.4.6 | **[CRITICAL]** "Restore purchases" button calls `PurchasesService.restore()`                 | mock invoked        |
| W1.4.7 | Restore that finds Pro entitlement updates provider                                          | provider emits true |
| W1.4.8 | Restore that finds nothing shows "No previous purchase found" snackbar                       | snackbar visible    |
| W1.4.9 | Purchase failure (declined card) shows error UI, does not crash                              | error visible       |

### 1.5 Quota UI integration (widget, `test/features/home/`, `test/features/recording/`)

| #      | Test                                                                                  | Expected                                    |
| ------ | ------------------------------------------------------------------------------------- | ------------------------------------------- |
| W1.5.1 | Usage meter renders 0/15 min at 0%                                                    | progress = 0.0                              |
| W1.5.2 | Usage meter renders 12/15 min at 80% (orange)                                         | progress = 0.8, color = orange              |
| W1.5.3 | Usage meter renders 15/15 min at 100% (red) + shows Upgrade button                    | red + button visible                        |
| W1.5.4 | **[CRITICAL]** Tapping FAB on home → record screen pre-flight check fires             | dialog OR mic permission OR both            |
| W1.5.5 | **[CRITICAL]** Free user at cap who taps Record sees quota dialog, NOT mic permission | dialog visible, controller.start NOT called |
| W1.5.6 | Pro user at cap... does NOT see dialog (Pro caps are advisory only in UI)             | controller.start called                     |
| W1.5.7 | Quota dialog "Upgrade" button routes to paywall                                       | router pushed to /paywall                   |
| W1.5.8 | Quota dialog "Not now" button just dismisses                                          | record screen popped                        |

### 1.6 Transcription error mapping (unit, `test/features/transcription/`)

| #      | Test                                                             | Expected                |
| ------ | ---------------------------------------------------------------- | ----------------------- |
| U1.6.1 | HTTP 401 → `TranscriptionErrorKind.unauthorized`                 | correct enum            |
| U1.6.2 | HTTP 413 → `TranscriptionErrorKind.fileTooLarge`                 | correct enum            |
| U1.6.3 | **[CRITICAL]** HTTP 429 → `TranscriptionErrorKind.quotaExceeded` | correct enum            |
| U1.6.4 | HTTP 503 → `TranscriptionErrorKind.disabled`                     | correct enum            |
| U1.6.5 | HTTP 500 → `TranscriptionErrorKind.other`                        | correct enum            |
| U1.6.6 | Network error (no response) → `TranscriptionErrorKind.other`     | correct enum            |
| U1.6.7 | Server error message in body is preserved on the exception       | `message` field correct |

---

## 2. Auth & sign-in flow

| #    | Test                                                    | Layer       | Expected           |
| ---- | ------------------------------------------------------- | ----------- | ------------------ |
| U2.1 | `AuthRepository.authState()` emits null when signed out | unit        | null               |
| U2.2 | `AuthRepository.authState()` emits User when signed in  | unit        | non-null User      |
| W2.1 | Sign-in screen shows Google button                      | widget      | button visible     |
| W2.2 | Successful Google sign-in routes to home                | widget      | route changed      |
| W2.3 | Failed sign-in stays on sign-in screen, shows error     | widget      | error visible      |
| W2.4 | Anonymous users see paywall-restricted features locked  | widget      | feature_gate locks |
| I2.1 | Full flow: cold start → sign-in → home shows user email | integration | email visible      |
| I2.2 | Sign-out from settings → routed back to sign-in         | integration | route changed      |

---

## 3. Recording flow

| #    | Test                                                                               | Layer       | Expected                         |
| ---- | ---------------------------------------------------------------------------------- | ----------- | -------------------------------- |
| U3.1 | `RecordingController.start()` requests mic permission                              | unit        | permission API called            |
| U3.2 | `RecordingController.start()` returns false on permission denied                   | unit        | false                            |
| U3.3 | `RecordingController.stop()` returns file path + duration                          | unit        | non-null result                  |
| U3.4 | `RecordingController.cancel()` deletes the partial file                            | unit        | file gone                        |
| U3.5 | Amplitude polling produces values in -60..0 dB range                               | unit        | all in range                     |
| W3.1 | Record screen shows "Preparing..." then "Recording..."                             | widget      | label sequence correct           |
| W3.2 | **[CRITICAL]** Stop with duration < 1.5s shows "too short" snackbar, no note saved | widget      | snackbar visible, repo unchanged |
| W3.3 | Stop with duration > 1.5s saves a note and pops                                    | widget      | note saved, route popped         |
| W3.4 | Cancel button discards the recording without saving                                | widget      | nothing saved                    |
| W3.5 | Permission denied dialog appears when permission rejected                          | widget      | dialog visible                   |
| I3.1 | Full flow: tap record → wait 5s → stop → note appears on home with "Processing..." | integration | note visible                     |
| I3.2 | Phone call interrupts recording — note saved with what was captured                | integration | note has partial audio           |

---

## 4. Transcription background flow

| #    | Test                                                                              | Layer       | Expected                           |
| ---- | --------------------------------------------------------------------------------- | ----------- | ---------------------------------- |
| U4.1 | `TranscriptionService.transcribe()` throws when `BACKEND_URL` unset               | unit        | TranscriptionException, kind=other |
| U4.2 | `TranscriptionService.transcribe()` throws when user not signed in                | unit        | TranscriptionException             |
| U4.3 | `TranscriptionService.transcribe()` attaches Bearer token header                  | unit        | mocked Dio sees header             |
| U4.4 | Successful response is parsed into `TranscriptionResult`                          | unit        | fields match                       |
| U4.5 | Response with `warning` field is preserved                                        | unit        | warning passed through             |
| W4.1 | After recording, note appears with `isProcessing = true`                          | widget      | spinner visible                    |
| W4.2 | After transcription succeeds, note shows summary + action items                   | widget      | summary visible                    |
| W4.3 | After transcription fails (429), note shows quota error + retry button            | widget      | error + button                     |
| W4.4 | "Retry transcription" button on failed note re-fires the request                  | widget      | mock invoked                       |
| I4.1 | Full flow: record → home shows processing → poll for completion → summary appears | integration | summary visible within 30s         |

---

## 5. Note list, detail, search

| #    | Test                                                          | Layer       | Expected                |
| ---- | ------------------------------------------------------------- | ----------- | ----------------------- |
| U5.1 | `NoteRepository.upsert()` writes to Hive                      | unit        | box has the doc         |
| U5.2 | `NoteRepository.delete()` removes from Hive                   | unit        | box empty               |
| U5.3 | `NoteRepository.all()` returns notes sorted by createdAt desc | unit        | order correct           |
| U5.4 | `Note.copyWith(clearError: true)` nukes processingError       | unit        | field is null           |
| W5.1 | Home screen shows empty state when no notes                   | widget      | \_EmptyState visible    |
| W5.2 | Home screen lists notes with summary                          | widget      | tile per note           |
| W5.3 | Tapping a note routes to detail screen                        | widget      | route changed           |
| W5.4 | Note detail shows transcript, summary, action items           | widget      | all visible             |
| W5.5 | Note detail with processingError shows error + retry          | widget      | error visible           |
| W5.6 | Playback controls render and respond to taps                  | widget      | just_audio mock invoked |
| I5.1 | 100 notes in the list — scroll perf is smooth                 | integration | no jank > 16ms          |

---

## 6. Cloud sync

| #    | Test                                                                  | Layer       | Expected                      |
| ---- | --------------------------------------------------------------------- | ----------- | ----------------------------- |
| U6.1 | `NoteCloudRepository.upsert()` writes to `users/{uid}/notes/{noteId}` | unit        | mocked Firestore path correct |
| U6.2 | `NoteSyncService.syncForUser(uid)` clears local cache on UID change   | unit        | local box cleared             |
| U6.3 | `NoteSyncService` pulls cloud notes into local                        | unit        | local has cloud notes         |
| U6.4 | `NoteSyncService` pushes local-only notes up                          | unit        | mocked cloud.upsert called    |
| I6.1 | Sign in on a fresh device → cloud notes appear within 10s             | integration | notes visible                 |
| I6.2 | Offline → record → online → note syncs to cloud                       | integration | cloud has note                |

---

## 7. Account & data lifecycle

| #    | Test                                                                             | Layer       | Expected                        |
| ---- | -------------------------------------------------------------------------------- | ----------- | ------------------------------- |
| W7.1 | Settings → "Delete account" shows confirmation dialog                            | widget      | dialog visible                  |
| W7.2 | **[CRITICAL]** Confirmed account deletion clears local Hive                      | widget      | box empty                       |
| W7.3 | **[CRITICAL]** Confirmed account deletion deletes all `/users/{uid}/**` docs     | widget      | mocked Firestore batch verified |
| W7.4 | **[CRITICAL]** Confirmed account deletion calls `user.delete()` on Firebase Auth | widget      | mock called                     |
| W7.5 | Sign-out preserves local data (does NOT clear Hive)                              | widget      | box still has notes             |
| I7.1 | Full flow: delete account → sign-in screen → re-sign-in shows empty home         | integration | empty state                     |

---

## 8. Edge cases & resilience

| #    | Test                                                                                | Layer       | Expected                 |
| ---- | ----------------------------------------------------------------------------------- | ----------- | ------------------------ |
| U8.1 | App handles malformed Note JSON in Hive (corrupt cache)                             | unit        | logs + drops the row     |
| U8.2 | App handles Firestore permission-denied gracefully                                  | unit        | error surfaced, no crash |
| U8.3 | App handles `record` package returning null path                                    | unit        | error surfaced           |
| W8.1 | App killed mid-recording: on relaunch, partial file is gone                         | widget      | file path null           |
| W8.2 | Network drops mid-transcribe: note shows error + retry available                    | widget      | error visible            |
| I8.1 | Run app on slow 3G network — recording still works, transcribe times out gracefully | integration | error shown              |
| I8.2 | Phone clock changes timezone mid-month — usage meter still reads correct month      | integration | correct month doc        |

---

## 9. Backend infrastructure tests (`api/__tests__/`)

These are Jest tests for the Vercel function code, with mocked `firebase-admin`
and mocked `openai`. They run on every PR via GitHub Actions.

| #    | Test                                                                | Expected                              |
| ---- | ------------------------------------------------------------------- | ------------------------------------- |
| B9.1 | `firebase-admin.ts` initializes once and reuses the app             | second call returns cached app        |
| B9.2 | `firebase-admin.ts` throws clear error when env vars missing        | meaningful error message              |
| B9.3 | `firebase-admin.ts` converts `\n` → real newlines in private key    | PEM parses                            |
| B9.4 | `audio-meta.ts` handles 0-byte file with clear error                | throws "empty"                        |
| B9.5 | `audio-meta.ts` handles unsupported codec with clear error          | throws "could not determine duration" |
| B9.6 | `audio-meta.ts` returns correct duration for known-good M4A fixture | seconds within 0.5 of expected        |
| B9.7 | `limits.ts` `currentMonthKey` returns same key across timezones     | UTC-only                              |
| B9.8 | `limits.ts` `limitsFor('pro')` returns PRO_LIMITS                   | exact match                           |
| B9.9 | `limits.ts` `limitsFor('free')` returns FREE_LIMITS                 | exact match                           |

---

## 10. CI / GitHub Actions setup

The test contract is enforced automatically. Every push to any branch
runs the full suite. PRs cannot merge if any test fails.

`.github/workflows/ci.yml` should run:

```yaml
- name: Flutter tests
  run: flutter test

- name: Flutter analyze
  run: flutter analyze --fatal-infos

- name: Backend type check
  run: npm run build

- name: Backend tests
  run: npm test
```

(The actual workflow file isn't in this repo yet — adding it is part of
the test-plan implementation phase.)

---

## 11. What's NOT tested (deliberately)

Listing exclusions explicitly so you don't feel guilty about them:

- **OpenAI itself.** You can't test that Whisper transcribes correctly —
  that's their job. You test that you _call_ it correctly and _handle_
  its responses correctly.
- **Google Play billing.** RevenueCat handles this; you test that you
  call RevenueCat correctly. You manually test the actual purchase flow
  on a real device before each release.
- **Firebase internals.** You mock Firestore and Auth at the boundary.
- **Network speed / latency.** Test infrastructure should not depend on
  real networks. Mock everything HTTP.
- **UI exact pixel positions.** Goldens are a maintenance nightmare for
  solo devs. Test behavior, not appearance.
- **Animations.** Test that animations don't crash. Don't test their
  feel.

---

## 12. The pragmatic test priority order

You don't have to write all 120 tests at once. Ship them in this order:

1. **§1.1 Plan-limit math** (~12 tests, 1 hour) — done as part of this commit
2. **§1.2 Quota enforcement backend** (~15 tests, 3 hours) — next session
3. **§1.6 Transcription error mapping** (~7 tests, 30 min)
4. **§3 Recording flow unit tests** (~5 tests, 1 hour)
5. **§1.4 Payment flow widget tests** (~9 tests, 2 hours) — _before_ you
   actually go live on Play Store. These protect real money.
6. **§9 Backend infrastructure** (~9 tests, 2 hours)
7. **§7 Account lifecycle** (~5 tests, 1 hour) — _before_ Play Store, GDPR
8. Everything else as you touch the code.

Total: ~15-20 hours of focused test writing. Spread over 2-3 weeks. Then
you have a real safety net for life.

---

## 13. Manual test checklist (before every release)

Some things you can only check by hand. Run this before pushing a new AAB
to Play Store:

```
Build & install
  [ ] flutter clean && flutter pub get
  [ ] flutter build appbundle --release --dart-define=BACKEND_URL=https://recapcoach.vercel.app
  [ ] adb install -r build/app/outputs/bundle/release/app-release.aab

Auth
  [ ] Sign in with Google works
  [ ] Sign out works
  [ ] Delete account works (then re-sign-in shows empty home)

Recording
  [ ] Record a 30-second clip; verify it transcribes within 30s
  [ ] Record a 5-minute clip; verify transcription quality
  [ ] Try to record at free-tier cap; verify Upgrade dialog appears

Payment
  [ ] Open paywall; verify both tiers visible and prices correct
  [ ] Purchase monthly (use Google test card); verify Pro badge appears
  [ ] Verify usage meter now shows Pro limits (100 / 8h)
  [ ] Restore purchases on a different device (test account); verify Pro restores

Edge cases
  [ ] Turn off internet mid-transcribe; verify error + retry works
  [ ] Background the app mid-recording; foreground; verify nothing crashed
  [ ] Sign in on a second device; verify cloud sync pulls notes
```

This is ~30 minutes of human time per release. Worth it.

---

## Last word

You said you're nervous about being one developer. **This document is the
reason you don't need to be.** Tests don't sleep. They don't get tired.
They don't forget the weird thing that broke last month. They run every
time you push, on every branch, forever. The discipline of writing them
once costs hours; the discipline of not writing them costs years.
