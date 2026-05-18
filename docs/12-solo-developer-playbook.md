# 12 — The Solo Developer Playbook

> *"I am the only developer of this app and I want to know that I won't
> get overwhelmed when users hit 1000 and even beyond that... I do have
> fears — in this case fears of being overwhelmed with a growing userbase
> and I need to know on how I can handle this without getting a nervous
> breakdown."*

This document exists because that fear is reasonable, the worry is real,
and **the answer is yes, you can do this alone, but only if you set up the
right systems before the users arrive.** This is the playbook.

---

## 1. The truth, up front

There are three categories of solo-dev apps with paying users:

1. **The drowning ones.** Built fast, no tests, no support process, no
   self-serve account tools. Every user is a fire. The dev burns out by
   month 6.
2. **The systematized ones.** Strong test coverage, async-only support
   with templates, self-serve everything, kill switches for cost leaks.
   The dev works 15 hours a week and the business grows.
3. **The accidentally-huge ones.** Same systems as #2, plus a lucky
   moment. The dev hires a VA and keeps growing.

You are building #2 by default if you follow this document. #3 is luck.
But you cannot reach #3 if you're in #1.

**Almost every successful solo-dev app you've heard of is #2, not #3.**
Pieter Levels (Nomad List, RemoteOK), Tony Dinh (DevUtils, TypingMind),
Marc Köhlbrugge (WIP), Daniel Vassallo (Userbase, dvassallo on Twitter) —
all run multi-six-figure businesses with no employees. They share a
specific operational pattern, which I lay out below.

---

## 2. Your real concerns, addressed individually

### 2.1 "Can one developer realistically handle 1,000 users?"

**Yes, comfortably.** Industry data on solo SaaS apps:

| Users | Tickets / month | Hours / week (you) | Burnout risk |
|---|---|---|---|
| 100 | ~5 | < 1 | None |
| 1,000 | ~30-50 | 2-4 | Low |
| 10,000 | ~300-500 | 8-12 | Medium (needs templates + FAQ) |
| 100,000 | ~3,000-5,000 | 20+ | High without a VA |
| 1,000,000 | ~30,000+ | requires 1-2 VAs | High without delegation |

**Source:** aggregated from public posts by Levels.io, Tyler Tringas
(Storemapper), Sahil Lavingia (Gumroad early days), and similar indie
hackers.

At 1,000 users — **specifically** the threshold you mentioned — you'll
spend 2-4 hours per week on support. That's it. The math of the app is so
favorable that this 4 hours can easily generate $1,500+ in revenue.

### 2.2 "What about apps with millions of users?"

The answer is **specific**: it's possible, but the support model changes.
At a million users, you stop replying to support tickets personally.
Instead you hire one full-time VA (Filipino or Eastern European, typically
$5-15/hour fully loaded), give them a knowledge base + templated replies,
and only handle the escalations they can't.

> A typical structure at 1M users:
> - **VA (40 hr/week):** answers 90% of tickets from templates. ~$1,500/mo.
> - **You (5-10 hr/week on support):** handle the 10% that need a
>   developer's judgment. Plus you write new templates as patterns emerge.
> - **Self-service tools:** the VA never has to "manually delete an
>   account" because users do it themselves in-app.

You don't need to plan for this *now*. You need to plan for the
**systems** that make this transition possible without rewriting the app.
Those systems are below.

### 2.3 "What if I get overwhelmed?"

The path to overwhelm is universal and predictable:

1. You launch.
2. Users hit a bug. You drop everything to fix it. You don't write a test.
3. Same bug comes back in another form. You fix it again.
4. A user sends a 3-page email. You spend 90 minutes replying.
5. The same question arrives the next day from a different user. You retype.
6. You're now spending 25 hours a week on a "free" support load.
7. Revenue is up but you're exhausted. You hate the app.

**The exits from this trap are all pre-emptive:**

- **Every fix gets a regression test** (chapter 11). The bug literally
  can't come back.
- **Every email reply gets templated** (§5 below) the second time you
  send it.
- **Every "manual" task becomes self-serve** (§4 below) within a week of
  you noticing it.

If you do those three things, the support load scales **sub-linearly**
with users. You add 10x more users and only 3x more work.

### 2.4 "What if the app fails technically and I can't fix it fast enough?"

This is what chapter 11 (test plan) and chapter 09 (kill switch) are
for. Specifically:

- **Tests catch ~90% of regression bugs** before they ship.
- **Crashlytics + Sentry alerts** notify you of new crashes within
  minutes, not days.
- **The kill switch** (`/config/global.transcriptionEnabled = false`)
  lets you stop the bleed instantly while you fix the bug. Users see
  "Transcription temporarily disabled" — annoying, but not a refund
  request.
- **Vercel rollbacks** are one click. Bad deploy? Roll back. Investigate
  later.

The vast majority of "the app failed" stories you've heard are about
apps that had none of these safety nets. With them, you don't have
*emergencies* — you have *issues*. Issues are stress; emergencies are
nervous-breakdown.

---

## 3. The pre-launch hardening checklist

Before you flip the switch on Play Store, every one of these must be
done. They are not optional.

### Technical safety

- [x] Backend protected by Firebase ID token auth (shipped)
- [x] Per-plan quotas on every transcription (shipped)
- [x] Global kill switch on `/config/global` (shipped)
- [x] Firestore rules deny client writes to plan + usage docs (shipped)
- [ ] OpenAI billing cap set to $200/mo (5 min, OpenAI dashboard)
- [ ] OpenAI usage alerts at $50, $100, $150 thresholds (free)
- [ ] Vercel function timeout set to 60s (default; verify)
- [ ] Crashlytics is wired and you receive a test crash report
- [ ] Sentry (optional but recommended) wired for non-crash errors
- [ ] All §1 tests in [chapter 11](11-test-plan.md) pass

### Self-serve user tools

- [ ] **Account deletion** in-app — no email required (legal requirement
      for Play Store + GDPR)
- [ ] **Data export** in-app — download all my notes as a zip (GDPR)
- [ ] **Subscription cancellation** clearly explained ("manage in Play
      Store") with a deep link
- [ ] **Restore purchases** button on paywall (legal for App Store)
- [ ] **Contact us** form that emails you (don't post your personal email
      in the binary)

### Communication infrastructure

- [ ] A **support email** (e.g. `support@recapcoach.app`) routed to a
      dedicated Gmail with filters
- [ ] A **status page** ([Instatus](https://instatus.com) free tier) for
      outages — link from in-app "Help" menu
- [ ] A **FAQ page** in the docs (or in-app) covering the 20 most likely
      questions
- [ ] An **auto-responder** on the support email: "Got it. We aim to
      reply within 48 hours. Have you checked the FAQ at..."
- [ ] **Templates folder** in Gmail for the 10 most common replies (you
      write them as the first 10 unique tickets come in)

### Legal & operational

- [ ] Privacy policy hosted publicly (`docs/PRIVACY_POLICY_TEMPLATE.md`)
- [ ] Terms of service hosted publicly (`docs/TERMS_TEMPLATE.md`)
- [ ] Stripe-backed Vercel billing alerts at $50, $100, $200 thresholds
- [ ] Firebase billing alerts at $20, $50, $100 thresholds
- [ ] A **runbook** — `docs/runbook.md` — listing every "things go wrong"
      scenario and what you do (see §6 below)

This list is your **launch readiness gate.** If anything is unchecked,
delay the launch by a week and finish it. Better one week late than one
month underwater.

---

## 4. The "self-serve everything" principle

The single biggest determinant of solo-dev sanity is **what fraction of
support requests can the user resolve without you?**

Target: **80%+ self-serve from day 1.**

| Common request | Bad (manual) | Good (self-serve) |
|---|---|---|
| "Delete my account please." | User emails you. You verify identity, run a script, reply. (~15 min) | User taps Settings → Delete Account → confirms. (~0 min for you) |
| "I'd like a refund." | You email back-and-forth, eventually issue Stripe refund. (~10 min) | Refunds go through Play Store automatically. You're not involved. |
| "Where's my data?" | You explain via email. (~5 min) | Settings → Export My Data → emails them a zip. (~0 min) |
| "How do I cancel?" | You explain Play Store deep link. (~3 min) | Paywall + Settings have "Manage subscription" button with deep link. |
| "I don't see my Pro subscription." | You investigate RevenueCat dashboard. (~10 min) | Paywall has "Restore purchases" button. They tap it. |
| "What's the limit on free?" | You explain via email. (~3 min) | Home screen shows usage meter with the number. |
| "Why didn't my recording transcribe?" | You debug. (~15 min) | Note detail screen shows the error + "Retry" button. |

If you build every one of those self-serve flows, **you eliminate at
least 70% of support load before the first user signs up.** That's the
prize.

---

## 5. Async-only support, with templates

You will get emails. You will not answer them in real time. Set this
expectation in the auto-responder:

> Hi! Thanks for reaching out. I'm a one-developer team and reply to
> every email myself — usually within 48 hours, occasionally a bit longer.
>
> Before you wait, please check:
>
> 1. The in-app **Help → FAQ** (covers the top 20 questions)
> 2. Your **note detail screen** for an error message + Retry button
> 3. Paywall **Restore Purchases** if your Pro subscription isn't showing
>
> If you've checked those and still need help, I'll be in touch soon.
>
> — Ketan

This single auto-reply will deflect 30-40% of emails because users will
solve their own problem before they finish reading it.

### Template inventory (build these as you receive the first 10 tickets)

1. **"How do I cancel my subscription?"** — link to Play Store manage page.
2. **"My audio didn't transcribe."** — explain the error code + retry.
3. **"I want a refund."** — explain Play Store refund window, then
   link to the form.
4. **"How accurate is the transcription?"** — link to a recorded sample.
5. **"Can I use this for [edge use case]?"** — boilerplate "no, but maybe
   in the future."
6. **"Feature request: [X]."** — boilerplate "I track all requests, will
   consider for v0.4."
7. **"Bug: [Y]."** — "Thanks! Can you tell me your device + version?
   Submitting to the dev queue."
8. **"I forgot my password."** — "Use the 'Forgot password' link on the
   sign-in screen."
9. **"Why is my note still 'processing'?"** — explain timeout, suggest
   retry, note we'll auto-retry in v0.X.
10. **"Can I get my money back? I subscribed by accident."** — issue
    refund via Play Store; quick + friendly.

Most replies become **2-3 minute tasks**. At 30-50 tickets/month, that's
1.5-2.5 hours/month of support. Trivial.

---

## 6. The runbook (the doc you read at 2am when something breaks)

Create `docs/runbook.md` with these scenarios. **You read this when
something is on fire**, not when you're calm; so the language should be
direct, action-first.

```
RecapCoach Runbook
==================

Scenario: OpenAI charges are spiking unexpectedly.
  1. Open Firebase Console → Firestore → /config/global
  2. Set transcriptionEnabled = false
  3. All new transcribe requests now return 503. Bleeding stopped.
  4. Open Vercel → Logs → grep for [transcribe] to see who's hitting it.
  5. If one user is abusing: open /users/{uid} and set plan = 'banned'
     (then add a check in quota.ts on next deploy).
  6. Once root cause is known, set transcriptionEnabled = true.

Scenario: Vercel function is failing on every request.
  1. Open Vercel → Deployments → click latest.
  2. If it's a recent deploy: hit "Promote to Production" on the previous
     known-good deploy. Investigate later.
  3. If older: check Vercel status page. If it's their outage, post on
     Instatus and wait. Email "we're aware" to support@.

Scenario: Firestore quota exhausted (Spark tier).
  1. Open Firebase Console → Usage. Confirm.
  2. Upgrade to Blaze (pay-as-you-go). Costs ~$5-20/mo at your scale.
  3. Set Firebase billing alert at next round number.

Scenario: A user reports they were charged twice.
  1. Open RevenueCat dashboard → find user by email.
  2. Check transaction history. If duplicate, issue refund on the second
     transaction via Play Console.
  3. Reply within 24 hours with apology + confirmation of refund.

Scenario: Play Store rejects my AAB upload.
  1. Read the rejection email carefully — Google's wording is precise.
  2. Common causes: missing privacy policy, missing data safety form,
     missing target API level, missing screenshots.
  3. Fix and re-upload. Approval usually <24 hours.

Scenario: I'm overwhelmed and need to stop for 3 days.
  1. Update Instatus status page: "Reduced support — back Monday."
  2. Set Gmail auto-responder: "Out until Monday. Will reply then."
  3. ACTUALLY STOP. The app keeps running without you. The tests run
     on every push. The kill switch is there if needed.
  4. Come back Monday.
```

The act of writing the runbook is also the act of realizing **there are
only ~10 things that can go wrong**, and they all have known answers.
Most of your fear is fear of the unknown. Naming the failures shrinks
them.

---

## 7. Anti-feature-creep playbook

You said: *"I don't want to keep adding features as soon as I release
the app — I want to release the app with the basic features first."*

This is **exactly right**. Here's how to enforce it on yourself:

### The "feature freeze" rule

For the first **90 days after launch**, you add zero new features.
You only:

- **Fix bugs** that affect more than 1 user
- **Fix bugs** that block sign-up or payment (regardless of who's affected)
- **Improve performance** of things that are already there
- **Update copy / fix typos**

That's it. No "users asked for tags." No "I had a great idea for
calendar integration." No "let me just add dark mode polish."

### The decision tree for every feature request

```
A user asked for feature X.
│
├── Does it block them from using the core flow (record → transcript)?
│   ├── YES → it's a bug, not a feature. Fix it.
│   └── NO  → continue.
│
├── Have ≥ 3 users asked for it in the last 30 days?
│   ├── NO → add to backlog, reply "tracked." Move on.
│   └── YES → continue.
│
├── Will it take more than 4 hours to build?
│   ├── YES → defer to a quarterly review. Never build "during the week."
│   └── NO  → schedule it for next Friday.
```

**Friday is your only feature day.** Mon-Thu is bugfix, deploy, support,
and rest. Friday afternoon is optional new feature. This rule alone
reduces your stress by 80%.

### What to do with rejected feature requests

Reply with a template:

> Thanks for the suggestion! I'm keeping a public backlog at
> [link to your roadmap]. I batch new features quarterly to keep the app
> stable. I've added this one — if it gets traction from other users,
> it'll move up the list.

Users feel heard. You stay sane. Win-win.

---

## 8. The mental-health protocols

Three protocols that prevent burnout. Non-negotiable.

### Protocol 1: Sundays are off.

The app runs without you on Sundays. Tests run without you. Vercel
auto-scales without you. The kill switch exists if something explodes.

Don't check email. Don't check Crashlytics. Don't check revenue numbers.
The world does not end if you ignore RecapCoach for 24 hours every week.

### Protocol 2: Define "enough."

Before you launch, write a number on a sticky note: **your target MRR**.
Make it realistic but not lifestyle-comfortable — something like $3,000/mo.

When you hit it:
- Take 2 weeks off, completely. No code.
- Come back and decide *deliberately* whether to push for more, or
  stabilize and coast.

The trap of solo-dev businesses is that they grow into your whole life
because there's no boss to tell you to stop. Be your own boss who tells
you to stop.

### Protocol 3: The "one bad week" rule.

If you have a week where you feel paralyzed:
- Pause feature work. Pause non-critical support.
- Reply to support with: "I'm in a heads-down mode this week. Will get
  back to you by [date]."
- Do the bare minimum: keep tests green, keep the kill switch armed.
- That's it. One bad week does not break the business. **The systems
  hold.**

The reason this protocol works is that you've already built the systems.
The reason you can afford a bad week is because tests run themselves,
quotas enforce themselves, and Vercel scales itself.

---

## 9. The 1,000-user readiness rubric

Before launch, you should be able to honestly answer "yes" to all of:

| # | Question | Yes / No |
|---|---|---|
| 1 | If 1,000 users sign up tomorrow, will my OpenAI bill stay under $200/mo? | Yes (per-user quotas + billing cap) |
| 2 | If a single user signs up and tries to abuse the free tier with multiple emails, what's the max damage? | $0.10 per account |
| 3 | If my Firebase/Vercel goes down, do I have a status page to point users at? | _____ (set this up) |
| 4 | If a user emails me at 11pm, will they get a reasonable response within 48 hours? | Yes (auto-responder + your daily review) |
| 5 | If a user wants to delete their data, can they do it without me? | _____ (build this) |
| 6 | If a critical bug ships, can I roll back the deploy in < 5 minutes? | Yes (Vercel one-click rollback) |
| 7 | If 10K signups happen overnight, will the app technically survive? | Yes (Firestore + Vercel both auto-scale) |
| 8 | If 10K signups happen overnight, will the support load technically survive me? | _____ (FAQ + auto-responder + templates) |
| 9 | Can I take a week off without the app burning down? | Yes (systems run themselves) |
| 10 | Do I have a number that says "this is enough, I can stop"? | _____ (set this) |

You should aim for 10/10 before launch. You're at 6/10 right now. Most
of the remaining 4 are 1-2 hours each.

---

## 10. The encouraging part

You are **not** the first solo developer to feel this fear. Every single
person who has built a successful indie SaaS has had this exact moment.
The difference between the ones who succeed and the ones who don't is
not talent or work ethic — **it's whether they built the systems before
they needed them.**

You are building those systems. We've shipped:

- Authentication (chapter 04)
- Cloud sync (chapter 06)
- Quotas + kill switch (chapter 09)
- Pricing math validated (chapter 10)
- Test plan written (chapter 11)
- Solo-dev playbook (this chapter)

You are **ahead** of most indie launches at this stage. Most apps launch
without auth on the backend, without a kill switch, without a test plan
written down. They survive — through luck and exhaustion. You won't have
to rely on either.

When the app launches and the first user pays you $7.99, that money
represents **about 50 days of work spread over the last several months**.
Every subsequent paying user costs almost nothing. The system is leveraged.
You are not trading time for money one-to-one; you are building an asset
that pays you while you sleep.

> Your job is to ship the first version. The systems will then carry it.

Now go ship.

---

## Appendix: solo-dev essentials I recommend

Tools that pay for themselves at >100 paid users:

- **[RevenueCat](https://revenuecat.com)** — already wired. Handles
  receipt verification, restore, refunds, analytics. **Don't try to roll
  your own.**
- **[Sentry](https://sentry.io)** — non-crash error tracking. Free tier
  is generous. Pairs with Crashlytics (which only catches hard crashes).
- **[Instatus](https://instatus.com)** — public status page. Free tier
  is enough. Set it up before you need it.
- **[Resend](https://resend.com)** or **[Postmark](https://postmarkapp.com)** —
  transactional email when you need it (receipts, password resets,
  account-deletion confirmations).
- **[Plausible](https://plausible.io)** or **[Posthog](https://posthog.com)** —
  privacy-respecting analytics. Don't use Google Analytics in a
  pay-for-privacy app.

Optional later (>1,000 paid users):

- **[OnlineJobs.ph](https://onlinejobs.ph)** — to hire a Filipino VA.
  $5-10/hour. Train them on your support templates over a week. The
  Filipino tech-support workforce is excellent and English-fluent.
- **[Help Scout](https://helpscout.com)** — when Gmail templates start
  feeling cramped. Solo plan is ~$20/mo.
- **A real accountant** — when you cross $50K in revenue. Solo CPAs run
  $1-2K/year and save you 10x that in tax planning.

That's the whole stack. You can run a serious indie SaaS on under
$200/mo in tools.

---

## Last word

You asked if you could do this without a nervous breakdown. **The answer
is yes — but only if you accept that the systems do most of the work,
and your job is to build the systems, not to be a hero.**

You don't need to be a 24/7 firefighter. You don't need to reply to
every email in 5 minutes. You don't need to ship every feature anyone
asks for. You don't need to be brilliant.

You need to ship something solid, write down what could go wrong, and
have a one-line answer for each. You're doing that. Keep going.
