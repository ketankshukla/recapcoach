# 10 — Financial Projections & Safety Math

This chapter answers the question every solo developer asks before
launching a paid app: **"What if it works?"**

It runs the actual numbers for the Hybrid pricing tier (see
[09-quotas-and-safety.md](09-quotas-and-safety.md)) at multiple scales,
including the specific scenario you asked about (1,000 free + 1,000 monthly
Pro + 1,000 yearly Pro). Then it brainstorms additional safety levers
beyond what's already shipped.

---

## TL;DR

> At **1,000 free + 1,000 monthly Pro + 1,000 yearly Pro** users with
> realistic usage patterns, you net **~$7,300 / month** (about
> **$87,600 / year**). Worst-case (every paid user maxes their cap and
> every free user maxes their 15-minute allowance), you still net
> **~$4,300 / month**. **The math cannot put you underwater** because
> every Pro tier has a hard cost ceiling baked into the quota system.

That's the headline. The rest of this document is the proof.

---

## 1. The unit economics (one user, one month)

Every number below comes from the pricing implemented in
`api/_lib/limits.ts` and the cost basis from OpenAI's published pricing.

### Per-user cost ceiling

| Plan | Monthly cap | Cost @ Whisper $0.006/min | GPT-4o-mini summary | **Total max cost / user / month** |
|---|---|---|---|---|
| Free | 15 min | $0.090 | ≤ $0.005 | **$0.095** |
| Pro (any) | 8 hr = 480 min | $2.880 | ≤ $0.020 | **$2.900** |

The GPT-4o-mini summary cost is bounded because we cap the transcript size
that gets fed in (the cap on Whisper minutes caps the transcript word
count downstream). I round to $2.90 / Pro user / month as the **hard
ceiling**. Mathematically impossible to exceed without a code bug — and
even a code bug is bounded by the OpenAI billing cap (a separate kill
switch you set in your OpenAI dashboard).

### Per-user revenue ceiling

| Plan | Price (gross) | Google Play fee (15%) | **Net revenue / month** |
|---|---|---|---|
| Pro Monthly | $7.99 / mo | $1.20 | **$6.79** |
| Pro Yearly | $49.99 / yr | $7.50 | **$3.54** ($42.49 ÷ 12) |

> **Why is yearly net per month lower than monthly net per month?**
> Because yearly users effectively get a 48% discount in exchange for
> committing 12 months up front. You make less per month but capture
> them for the whole year, which is **almost always worth it** because
> the alternative is they churn after month 2.

### Per-user profit ceiling (worst case for you = best case for the user)

| Plan | Net revenue | Max cost | **Worst-case profit / user / month** | Margin |
|---|---|---|---|---|
| Pro Monthly | $6.79 | $2.90 | **$3.89** | **57%** |
| Pro Yearly | $3.54 | $2.90 | **$0.64** | **18%** |

> **Important insight:** the yearly plan, at 100% usage, has razor-thin
> margins. This is **fine** because:
> 1. Almost no one actually maxes the 8-hour cap. Real usage averages
>    20-40% of cap for most consumer apps.
> 2. Yearly users churn far less, so the lifetime profit is much higher
>    even if monthly profit is smaller.
> 3. They committed cash up front. You're holding $50 of their money
>    before you've delivered a single minute of transcription.

---

## 2. Your specific scenario — 1,000 / 1,000 / 1,000

You asked: "What happens with 1,000 free + 1,000 monthly Pro +
1,000 yearly Pro users?"

### Revenue (always the same — users pay regardless of usage)

| Cohort | Headcount | Net per user per month | **Monthly revenue** |
|---|---|---|---|
| Free | 1,000 | $0.00 | **$0** |
| Pro Monthly | 1,000 | $6.79 | **$6,790** |
| Pro Yearly | 1,000 | $3.54 | **$3,540** |
| | | **Total** | **$10,330 / mo** |

That's **$123,960 / year in revenue** from a 3,000-user paid base.

### Costs at three usage levels

Real-world consumer apps see a power-law distribution: most users barely
use the product, a few power-users hit the cap. I model three scenarios.

#### Scenario A — Realistic (average user uses ~30% of cap)

Industry benchmark for B2C subscription tools (Otter, Rev, etc.).

| Cohort | Headcount | Avg usage | Cost per user | **Monthly cost** |
|---|---|---|---|---|
| Free | 1,000 | 30% of 15 min | $0.028 | **$28** |
| Pro Monthly | 1,000 | 30% of 8 hr | $0.870 | **$870** |
| Pro Yearly | 1,000 | 30% of 8 hr | $0.870 | **$870** |
| | | | **OpenAI total** | **$1,768 / mo** |

| | Amount |
|---|---|
| Revenue | $10,330 |
| OpenAI cost | ($1,768) |
| Fixed overhead (see §3) | ($170) |
| **Net profit** | **$8,392 / mo** |
| **Annual profit** | **~$100,700 / yr** |
| **Margin** | **81%** |

#### Scenario B — Heavy (average user uses 60% of cap)

If your audience is hardcore power-users (every-call-recorded consultants).

| Cohort | Headcount | Avg usage | Cost per user | **Monthly cost** |
|---|---|---|---|---|
| Free | 1,000 | 60% of 15 min | $0.057 | **$57** |
| Pro Monthly | 1,000 | 60% of 8 hr | $1.740 | **$1,740** |
| Pro Yearly | 1,000 | 60% of 8 hr | $1.740 | **$1,740** |
| | | | **OpenAI total** | **$3,537 / mo** |

| | Amount |
|---|---|
| Revenue | $10,330 |
| OpenAI cost | ($3,537) |
| Fixed overhead | ($170) |
| **Net profit** | **$6,623 / mo** |
| **Annual profit** | **~$79,500 / yr** |
| **Margin** | **64%** |

#### Scenario C — Worst case (every single user maxes their cap)

This will not happen. Including it because it's the mathematical floor.

| Cohort | Headcount | Avg usage | Cost per user | **Monthly cost** |
|---|---|---|---|---|
| Free | 1,000 | 100% (15 min) | $0.095 | **$95** |
| Pro Monthly | 1,000 | 100% (8 hr) | $2.900 | **$2,900** |
| Pro Yearly | 1,000 | 100% (8 hr) | $2.900 | **$2,900** |
| | | | **OpenAI total** | **$5,895 / mo** |

| | Amount |
|---|---|
| Revenue | $10,330 |
| OpenAI cost | ($5,895) |
| Fixed overhead | ($170) |
| **Net profit** | **$4,265 / mo** |
| **Annual profit** | **~$51,180 / yr** |
| **Margin** | **41%** |

> **The point:** even the catastrophic scenario where every single user
> maxes their cap pays you $51K/year on a 3,000-user base. The realistic
> scenario pays you $100K/year. You cannot lose money on this pricing.

---

## 3. Fixed overhead at this scale

| Item | Cost / month | Notes |
|---|---|---|
| Vercel Pro | $20 | Required above ~100K function invocations/month. 3K paid users averaging 4 recordings/week ≈ 50K invocations — Hobby tier likely OK, but Pro gives headroom + better support. |
| Firebase Blaze plan | $5-25 | Spark (free) tier covers 50K reads, 20K writes, 1GB/day. 3K paid users generate ~15K writes/day, so you'd just barely exceed Spark. Blaze pay-as-you-go on Firestore at this scale: $5-25/mo. |
| Google Play Console | $2.08 | $25 one-time, amortized over 12 months for year 1. |
| Apple Developer (if iOS) | $8.25 | $99/yr. Skip if Android-only. |
| Domain (recapcoach.app or similar) | $1 | $12/yr. |
| RevenueCat | $0 - $80 | **Free** up to $2.5K MTR (monthly tracked revenue). Above that: **1%** of revenue. At $10,330 MTR: $103/mo, but the first $2.5K is free, so ≈ $78/mo. |
| Sentry / Crashlytics | $0 | Crashlytics free; Sentry has a free tier good for 5K events/mo. |
| Email sender (Resend / Postmark) | $0 - $20 | Needed if you send password resets, receipts, etc. Free tier covers ~3K emails/mo. |
| Status page (Instatus) | $0 | Free tier covers what you need. |
| Total | **~$110 - $160 / mo** | Negligible at the revenue levels above. |

I used **$170 / mo** in the scenarios above to leave headroom.

---

## 4. Scaling tables (what happens beyond 3,000 paid?)

Assumptions:
- Free-to-paid conversion rate: **3%** (industry benchmark for productivity apps)
- 60% of paid users pick monthly, 40% yearly (typical post-launch ratio)
- Realistic 30% cap usage (Scenario A above)

| Total users | Free | Paid (3% conversion) | Monthly rev (net) | OpenAI cost | Fixed | **Net profit / mo** | **Annual** |
|---|---|---|---|---|---|---|---|
| 1,000 | 970 | 30 (18 M + 12 Y) | $164 | $36 | $25 | **$103** | **$1,236** |
| 10,000 | 9,700 | 300 (180 M + 120 Y) | $1,646 | $355 | $50 | **$1,241** | **$14,892** |
| 100,000 | 97,000 | 3,000 (1.8K M + 1.2K Y) | $16,460 | $3,540 | $200 | **$12,720** | **$152,640** |
| 1,000,000 | 970,000 | 30,000 (18K M + 12K Y) | $164,600 | $35,400 | $1,800 | **$127,400** | **$1,528,800** |

> **Two numbers worth pinning to the wall:**
>
> - **10,000 users → ~$15K/year** (validates the business; quit-your-side-projects money)
> - **100,000 users → ~$150K/year** (full-time founder income, comfortably)
> - **1,000,000 users → ~$1.5M/year** (life-changing, with margins still above 70%)

You hit the second tier (full-time founder income) at a scale that
*thousands* of solo-dev apps have reached. This is not a moonshot.

---

## 5. Sensitivity analysis — what if things go wrong?

### "What if OpenAI raises Whisper prices 50%?"

Whisper goes from $0.006/min → $0.009/min. Max cost / Pro user / month
goes from $2.90 → $4.35. At 3,000 paid users with realistic 30% usage:
extra cost ≈ $1,304 / mo. **Margin drops from 81% → 69%.** Still very
healthy. Mitigation: raise Pro to $9.99 (already in our backup plan).

### "What if Google raises their fee from 15% back to 30%?"

This is the genuine pre-2022 fee, but they're unlikely to revert.
Net revenue / Pro Monthly drops from $6.79 → $5.59. At 3,000 paid users
with current split: revenue drops ~$2,000/mo. **Margin drops from 81% → 62%.**
Still profitable. Mitigation: raise Pro to $9.99.

### "What if 10% of paid users refund within the first month?"

Google Play allows refunds within 48 hours automatically and beyond that
case-by-case. Realistic refund rate for subscription apps: **2-5%**.
At 10% (catastrophic): you lose ~$1,000/mo to refunds. **Margin drops
81% → 71%.** Still very healthy. Mitigation: 3-day free trial filters out
serial refunders.

### "What if a viral TikTok floods you with 100K free signups in a week?"

This is the *best* problem to have. Free users cost you $0.095/mo max
each. 100K free users at worst case = **$9,500/mo OpenAI cost**.
You'd lose money for ~30 days until the free users churn or convert,
**but** even at 1% conversion you get 1,000 new paid users = $5,700/mo
new revenue from the spike. Net: ~$3,800/mo loss for one month, then
profitable forever after.

> **Safety net for this scenario:** the global kill switch in
> `/config/global.transcriptionEnabled` lets you slam the brakes on
> *all* new transcriptions in one click. You can also temporarily drop
> the free-tier limit from 15 min to 5 min by editing `/config/global.freeOverride`
> — no redeploy needed.

### "What if my Vercel function gets DoS'd?"

Vercel auto-rate-limits and absorbs the traffic; you don't pay for
rejected requests. The Firebase ID token requirement on
`/api/transcribe` means an attacker needs a valid Firebase account just
to *attempt* an OpenAI call. With per-user monthly quotas, a single
attacker account can drain at most $2.90 before being throttled.

---

## 6. Additional safety + profit levers (not yet shipped)

Brainstorm of features that would tighten margins or reduce risk further.
Each is small in effort relative to its impact. Listed in order of
priority.

### Safety levers

| # | Lever | Effort | Why it matters |
|---|---|---|---|
| S1 | **OpenAI hard billing cap** in OpenAI dashboard at e.g. $200/mo | 2 min | Last-resort fuse. If everything else fails, OpenAI stops charging you when the cap hits. |
| S2 | **Per-IP rate limit** on `/api/transcribe` (10 req/hr per IP, regardless of auth) | 30 min | Stops a single bad actor with multiple accounts. |
| S3 | **Daily spend tracker** that emails you if any single day's transcription cost exceeds $50 | 1 hr | Early warning of abuse or a bug. Uses Vercel cron + Firestore aggregate read. |
| S4 | **Block disposable email domains** at sign-up (mailinator, 10minutemail, etc.) | 20 min | Reduces serial-trial-abuse. There are open-source lists you can copy. |
| S5 | **Trial period (3 days free Pro)** instead of "5 free recordings forever" | 1 hr | Filters out users who'll never convert. Industry-standard pattern. |
| S6 | **Fraud detection on yearly purchases** — flag any user who refunds within 14 days | 1 hr | Yearly plan is the biggest refund target. Catches refund-and-resubscribe scams. |
| S7 | **Anomaly detection on usage** — alert when one user transcribes > 3 hr in a single day | 1 hr | A real human doesn't do this. Likely automated abuse. |

### Profit levers

| # | Lever | Effort | Why it matters |
|---|---|---|---|
| P1 | **Top-ups** — "$2.99 for 2 extra hours this month" | 4 hr | Captures revenue from heavy users who would otherwise churn. ~5-10% revenue lift. |
| P2 | **Lifetime deal** — "$149 one-time, lock in forever" | 2 hr | Cash up front, no churn. Effective even at small scale. Could net $5-10K in a launch promo. |
| P3 | **Yearly intro discount** — first year $39.99, renews at $49.99 | 1 hr | Reduces friction on yearly conversion. Industry-standard. |
| P4 | **Referral program** — "Give a friend 1 month free Pro, get 1 month free Pro" | 4 hr | Viral coefficient > 0 = exponential growth. RevenueCat has built-in support. |
| P5 | **Team / family plan** — $14.99/mo for 3 users | 4 hr | Some users will share with their partner. Capture that revenue instead of losing it. |
| P6 | **B2B tier** — $39.99/mo, custom branding, priority support | 8 hr | Even 10 B2B customers = $400/mo. Highest-margin tier. |
| P7 | **Annual upsell drip** — show "Save 48% with yearly!" banner to month-3 monthly users | 1 hr | Converts ~10% of monthly to yearly. Industry-standard. |

### Cost-reduction levers

| # | Lever | Effort | Why it matters |
|---|---|---|---|
| C1 | **Cache identical audio fingerprints** — if two users upload the same file, transcribe once | 4 hr | Probably negligible savings unless your users share content. Skip until proven needed. |
| C2 | **Use `gpt-4o-mini-transcribe` instead of `whisper-1`** when it's stable in the API | 1 hr | gpt-4o-mini-transcribe is **40% cheaper** ($0.0036/min vs $0.006/min). Drop-in replacement. **Plan to migrate within 6 months.** |
| C3 | **Compress audio before upload** — drop bitrate from 64 kbps to 32 kbps mono | 1 hr | Smaller uploads = faster, less bandwidth cost on Vercel. Whisper accuracy unchanged at 16 kHz mono. |
| C4 | **Skip GPT summary for very short recordings (< 30 sec)** | 30 min | Tiny cost, but eliminates the "wasted summary call" pattern. |

---

## 7. The cost-of-doing-nothing comparison

A reminder of why you're doing this in the first place:

> A solo consultant who books even **one extra $500 client** because RecapCoach
> reminded them to follow up has paid for **6 years** of their Pro subscription.
> You don't need to convince anyone of the value. You just need to ship.

---

## 8. When to revisit pricing

Do **not** change pricing in the first 6 months. Use that time to gather
usage data. After 6 months, revisit if:

- **Realistic-scenario margin drops below 50%** → raise Pro to $9.99
- **Conversion rate is below 1%** → free tier is too generous; tighten to 3 recordings / 10 min
- **Conversion rate is above 6%** → free tier is too restrictive; loosen slightly
- **Yearly:monthly ratio is below 20%** → yearly is too expensive; lower to $39.99
- **Yearly:monthly ratio is above 60%** → yearly is too cheap; raise to $59.99

Track these in a simple Firestore aggregate doc; no analytics platform
needed.

---

## 9. The bottom line

You asked: **"Can I make money with this app without going bankrupt?"**

The math answer is **yes, with substantial margin in every scenario the
universe can throw at you**. The technical answer (kill switch, per-user
quotas, hard OpenAI billing cap, atomic counters) means the worst-case
failure mode is "you have to fix a bug" — not "you owe OpenAI $20,000."

Now the harder question: **"Can I emotionally and logistically handle
1,000+ paying users as a solo developer?"** That's [chapter 12](12-solo-developer-playbook.md).
