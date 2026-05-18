# 09 — Quotas, Plan Limits & Safety Net

This chapter covers the monetization safety layer added on top of the
Firebase-authenticated `/api/transcribe` endpoint.  Auth (chapter 04 + 08)
protected the OpenAI key from anonymous attackers.  This phase protects it
from *authenticated* users — both honest free users who'd be expensive to
support unlimited, and any single bad actor who tries to drain the wallet
through one signed-in account.

---

## Why this exists

OpenAI bills RecapCoach.  Users do not have OpenAI accounts and never will.
Every Whisper call is paid for from one credit card.  Therefore:

- **Auth** keeps strangers off the endpoint.
- **Quotas** keep signed-in users inside an envelope you can afford.

Without quotas, a single viral TikTok ("free unlimited AI transcription!")
could cost thousands before anyone notices.

---

## The Hybrid pricing model

| Tier | Price | Caps | Max cost / user / mo | Plan margin |
|---|---|---|---|---|
| **Free** | $0 | 5 recordings, 3 min each, 15 min total | ~$0.09 | (CAC) |
| **Pro Monthly** | $7.99 | 100 recordings, 20 min each, 8 hr total | ~$2.88 | ~58% |
| **Pro Yearly** | $49.99 | same as Pro Monthly | ~$2.88 / mo equivalent | higher retention |

Cost basis: Whisper $0.006/min + Google Play subscription fee 15%.

The free tier is intentionally narrow.  3-minute clips force users to taste
the product, hit the wall, and either upgrade or churn — both acceptable
outcomes.  The Pro tier is wide enough that 95% of real users will never
notice the cap.

---

## Architecture

```
Flutter client                   Vercel /api/transcribe                Firestore
─────────────                    ─────────────────────                 ─────────
record audio  ──── POST ───►     0. verify Firebase ID token  ◄────── /users/{uid}
                                 1. loadQuotaContext():               /config/global
                                     - read /config/global  (kill switch + overrides)
                                     - read /users/{uid}    (plan)
                                     - read usage/{YYYY-MM} (counters)
                                 2. parse multipart (maxFileSize per plan)
                                 3. probe audio for real duration
                                 4. assertWithinMonthlyQuota()
                                 5. call Whisper + gpt-4o-mini
                                 6. recordUsage() ──── writes ───────► usage/{YYYY-MM}
                                                                        atomic FieldValue.increment
◄──── 200 + transcript + usage payload, OR 429 / 413 / 503 / 401
```

The client streams `/users/{uid}/usage/{YYYY-MM}` over Firestore to render
a live meter; it cannot write that doc (firestore.rules locks it down).

---

## Files

### Server

- **`api/_lib/limits.ts`** — single source of truth for `FREE_LIMITS` /
  `PRO_LIMITS` (recording length, monthly seconds, monthly count, max file
  bytes).  Also exports `currentMonthKey()` returning `YYYY-MM` UTC.
- **`api/_lib/quota.ts`** — `loadQuotaContext`, `assertFileSizeAllowed`,
  `assertWithinMonthlyQuota`, `recordUsage`, plus `QuotaExceededError` and
  `TranscriptionDisabledError`.  Reads `/config/global`, `/users/{uid}`,
  `/users/{uid}/usage/{YYYY-MM}` via Firebase Admin (bypasses rules).
- **`api/_lib/audio-meta.ts`** — `probeAudioFile()` decodes the uploaded
  audio with `music-metadata` (pure JS, no native deps) and returns the
  actual duration in seconds.  Client-reported duration is ignored — only
  bytes-on-disk count.
- **`api/transcribe.ts`** — orchestrates: auth → load quota → parse upload
  → probe duration → quota assert → Whisper → gpt-4o-mini → recordUsage.
  Sends the user a refreshed `usage` payload in every 200 response so the
  client UI updates immediately.

### Client

- **`lib/features/usage/usage.dart`** — `UsageSnapshot` model with mirrored
  plan limits and helpers (`secondsProgress`, `recordingsProgress`,
  `isAtCap`, `remainingMinutesLabel`).  These constants MUST stay in sync
  with `api/_lib/limits.ts`.
- **`lib/features/usage/usage_provider.dart`** — `monthlyUsageProvider`
  streams `/users/{uid}/usage/{YYYY-MM}` and combines it with the
  RevenueCat-driven `entitlementProvider`.
- **`lib/features/home/home_screen.dart`** — adds `_UsageMeter` card showing
  `usedMin / limitMin` and `usedCount / limitCount` with a progress bar that
  turns orange at 80% and red when capped.  When capped on free, surfaces
  an inline "Upgrade" CTA.
- **`lib/features/recording/record_screen.dart`** — pre-flight check in
  `_autoStart()`: if `monthlyUsageProvider.value.isAtCap` and `plan != 'pro'`,
  show a quota dialog and route to the paywall before the mic even opens.
- **`lib/features/transcription/transcription_service.dart`** — adds
  `TranscriptionErrorKind` enum (`quotaExceeded`, `fileTooLarge`,
  `disabled`, `unauthorized`, `other`) mapped from HTTP status codes so the
  UI can specialize the message.

### Security rules

- **`firestore.rules`** — `/users/{uid}` and `/users/{uid}/usage/{monthKey}`
  are now **read-only from the client**; only the backend (service account)
  can write them.  Notes (`/users/{uid}/notes/{noteId}`) remain CRUD by the
  owner.  `/config/global` is admin-only on both reads and writes.

---

## Firestore data model

```
/users/{uid}
  plan: 'free' | 'pro'                  # mirrored from RevenueCat webhook (future)
  ...

/users/{uid}/notes/{noteId}
  ...existing fields...

/users/{uid}/usage/{YYYY-MM}            # one doc per month, in UTC
  transcriptionSeconds: number           # atomic increment
  recordingsCount:      number           # atomic increment
  lastTranscriptionAt:  Timestamp        # serverTimestamp()
  plan:                 'free' | 'pro'   # plan at time of last write

/config/global                           # admin-only, optional
  transcriptionEnabled:  bool            # kill switch
  freeOverride:          PlanLimits?     # runtime override
  proOverride:           PlanLimits?
```

`YYYY-MM` keys are **UTC** so all users roll over at the same instant
(midnight UTC on the 1st of each month).  No "midnight in user's timezone"
edge cases.

---

## The kill switch

Flip `/config/global.transcriptionEnabled` to `false` in the Firebase
Console and `/api/transcribe` immediately returns 503 to every caller, no
deploy needed.  Use it if:

- OpenAI is having an outage and you'd rather refund minutes than serve
  errors.
- You discover a cost-leak bug at 2am and need to stop the bleeding before
  fixing it.
- You're running a beta and want to pause new transcriptions during a
  migration.

Default behaviour: if the `/config/global` doc doesn't exist, the backend
treats it as `transcriptionEnabled: true`.

---

## Error responses (the contract)

| Status | When | Body shape |
|---|---|---|
| 200 | success | `{ transcript, summary, actionItems, usage }` |
| 400 | bad upload / corrupt audio | `{ error }` |
| 401 | missing / invalid Firebase ID token | `{ error }` |
| 413 | file exceeds plan's `maxFileBytes` | `{ error, reason, plan, limits, used }` |
| 429 | quota exceeded — DO NOT RETRY | `{ error, reason, plan, limits, used }` |
| 503 | global kill switch flipped | `{ error }` |
| 500 | OpenAI down / server misconfigured | `{ error }` |

`reason` is one of `kill_switch`, `recording_too_long`, `file_too_large`,
`monthly_minutes`, `monthly_recordings` — the client uses it to choose the
right user-facing message.

---

## Operational notes

- **Per-month rollover happens instantly at midnight UTC.**  The previous
  month's doc remains in Firestore for audit; the new month starts at zero.
  Storage cost: ~12 docs/user/year, trivial.
- **`recordUsage()` is best-effort.**  If Firestore write fails AFTER a
  successful Whisper call, the request still returns 200.  The user already
  got their value; failing the response would mean we paid OpenAI for
  nothing.
- **Plan changes (Pro → Free downgrade) take effect immediately** on the
  user's next request because the backend reads `/users/{uid}.plan` fresh
  every call.  No caching.
- **Counters never decrement.**  Refunds, cancellations, etc. do not roll
  back usage.  The next month starts fresh.

---

## What's NOT here yet

- **RevenueCat → Firestore webhook.**  Currently `/users/{uid}.plan` has to
  be flipped manually (or by future tooling) to mark someone Pro.  Until the
  webhook is wired, the backend treats everyone as Free.  See roadmap item
  3.1 RevenueCat product wiring.
- **OpenAI billing alert.**  Set `$10/day` and `$50/month` thresholds in
  OpenAI dashboard → Limits.  This is a 2-minute manual setup, not code.
- **Top-ups.**  ("$2.99 for 2 extra hours.")  Deferred until the Pro flow
  is proven; would add `bonusSeconds` to the usage doc.

---

## Cost ceiling math

Worst-case monthly outflow at N installs, assuming everyone hits their cap:

| Users | Free at $0.09 | Pro at $2.88 (cost) | Pro revenue ($6.79 net) |
|---|---|---|---|
| 1,000 free | $90 | — | — |
| 10,000 free | $900 | — | — |
| 100 Pro | — | $288 cost | $679 revenue |
| 1,000 Pro | — | $2,880 cost | $6,790 revenue |

The free tier is uncapped in *user count* but capped per user.  A million
free users would cost ~$90,000/month if all of them maxed out — but at that
scale you're a viral hit and conversion economics dominate.  Defensible.
