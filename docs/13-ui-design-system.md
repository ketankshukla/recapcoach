# 13 — UI Design System

The visual foundation that every screen in RecapCoach is built on.

This chapter documents the **tokens** (colors, spacing, radii, typography)
and explains the rationale so future you (or anyone reading the code)
knows why a value is what it is. The widget code reads everything via
`Theme.of(context)` — never hard-coded constants.

This is **Phase 0** of the [UI overhaul](08-roadmap.md). It produces no
visible UI change on its own; phases 1-6 use these tokens to redesign
the actual screens.

---

## 1. Aesthetic direction

**Direction A — Deep navy + warm amber.**

> Professional, slightly luxurious, "this looks expensive enough to be
> serious." Targets the solo-consultant audience who values an app that
> matches the rate they charge.

Reference brands with this feel: Linear, Stripe, Notion's enterprise
pages.

What we deliberately avoided:

- Generic teal/cyan (overused in productivity apps; signals "made with
  Material defaults")
- Pure black/white (clinical, cold)
- Electric purple SaaS palette (too startup-y for the audience)

---

## 2. Files involved

```
lib/core/theme/
├── app_colors.dart           Raw palette tokens (navy/amber/sage/cream)
├── app_spacing.dart          4pt spacing scale
├── app_radii.dart            Border-radius tokens
├── app_typography.dart       Material 3 text scale on Inter (system fallback)
├── app_semantic_colors.dart  ThemeExtension for app-specific colors
└── app_theme.dart            Wires ColorSchemes + ThemeData (light + dark)
```

Tests:

```
test/core/theme/
└── app_theme_test.dart       21 tests covering token vocabulary + wiring
```

---

## 3. Color palette

### 3.1 Raw tokens (`app_colors.dart`)

| Family       | Token         | Hex       | Notes                                                                                              |
| ------------ | ------------- | --------- | -------------------------------------------------------------------------------------------------- |
| **Navy**     | `navy900`     | `#0F1E3D` | Darkest navy. Used for ink-style text on cream backgrounds and for the deepest dark-mode surfaces. |
|              | `navy800`     | `#1B2A4E` | **Brand primary (light mode).** AppBar, primary buttons, prominent text.                           |
|              | `navy700`     | `#2D4373` | Outline on dark surfaces; selected states.                                                         |
|              | `navy500`     | `#7B9FE0` | Mid-tone; rarely used directly.                                                                    |
|              | `navy200`     | `#A8C0E8` | **Brand primary (dark mode).** Light enough to pop on the dark navy surface.                       |
|              | `navy100`     | `#D8E0F0` | Primary container in light mode (chip backgrounds, etc.).                                          |
| **Amber**    | `amber900`    | `#78350F` | Container content color in light mode.                                                             |
|              | `amber700`    | `#92400E` | Container background in dark mode.                                                                 |
|              | `amber600`    | `#D97706` | **Brand secondary (light mode).** Accessible on white.                                             |
|              | `amber400`    | `#F4A261` | **Brand secondary (dark mode).** Brighter pop on navy.                                             |
|              | `amber100`    | `#FEF3C7` | Container background in light mode.                                                                |
| **Sage**     | `sage700`     | `#4A7264` | Container content color.                                                                           |
|              | `sage500`     | `#5A8C7B` | **Success (light mode)**, usage-meter "low" color.                                                 |
|              | `sage300`     | `#86B5A1` | **Success (dark mode)**, usage-meter "low" color.                                                  |
| **Cream**    | `cream50`     | `#FAFAF7` | Scaffold background (light). Warmer than pure white.                                               |
|              | `cream100`    | `#F4F3EE` | Slightly raised container.                                                                         |
|              | `cream200`    | `#EFEDE6` | More raised container; usage-meter track.                                                          |
|              | `cream50Dark` | `#F5F1E8` | Body text color in dark mode.                                                                      |
| **Slate**    | `slate500`    | `#4A5568` | Secondary text in light mode.                                                                      |
|              | `slate400`    | `#A0AEC0` | Secondary text in dark mode.                                                                       |
|              | `slate300`    | `#CBD5E0` | Outlines in light mode.                                                                            |
|              | `slate200`    | `#E2E8F0` | Subtle dividers.                                                                                   |
| **Ink**      | `ink900`      | `#080F1F` | Deepest dark-mode background.                                                                      |
|              | `ink800`      | `#0F1E3D` | Dark-mode surface.                                                                                 |
|              | `ink700`      | `#152544` | Dark-mode container.                                                                               |
| **Semantic** | `error600`    | `#B91C1C` | Error (light). Warm deep red, fits the palette.                                                    |
|              | `error300`    | `#FCA5A5` | Error (dark).                                                                                      |
|              | `success`     | sage500   | Alias for clarity at call sites.                                                                   |
|              | `warning`     | amber600  | Aligns with the accent so the UI doesn't fight itself.                                             |

### 3.2 Why each ColorScheme slot got these values

The `_lightColorScheme` and `_darkColorScheme` in `app_theme.dart` map
these raw tokens onto Material 3's standard slots. The mapping is
deliberate; widgets that use `Theme.of(context).colorScheme.primary`
will get the right thing automatically.

| ColorScheme slot       | Light    | Dark        | What it's used for                                  |
| ---------------------- | -------- | ----------- | --------------------------------------------------- |
| `primary`              | navy800  | navy200     | FilledButton background, FAB, primary text emphasis |
| `onPrimary`            | white    | navy900     | Text on primary surfaces                            |
| `secondary`            | amber600 | amber400    | Accent CTAs ("Upgrade"), highlights                 |
| `onSecondary`          | white    | amber900    | Text on secondary surfaces                          |
| `tertiary`             | sage500  | sage300     | Positive states that aren't amber                   |
| `error`                | error600 | error300    | Quota exceeded, processing errors                   |
| `surface`              | white    | ink800      | Card backgrounds                                    |
| `surfaceContainerLow`  | cream50  | ink800      | Scaffold background                                 |
| `surfaceContainerHigh` | cream200 | navy800     | Input backgrounds                                   |
| `onSurface`            | navy900  | cream50Dark | Body text                                           |
| `onSurfaceVariant`     | slate500 | slate400    | Secondary text                                      |
| `outline`              | slate300 | navy700     | Borders, dividers                                   |

### 3.3 Accessibility notes

All body-text combinations clear WCAG AA (4.5:1) by a wide margin:

- Light: `navy900` on `cream50` → contrast ≈ 15:1 ✅
- Light: `slate500` on `cream50` → contrast ≈ 8:1 ✅
- Dark: `cream50Dark` on `ink900` → contrast ≈ 17:1 ✅
- Dark: `slate400` on `ink900` → contrast ≈ 9:1 ✅

**Caveat on amber600 on white:** ~3.5:1, which fails AA for normal text
but passes for **large text** (18pt+) and is OK for **decorative
elements** (chip backgrounds, FAB backgrounds with white-text overlay).
Use amber600 for accents, not body copy.

---

## 4. Spacing (`app_spacing.dart`)

A **4pt scale**. Every padding, margin, and gap value in the app should
come from one of these:

| Token  | px  | Use                                             |
| ------ | --- | ----------------------------------------------- |
| `xxs`  | 4   | Icon-to-text in compact chips                   |
| `xs`   | 8   | Between related elements                        |
| `sm`   | 12  | Between paragraphs in a card                    |
| `md`   | 16  | **Default card padding** — by far the most-used |
| `lg`   | 20  | Between major card elements                     |
| `xl`   | 24  | Between sections within a screen                |
| `xxl`  | 32  | Between screen regions                          |
| `xxxl` | 48  | Top of major screens, around hero elements      |
| `huge` | 64  | Large empty states                              |

Why 4pt? Because (a) it's pixel-perfect at all common DPIs, and (b) the
small vocabulary is easy to memorize.

Tests enforce that every token is a multiple of 4 and that the scale is
strictly increasing.

---

## 5. Radii (`app_radii.dart`)

| Token  | px   | Use                                    |
| ------ | ---- | -------------------------------------- |
| `xs`   | 6    | Chips, badges                          |
| `sm`   | 8    | Compact buttons, small inputs          |
| `md`   | 12   | **Default** for cards, buttons, inputs |
| `lg`   | 16   | Prominent cards, dialogs               |
| `xl`   | 20   | Bottom sheets                          |
| `pill` | 28   | Pill-shaped FAB / full-width CTAs      |
| `full` | 9999 | Effectively circular (avatars)         |

---

## 6. Typography (`app_typography.dart`)

### 6.1 The plan

We use Material 3's standard 15-style text scale, **with stronger
weights** for a more decisive, premium feel.

- Display & headline: **w600/w700** (not the default w400)
- Title: w600
- Body: w400
- Labels: w500/w600

Letter-spacing is tightened on display/headline (negative tracking) and
expanded on labels (positive tracking) per Material 3 best practice.

### 6.2 The font choice

Preferred family: **Inter** (`'Inter'`).

For Phase 0 we **do not bundle Inter as an asset**. The font family is
declared on every text style, so:

- If Inter TTF files are added to `assets/fonts/Inter/` and registered
  in `pubspec.yaml > flutter > fonts`, Flutter uses them automatically.
- If not (current state), Flutter silently falls back to the platform
  system font — **Roboto on Android, San Francisco on iOS**. Both are
  excellent and indistinguishable from Inter to most users.

This means we don't pay the cost (binary size, network dependency at
first launch, test-environment complexity) of bundling fonts until
we've validated the rest of the design.

> **To bundle Inter later:** download the OTF/TTF files from
> <https://rsms.me/inter/>, drop them in `assets/fonts/Inter/`, add the
> family declaration to `pubspec.yaml`. No widget code changes needed.

### 6.3 The tabular numbers helper

The recording-screen timer and usage counters use **tabular figures**
(numerals that all have the same width) so the layout doesn't jitter
as numbers change. Apply via:

```dart
Text(
  '12:34',
  style: theme.textTheme.displayMedium?.merge(
    AppTypography.tabularNumberStyle,
  ),
)
```

This works regardless of the underlying font because both Roboto and
Inter ship with `tnum` OpenType features.

---

## 7. Semantic colors (`app_semantic_colors.dart`)

Exposed as a `ThemeExtension<AppSemanticColors>` so widgets can read
them via `Theme.of(context).extension<AppSemanticColors>()`. This is
the right pattern for app-specific tokens that:

1. Differ between light and dark mode (so they can't be `const`s in
   `AppColors`).
2. Need to animate smoothly when the theme transitions.
3. Need to be discoverable by IDE auto-complete from any widget.

| Field             | Light    | Dark     | Use                            |
| ----------------- | -------- | -------- | ------------------------------ |
| `usageMeterLow`   | sage500  | sage300  | Bar color < 50%                |
| `usageMeterMid`   | amber600 | amber400 | Bar color 50-80%               |
| `usageMeterHigh`  | error600 | error300 | Bar color ≥ 80%                |
| `usageMeterTrack` | cream200 | ink700   | Bar background                 |
| `recordingPulse`  | amber600 | amber400 | Record-button pulse + waveform |
| `proBadge`        | navy800  | amber400 | "PRO" chip background          |
| `proBadgeOn`      | amber400 | navy900  | Text on PRO chip               |
| `shimmer`         | cream200 | ink700   | Skeleton loading state         |

### 7.1 The `usageMeterColorFor(progress)` helper

This is the single source of truth for the usage-meter color
transitions. Both the home-screen meter and the record-screen quota
indicator call it, so the two stay in lockstep:

```dart
final tokens = Theme.of(context).extension<AppSemanticColors>()!;
final color = tokens.usageMeterColorFor(snapshot.worstProgress);
```

Tested at 0%, 25%, 49%, 50%, 65%, 79%, 80%, 95%, 100%.

---

## 8. ThemeData wiring (`app_theme.dart`)

The `_build()` method wires everything together once per brightness:

```dart
return ThemeData(
  useMaterial3: true,
  brightness: brightness,
  colorScheme: scheme,
  textTheme: AppTypography.textTheme(brightness),
  scaffoldBackgroundColor: scheme.surfaceContainerLow,
  extensions: <ThemeExtension<dynamic>>[semanticColors],
  // ... per-component themes ...
);
```

Component themes overridden:

- `appBarTheme` — flat, no elevation, our text style, no centered title.
- `filledButtonTheme` / `outlinedButtonTheme` — 52pt min height, md
  radius, labelLarge text.
- `inputDecorationTheme` — filled style with surfaceContainerHigh,
  focused border 1.5px primary.
- `cardTheme` — flat (no elevation), lg radius, zero margin.
- `snackBarTheme` — floating, md radius, inverse surface.
- `dialogTheme` / `bottomSheetTheme` — lg/xl radii respectively, drag
  handle on sheets.
- `chipTheme`, `dividerTheme`, `progressIndicatorTheme`,
  `floatingActionButtonTheme` — all aligned to the system.

---

## 9. Usage from widget code

A few canonical patterns:

```dart
// Reading colors
final theme = Theme.of(context);
final scheme = theme.colorScheme;
final tokens = theme.extension<AppSemanticColors>()!;

Container(
  color: scheme.surface,                  // not Colors.white
  padding: const EdgeInsets.all(AppSpacing.md),
  child: Text(
    'Hello',
    style: theme.textTheme.titleMedium,   // not TextStyle(fontSize: 16, ...)
  ),
)
```

```dart
// Status colors
Icon(
  Icons.check_circle,
  color: tokens.usageMeterColorFor(progress),
)
```

```dart
// Buttons (already styled by the theme; just use them)
FilledButton(onPressed: () {}, child: const Text('Save'))
```

**What NOT to do:**

```dart
// ❌ Don't import AppColors directly in widget code.
import 'package:recapcoach/core/theme/app_colors.dart';
Container(color: AppColors.navy800);

// ❌ Don't hard-code radii or padding.
Padding(padding: EdgeInsets.all(16))

// ❌ Don't hard-code text styles.
Text('Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
```

---

## 10. Tests

21 tests in `test/core/theme/app_theme_test.dart`:

- **Palette constants** (3 tests) — exact hex values for navy + amber +
  semantic aliases. Catches accidental drift.
- **Spacing** (3 tests) — 4pt multiples, monotonic ordering, md = 16.
- **Radii** (4 tests) — monotonic ordering, defaults, full = ≥9999,
  `all()` helper.
- **Semantic colors** (5 tests) — usage-meter color thresholds at every
  boundary, lerp + copyWith.
- **ThemeData wiring** (6 tests) — Material 3 enabled, brightness, the
  light/dark primary + secondary tones, extension presence in a real
  widget tree.

All pass. Run with:

```powershell
flutter test test\core\theme\
```

---

## 11. Phase 1 — Home screen components

Phase 1 ([08-roadmap.md](08-roadmap.md)) is the first visible
application of the design system. Every Phase 1 widget reads its
colors / spacing / radii through the patterns in section 9 — nothing
hard-coded.

**Files:**

```
lib/features/home/widgets/
├── time_based_greeting.dart  Pure helper: hour → "Good morning/afternoon/evening"
├── home_app_bar.dart         AppBar with avatar + greeting + settings
├── user_avatar.dart          Photo-or-initials circle (navy bg + amber initials)
├── empty_state.dart          Hero illustration + "Capture your first call"
├── note_card.dart            Card with icon + title + status chip + summary
├── note_status.dart          NoteStatus enum + Note → status mapping
├── note_status_chip.dart     Pill chip (Transcribing / Done / Failed / Pending)
├── usage_meter.dart          Gradient + animated bar with FREE/PRO badge
├── skeleton_note_card.dart   Loading placeholder matching NoteCard shape
└── pulsing_record_fab.dart   FAB with subtle amber heartbeat shadow
```

### Component recipes

| Component          | Tokens consumed                                                                                                              | Notes                                                                                                                                       |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `HomeAppBar`       | `AppSpacing.sm`, M3 `colorScheme.onSurfaceVariant`                                                                           | Computes greeting via `TimeBasedGreeting.forTime`. Falls back to "Welcome to RecapCoach" if not signed in.                                  |
| `UserAvatar`       | `AppColors.navy800` (bg), `AppColors.amber400` (initials)                                                                    | Avatar uses `foregroundImage: NetworkImage(photoUrl)` with the initials Text as the `child`, so a load failure naturally falls back.        |
| `HomeEmptyState`   | `AppColors.navy800`, `AppColors.amber400`, `AppSpacing.huge`, `semantic.recordingPulse`, `semantic.shimmer`, `AppRadii.full` | The amber-on-navy mic disc gets a soft `recordingPulse`-tinted halo via a `BoxShadow`.                                                      |
| `NoteCard`         | `cardTheme` (auto), `AppRadii.sm`, `AppSpacing.sm`                                                                           | Wraps `Card + InkWell` so tap feedback respects the elevation. Body text branches on `note.status`.                                         |
| `NoteStatusChip`   | `semantic.usageMeterLow/Mid/High`, `AppRadii.xs`, `AppSpacing.xxs`                                                           | Reuses the usage-meter color ladder so "almost out" and "transcribing" share the amber tone — no new vocabulary.                            |
| `UsageMeter`       | `semantic.usageMeterColorFor()`, `semantic.usageMeterTrack`, `semantic.proBadge`, `AppRadii.xs`, `AppSpacing.md`             | Bar is a gradient (65% alpha → full color) animated via `TweenAnimationBuilder` (700ms, easeOutCubic). Inline Upgrade CTA when free + ≥80%. |
| `SkeletonNoteCard` | `semantic.shimmer`, `AppRadii.sm/xs`                                                                                         | Static (non-animated) skeleton; Hive opens fast enough that a real shimmer would barely register.                                           |
| `PulsingRecordFab` | `semantic.recordingPulse`, `AppRadii.pill`                                                                                   | Pulse is a `BoxShadow` whose alpha + blur + spread are driven by an `AnimationController` repeating every 1.6s with `Curves.easeOut`.       |

### Tests

49 widget + unit tests added in Phase 1 (live alongside the 21 from
Phase 0), in `test/features/home/widgets/`:

- `time_based_greeting_test.dart` — 9 tests covering every hour boundary
- `note_status_test.dart` — 7 tests covering precedence rules
- `note_status_chip_test.dart` — 4 tests, one per status
- `home_app_bar_test.dart` — 6 tests (greeting branches + welcome
  fallback + settings callback + first-name parsing)
- `user_avatar_test.dart` — 7 tests (initials matrix + photo branch)
- `empty_state_test.dart` — 2 tests (smoke + dark theme)
- `note_card_test.dart` — 5 tests (each status + onTap)
- `usage_meter_test.dart` — 5 tests (free/pro × under/near/at-cap)
- `pulsing_record_fab_test.dart` — 4 tests (smoke + tap + animation
  cycle + clean dispose)

Total Phase 0 + Phase 1 design-system tests: **70**, plus 40
monetization tests = **110 tests passing** as of this commit.

```powershell
flutter test test\core\theme\ test\features\home\
```
