# 08 — Roadmap

Everything that's still open, ordered roughly by priority. Effort estimates assume continuous focused work.

---

## Tier 1: blockers before any external testing

These must ship before inviting even your first friendly tester. They're either security or trust issues.

### 1.1 Lock down `/api/transcribe` with Firebase ID token auth ✅ SHIPPED

**Why:** Right now the endpoint is fully anonymous. Anyone with the URL can hit it and consume OpenAI credits on your dime.

**What:**

- Client: attach `Authorization: Bearer <FirebaseIdToken>` header to every transcribe request
- Server: verify the token using Firebase Admin SDK; reject with 401 if invalid; extract `uid` and log it

**Status:** Shipped. See `api/_lib/firebase-admin.ts`, `api/transcribe.ts`, `lib/features/transcription/transcription_service.dart`.

### 1.1b Per-plan quotas + kill switch + usage meter ✅ SHIPPED

**Why:** Auth protects against strangers, but authenticated users can still drain the OpenAI budget. Need hard caps + a runtime kill switch + transparent in-app usage so users know where they stand.

**What shipped:**

- `api/_lib/limits.ts` — `FREE_LIMITS` (5 recordings, 3 min each, 15 min/mo) and `PRO_LIMITS` (100 recordings, 20 min each, 8 hr/mo)
- `api/_lib/quota.ts` — Firestore-backed per-user monthly counters + kill switch (`/config/global`)
- `api/_lib/audio-meta.ts` — server-side duration probe via `music-metadata` (can't be spoofed)
- `api/transcribe.ts` — full pipeline gates the OpenAI call on plan + quota + kill switch + size
- `firestore.rules` — `/users/{uid}` and `/users/{uid}/usage/*` are read-only from the client; only the backend writes
- `lib/features/usage/` — `UsageSnapshot` model + Firestore stream
- Home-screen usage meter with progress bar (green / orange / red)
- Record-screen pre-flight check + paywall route when at cap
- `TranscriptionErrorKind` enum for typed UI handling of 429/413/503

See [chapter 09](09-quotas-and-safety.md) for the full design.

### 1.2 Set OpenAI monthly billing cap

**Why:** A single bug, leaked key, or malicious actor could rack up thousands in OpenAI charges before you notice. (Secondary safety on top of 1.1b.)

**What:**

- OpenAI Dashboard → Settings → Limits
- Monthly budget: $20–$50 (whatever feels right for your testing phase)
- Soft notification threshold at 50% of cap

**Effort:** ~2 min, no code.

### 1.3 Privacy policy + terms hosted live

**Why:** Required by Play Store. Also required by GDPR for any user in the EU.

**What:**

- Fill in `docs/PRIVACY_POLICY_TEMPLATE.md` and `docs/TERMS_TEMPLATE.md`
- Host as static pages (GitHub Pages or just markdown in the app via `legal_viewer_screen.dart`)
- Reference in app: Settings → Privacy / Terms

**Effort:** ~1 hour (mostly writing, not coding)

---

## Tier 2: feature gaps that hurt user trust

These don't block testing but hurt retention badly.

### 2.1 Audio cloud sync (Pro feature)

**Why:** Right now, uninstalling the app loses the audio forever. Even though text survives, users with valuable recordings will hate this.

**What:**

- Upload audio to Firebase Storage on note save: `gs://recapcoach-dev/users/{uid}/recordings/{noteId}.m4a`
- Add `cloudAudioUrl` field to `Note`
- On sync pull-down: if local file missing but `cloudAudioUrl` present, download lazily on first playback
- Gate behind Pro entitlement check
- Add progress indicator during upload
- Only upload over Wi-Fi by default (Settings toggle)

**Effort:** ~45 min for the basic upload + sync. Another ~30 min for the Wi-Fi-only toggle, progress UI, and lazy download.

### 2.2 "Reprocess" button on failed/legacy notes

**Why:** If transcription fails (network blip, OpenAI outage, audio too quiet), the note is stuck with "Processing error" forever. Users want a retry.

**What:**

- Add a button to `NoteDetailScreen` when `processingError != null` (or for legacy notes where everything is null)
- Tapping it: re-fires `TranscriptionService.transcribe()`, updates note on success

**Effort:** ~15 min.

### 2.3 Account deletion nukes cloud data

**Why:** Right now `AuthRepository.deleteAccount()` only deletes the Firebase Auth user. Their Firestore notes orphan forever. GDPR violation + cost leak.

**What:**

- Before `user.delete()`, delete all docs under `users/{uid}/**`
- Also delete all blobs under `gs://.../users/{uid}/**` (once 2.1 ships)
- Confirm with the user via a destructive-action dialog

**Effort:** ~20 min.

### 2.4 GDPR data export

**Why:** EU users have a right to download their data. Required by law.

**What:**

- Settings → "Download my data" → zips all transcripts + audio into a file → shares via system share sheet
- Could be a server-side Cloud Function that generates a signed URL

**Effort:** ~1 hour.

---

## Tier 3: polish that earns Play Store featuring

These make the app feel professional, not amateur.

### 3.1 Real app icon + splash

**Why:** The current icon is the Flutter starter placeholder. Looks unprofessional.

**What:**

- Commission or design a 1024×1024 RecapCoach icon (mic + speech-bubble + accent color)
- Adaptive icon variants (foreground + background)
- Place in `assets/icons/app_icon.png` and `app_icon_foreground.png`
- Run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`

**Effort:** ~15 min once you have the artwork. Artwork itself: ~$50 on Fiverr.

### 3.2 Home screen polish

**Why:** It's currently a basic ListView. Needs to feel inviting.

**What:**

- Empty state with helpful illustration + CTA ("Record your first call →")
- Search bar at top (filter by text in transcript or summary)
- Filter chips ("This week", "Has action items", "Failed")
- Pull-to-refresh that retriggers cloud sync
- Long-press a note for batch select + delete

**Effort:** ~30–45 min for the basics.

### 3.3 Note editing

**Why:** Users will want to rename notes ("Call with Acme") and edit/check off action items.

**What:**

- Editable title at top of `NoteDetailScreen`
- Action items become a `CheckboxListTile` list; persist completion state
- Add an "Add manual action item" button

**Effort:** ~30 min.

### 3.4 Tags / categories

**Why:** Beyond ~50 notes, the flat list gets unwieldy.

**What:**

- Add `tags: List<String>?` to `Note` model
- Quick-add UI on detail screen
- Filter chip at top of home screen

**Effort:** ~45 min.

---

## Tier 4: distribution

### 4.1 Play Store closed testing

**Why:** Get real-user feedback before public launch.

**What:** Follow `docs/PUBLISH.md`:

- Create signing key
- Build release AAB
- Set up Play Console listing
- Add internal testers via email
- Set price (or free for now)

**Effort:** ~1–2 hours for the full Play Console dance.

### 4.2 Crashlytics dashboards + alerting

**Why:** Right now Crashlytics is wired but nobody's watching it.

**What:**

- Configure Crashlytics issue alerts → email
- Set up a weekly "crash-free users" review habit

**Effort:** ~10 min.

---

## Tier 5: future ambition (when there's traction)

Skip these until you have at least 100 paying users.

### 5.1 iOS port

Flutter handles 95% of this. Mostly:

- `flutter create . --platforms=ios`
- Set up Apple Developer account ($99/year)
- Configure iOS Firebase project
- Test on actual hardware
- Submit to App Store

**Effort:** ~1 day.

### 5.2 Live transcription (streaming)

Show transcript as it's being recorded. Significantly more complex; requires `gpt-4o-transcribe` (which streams) + websocket plumbing.

**Effort:** ~2 days.

### 5.3 Team / shared workspaces

For consultants in small partnerships. Each team has shared notes, role-based access.

**Effort:** ~1 week, mostly Firestore data model + sharing UI.

### 5.4 Web companion app

Read-only browser interface to view your notes from a laptop.

**Effort:** ~3 days (mostly UI; the Flutter web build mostly works as-is).

### 5.5 Calendar integration

Auto-tag notes with the meeting they came from. Pull from Google Calendar API.

**Effort:** ~2 days.

---

## What NOT to do

Worth being explicit about, since these are tempting but bad ideas at this stage:

- **Don't add a server-side database** — Firestore is plenty.
- **Don't migrate off Vercel** — until you're north of 1000 daily transcriptions, the free tier is fine.
- **Don't replace Whisper with self-hosted models** — costs ~$0.06/call. You'd need 1000+ calls/day before it's worth running your own GPU.
- **Don't build Android Wear / iOS Watch apps** — solo consultants are not the watch demographic.
- **Don't add real-time collaborative editing** — your users are solo. They don't need it.

---

## Suggested next-session sequence

Auth + quotas are done. The next session is the **UI overhaul** — RecapCoach
should _look_ like a paid product before we ask anyone to pay.

If you have ~2 hours, do this in order:

1. **2 min** — 1.2 OpenAI billing cap (manual, Vercel dashboard)
2. **30 min** — UI: themed color palette (warm professional), typography (Inter or Geist), and Material 3 expressive components on home/record/detail screens
3. **30 min** — UI: real recording-screen waveform (`AnimatedBuilder` + amplitude history buffer), refined empty state with illustration
4. **20 min** — UI: paywall redesign with feature comparison table, "most popular" yearly badge, smooth transitions
5. **10 min** — UI: settings redesign with sectioned cards + subscription status surface
6. **5 min** — commit + push + tag a release: `v0.3.0`

After that, the next big chunks are:

- **RevenueCat product wiring** (Tier 3 below): create products in Play Console, configure entitlements, wire the actual purchase flow. Without this, no one can become Pro.
- **Audio cloud sync** (2.1): so users don't lose recordings on uninstall.
- **Play Store closed testing** (4.1): real users, real feedback.
