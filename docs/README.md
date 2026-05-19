# RecapCoach Documentation

This folder holds everything you need to understand, develop, and ship RecapCoach.

The documents are split into two groups:

1. **Development chapters** — a chronological build log of how the app was constructed. Read these in order if you want to understand the codebase from scratch.
2. **Operational guides** — setup, publishing, and legal templates you reach for when shipping.

---

## Development chapters (read in order)

| #   | Chapter                                                      | Summary                                                                                                                                          |
| --- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 01  | [Overview](01-overview.md)                                   | What RecapCoach is, who it's for, the stack, current status, and what works end-to-end today.                                                    |
| 02  | [Initial scaffold](02-scaffold.md)                           | The starter project (Flutter + Riverpod + Firebase + RevenueCat) — what came pre-wired before feature work began.                                |
| 03  | [Audio recording + local notes](03-audio-recording.md)       | The `record` package, amplitude meter, Hive-backed `NoteRepository`, and the record/detail UI.                                                   |
| 04  | [Transcription backend](04-transcription-backend.md)         | The Vercel serverless `/api/transcribe` endpoint (Whisper + gpt-4o-mini) and the Flutter `TranscriptionService` that calls it.                   |
| 05  | [Playback + amplitude bug fix](05-playback-and-amplitude.md) | Adding `just_audio` playback to the detail screen and fixing the amplitude meter dying after the first recording.                                |
| 06  | [Cloud sync](06-cloud-sync.md)                               | Firestore-backed text sync so notes survive uninstall/reinstall and follow the user across devices.                                              |
| 07  | [Architecture](07-architecture.md)                           | Full data-flow diagram, layer responsibilities, and the rationale for major decisions.                                                           |
| 08  | [Roadmap](08-roadmap.md)                                     | What's still open, prioritized, with effort estimates.                                                                                           |
| 09  | [Quotas & safety](09-quotas-and-safety.md)                   | Hybrid pricing model, per-plan caps, server-side quota enforcement, Firestore data model, kill switch.                                           |
| 10  | [Financial projections](10-financial-projections.md)         | Exact revenue + cost math at 1K / 10K / 100K / 1M users, sensitivity analysis, additional safety + profit levers.                                |
| 11  | [Test plan](11-test-plan.md)                                 | Full catalogue of ~120 tests (unit / widget / integration / backend) including all payment + quota scenarios. Priority order for shipping.       |
| 12  | [Solo developer playbook](12-solo-developer-playbook.md)     | The realistic operational guide for running a paid app alone: support load by scale, anti-feature-creep rules, runbook, mental-health protocols. |
| 13  | [UI design system](13-ui-design-system.md)                   | Phase 0 foundation: color palette (deep navy + warm amber), spacing, radii, typography, semantic tokens, Material 3 wiring.                      |
| 14  | [Vercel CLI setup](14-vercel-cli-setup.md)                   | Local pre-deploy verification: how to install + auth the Vercel CLI and run `npm run vercel:build` before pushing backend changes.               |

## Operational guides

| Doc                                                      | Use it when                                                                             |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [SETUP.md](SETUP.md)                                     | Setting up the Windows toolchain (Flutter, JDK, Android SDK, FlutterFire) from scratch. |
| [PUBLISH.md](PUBLISH.md)                                 | Publishing to Google Play closed testing / production.                                  |
| [14-vercel-cli-setup.md](14-vercel-cli-setup.md)         | Auth Vercel CLI on a fresh machine and use `npm run vercel:build` before pushing.       |
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

This snapshot reflects the state of `main` after the **UI overhaul Phase 1 — Home screen** milestone:

- Firebase ID token auth on `/api/transcribe` (chapter 04 + 08).
- Hybrid pricing model with server-side quotas, kill switch, and live usage meter in the app (chapter 09).
- Financial projections + test plan + solo-developer playbook (chapters 10-12).
- UI design system — navy + amber palette, spacing/radii/typography tokens, semantic colors, Material 3 wiring (chapter 13).
- Local pre-deploy `vercel build` wired up via `npm run vercel:build` (chapter 14). Auth via gitignored `secrets/vercel-cli-token`.
- **Phase 1 home screen shipped — premium glass dashboard variant** — animated mesh-gradient background, frosted-glass cards over the mesh, hero stats card (greeting + 3-stat row with circular usage arc), glass note cards with status-color edge accents, amber→gold gradient FAB with heartbeat halo. 12 widgets in `lib/features/home/widgets/` (chapter 13 § 11).
- **Hero stats card now reads server-backed monthly usage** (was: weekly Hive counts). Numbers on the card match the caps the server enforces, eliminating the "19 recordings this week / 5 of 5 cap reached this month" inconsistency.
- **Developer quota bypass** — debug builds and any UID listed in `/config/global.developerUids` skip every cap check on both the client (`lib/core/config/developer.dart`) and the server (`api/_lib/quota.ts`). Cap dialogs, paywall pre-flight, and the usage meter all short-circuit. The hero card renders DEV / unlimited instead of percent-used (chapter 09 § Developer bypass).
- **Paywall hang fixed** — empty RevenueCat package list (stub mode in dev) now renders a stub picker instead of spinning forever (`lib/features/paywall/paywall_screen.dart`).
- **Phase 2 glass theme rollout COMPLETE — every secondary screen migrated to the mesh-glass vocabulary.** Paywall + Record + Settings + Note detail + Sign in + Onboarding (chapter 13 § 12). The whole user journey from first launch (Onboarding → Sign in → Home → Record → Note detail → Paywall → Settings) now feels like a single coherent product instead of "the home screen plus a Material 3 settings page."
  - Onboarding: 3 RecapCoach-specific pages (was: generic template copy), 132 dp amber-gradient hero discs with two-layer bloom shadows, amber `WormEffect` page indicator, floating glass `Skip` pill, shared `GradientPillButton` CTA that flips to "Get started" + arrow on the last page.
  - Sign in: amber `_BrandMedal` hero, glass-themed credentials card with `_GlassTextField` (amber-600 focus border, transparent fill), inline `_ErrorChip`, hand-rolled glass `_GoogleButton`.
  - Note detail: header w/ display title + metadata row, redesigned `NotePlayer` (amber-gradient play disc + amber slider), three section `GlassCard`s (Summary / Action items / Transcript) with amber icon avatars + copy-to-clipboard.
  - Settings: four mesh-backed `GlassCard` sections (Account / Subscription / Legal & support / Account actions); destructive Delete uses `GlassAlertDialog(primaryDestructive: true)`.
  - Record: amber `AmplitudePulseMic` with live-amplitude halos, glass timer card, amber `AmplitudeWaveform`, glass discard / Stop & save.
  - Paywall: hero amber medal, glass benefits card, glass product tiles with amber `BEST VALUE` badge.
- Four shared primitives in `lib/core/widgets/glass/`: `GradientPillButton`, `GlassIconButton`, `GlassPillButton`, `GlassAlertDialog`.

Update this doc when you ship the next significant milestone (UI Phase 2 record screen, RevenueCat product wiring, Play Store closed testing, etc.).
