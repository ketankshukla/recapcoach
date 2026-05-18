# 08 — Roadmap

Everything that's still open, ordered roughly by priority. Effort estimates assume continuous focused work.

---

## Tier 1: blockers before any external testing

These must ship before inviting even your first friendly tester. They're either security or trust issues.

### 1.1 Lock down `/api/transcribe` with Firebase ID token auth

**Why:** Right now the endpoint is fully anonymous. Anyone with the URL can hit it and consume OpenAI credits on your dime.

**What:**
- Client: attach `Authorization: Bearer <FirebaseIdToken>` header to every transcribe request
- Server: verify the token using Firebase Admin SDK; reject with 401 if invalid; extract `uid` and log it

**Effort:** ~30 min (Firebase Admin SDK setup + middleware + client header)

**Side benefit:** server-side per-user logging becomes possible, enabling future per-user quotas.

### 1.2 Set OpenAI monthly billing cap

**Why:** A single bug, leaked key, or malicious actor could rack up thousands in OpenAI charges before you notice.

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

If you have ~2 hours of focused time next session, do this:

1. **30 min** — 1.1 Firebase ID token auth on `/api/transcribe`
2. **2 min** — 1.2 OpenAI billing cap
3. **45 min** — 2.1 Audio cloud sync (the basic version, not the polished one)
4. **15 min** — 2.2 Reprocess button
5. **20 min** — 2.3 Account deletion nukes cloud data
6. **5 min** — commit + push + tag a release: `v0.2.0`

That's a defensibly-shippable closed-testing build.
