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

## 11. Phase 1 — Home screen (premium glass dashboard)

Phase 1 ([08-roadmap.md](08-roadmap.md)) is the first visible
application of the design system. The first cut shipped a
conventional Material 3 layout; the **glass-dashboard variant** in
this section replaced it after user feedback that the M3 look felt
"too plain and monotonously simple."

The new look is built on three primitives that are reused by
subsequent phases:

1. **Mesh-gradient background** (`MeshGradientBackground`) — animated
   `CustomPainter` that drifts three radial-gradient blobs over a
   28-second period. Light + dark palettes are independent: dark uses
   ink + navy + amber bloom + sage; light uses cream + amber-100 +
   sage-300 + navy-100.
2. **Frosted glass surfaces** (`GlassCard`) — `BackdropFilter`-blurred
   container with a 1px hairline border, low-alpha fill, and a soft
   amber- (dark) or navy-tinted (light) drop shadow. The card "floats"
   over the mesh.
3. **Hero stats card** (`WeeklyStatsCard`) — replaces the AppBar +
   AccountCard + horizontal usage meter combo with a single statement
   element: avatar + greeting in 34 pt display weight + 3-stat row
   (this-week recordings, this-week minutes, circular usage arc).

### Files

```
lib/features/home/widgets/
├── time_based_greeting.dart    Pure helper: hour → greeting
├── note_status.dart            NoteStatus enum + Note→status mapping
├── note_status_chip.dart       Pill chip (Transcribing/Done/Failed/Pending)
├── user_avatar.dart            Photo-or-initials circle
├── mesh_gradient_background.dart  Animated mesh, light + dark palettes
├── glass_card.dart             BackdropFilter wrapper, optional onTap
├── arc_usage_ring.dart         CustomPainter sweep-gradient progress arc
├── weekly_stats_card.dart      Hero glass card with greeting + stats
├── note_card.dart              Glass note tile + status-color edge accent
├── empty_state.dart            Hero amber-on-navy mic disc + glass panel
├── skeleton_note_card.dart     Glass skeleton matching note card shape
└── pulsing_record_fab.dart     Amber→gold gradient pill + heartbeat halo
```

### Component recipes

| Component                | Tokens consumed                                                                                                                      | Notes                                                                                                                                                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `MeshGradientBackground` | `AppColors.navy700`, `AppColors.amber600/100`, `AppColors.sage700/300`, `AppColors.navy100`                                          | 3 radial blobs with sin/cos drift on 28s loop. `animate: false` flag for tests + low-power devices. Painter only repaints when `t` changes.                                                                        |
| `GlassCard`              | `Colors.white` (mode-aware alpha), `Colors.black` / `AppColors.navy800` (drop shadow), `BackdropFilter` sigma 18 default             | Dark mode: 6% white fill, 10% white border. Light mode: 55% white fill, 70% white border. Optional `gradient` overlay paints between the blur and the child.                                                       |
| `ArcUsageRing`           | Caller-supplied `color` + `trackColor`; uses `SweepGradient` (50% → full alpha)                                                      | Animated via `TweenAnimationBuilder` (800ms easeOutCubic). Center widget slot for the percentage label. Defensively clamps progress to [0, 1].                                                                     |
| `WeeklyStatsCard`        | `AppColors.amber600/100`, `AppColors.ink900`, `AppColors.slate500`, `semantic.usageMeterColorFor()`, `AppSpacing.lg`                 | 34 pt display greeting, 3-stat row (count / minutes / arc-ring). Static helpers `firstName()` + `weeklyStats()` exposed for unit testing. Subtle warm gradient overlay in the top-left corner draws the eye first. |
| `NoteCard`               | `GlassCard` (sigma 14, radius 18), `semantic.usageMeterLow/Mid/High`                                                                 | 4 dp leading status-color accent strip + status-tinted icon avatar (12 dp radius, 18% fill, 30% border). Body text branches on `note.status`.                                                                      |
| `NoteStatusChip`         | `semantic.usageMeterLow/Mid/High`, `AppRadii.xs`                                                                                     | Unchanged from the M3 cut — works equally well on glass surfaces.                                                                                                                                                  |
| `HomeEmptyState`         | `AppColors.navy900/700` (mic disc gradient), `AppColors.amber400/600` (halo + icon), `GlassCard`                                     | 132 dp mic disc has two stacked `BoxShadow` halos (36 dp blur + 80 dp blur) that bloom amber against the mesh. Glass panel below holds the headline + helper copy + "Start recording" pill.                        |
| `SkeletonNoteCard`       | `GlassCard` (sigma 14), low-alpha block fills                                                                                        | Mode-aware block tints. Static (non-animated) — Hive opens in <300ms in practice.                                                                                                                                  |
| `PulsingRecordFab`       | `AppColors.amber600 → amber400` linear gradient, `AppColors.amber400` halo, `AppColors.amber700` grounded shadow, white icon + label | Heartbeat halo: `AnimationController.repeat(1.6s)` drives a `BoxShadow` whose alpha (35→0%) + blur (14→32 dp) + spread (1→6 dp) co-vary on `Curves.easeOut`.                                                       |

### Layout

```
┌────────────────────────────────────────────┐
│ ░░░░░░░  animated mesh gradient ░░░░░░░░  │ ← Scaffold body
│                                            │   (no AppBar)
│  ╭──────── glass hero card ────────╮      │
│  │ [avatar]              [⚙ icon] │      │
│  │                                  │      │
│  │ Good evening,                    │      │ ← 34 pt
│  │ Ketan                            │      │   display
│  │                                  │      │
│  │  3       47        ◯ 40%         │      │
│  │ recordings min     used          │      │
│  ╰──────────────────────────────────╯      │
│                                            │
│  RECENT RECORDINGS                        │
│  ╭────── glass note card ──────────╮      │
│  │▌[icn] Title              [▸]   │      │
│  │      [chip] 2:14                │      │
│  │      Summary preview...          │      │
│  ╰─────────────────────────────────╯      │
│              ...                          │
│                                            │
│             ┌──────────────────┐          │
│             │ 🎤 Record call   │ pulse    │ ← gradient FAB
│             └──────────────────┘          │
└────────────────────────────────────────────┘
```

The Scaffold uses no AppBar — the hero card occupies the top region.
`Scaffold.backgroundColor` is transparent so the mesh is the actual
background.

### Tests

63 widget + unit tests live in `test/features/home/widgets/`:

| File                            | Tests | Coverage                                                          |
| ------------------------------- | ----- | ----------------------------------------------------------------- |
| `time_based_greeting_test.dart` | 9     | every hour boundary                                               |
| `note_status_test.dart`         | 7     | Note→status precedence rules                                      |
| `note_status_chip_test.dart`    | 4     | one per status                                                    |
| `user_avatar_test.dart`         | 7     | initials matrix + photo branch                                    |
| `glass_card_test.dart`          | 5     | child reachable, light/dark, onTap, no spurious InkWell           |
| `arc_usage_ring_test.dart`      | 5     | smoke, full progress, center slot, defensive clamp ±1.5/-0.3      |
| `weekly_stats_card_test.dart`   | 12    | `firstName` (3) static helper + 9 widget tests (incl. dev bypass) |
| `note_card_test.dart`           | 5     | each status + onTap                                               |
| `empty_state_test.dart`         | 2     | smoke + dark theme                                                |
| `pulsing_record_fab_test.dart`  | 4     | smoke + tap + animation cycle + clean dispose                     |

**Total: 156 tests passing as of this commit** (Phase 0 + Phase 1
design-system + 40 monetization + quota / dev-bypass + Phase 2 shared
primitives + Record screen widgets).

```powershell
flutter test test\core\ test\features\home\
```

### Performance notes

- Each `GlassCard` instantiates its own `BackdropFilter`. On Impeller
  (default on the user's Samsung S22), a list of 6-10 glass cards runs
  at sustained 60 fps. If we ever drop below that on lower-end
  devices, the first lever is dropping `sigma` from 18 → 12.
- The mesh painter draws 3 radial gradients per frame at 60 fps. This
  is a single large quad with shaders; cheap on Vulkan.
- The hero card's animated arc-ring uses `TweenAnimationBuilder` so
  it animates exactly once per change in progress, not every frame.

---

## 12. Phase 2 — Glass theme rollout to remaining screens

Phase 1 proved the glass-dashboard direction on the home screen. Phase
2 propagates the same vocabulary across every other screen so the app
feels like a single coherent product rather than "the home screen plus
a Material 3 settings page."

### Shared primitives

A new shared widgets folder, `lib/core/widgets/glass/`, holds primitives
used by 2+ screens. The home screen's `GlassCard` and
`MeshGradientBackground` will eventually move here too once they earn
a second consumer.

| Primitive            | File                                               | Used by                                                                                                                                                |
| -------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GradientPillButton` | `lib/core/widgets/glass/gradient_pill_button.dart` | Paywall ("Start free trial"), Record ("Stop & save"), `GlassAlertDialog` non-destructive primary action, future Sign In CTA                            |
| `GlassIconButton`    | `lib/core/widgets/glass/glass_icon_button.dart`    | Paywall close, Record cancel + discard (red `tint:`), Settings back                                                                                    |
| `GlassPillButton`    | `lib/core/widgets/glass/glass_pill_button.dart`    | Paywall "Restore" link; the low-key sibling of `GradientPillButton`                                                                                    |
| `GlassAlertDialog`   | `lib/core/widgets/glass/glass_alert_dialog.dart`   | Record (mic permission, free-cap reached), Settings (delete-account confirmation). `primaryDestructive: true` swaps amber CTA for red outlined button. |

`GradientPillButton` is the same amber-600 → amber-400 gradient pill
as `PulsingRecordFab` minus the heartbeat halo. Idle / loading /
disabled states share a single API:

```dart
GradientPillButton(
  onPressed: _selected == null ? null : _buy,
  loading: _purchasing,
  expanded: true,                   // stretches to fill width
  icon: Icons.workspace_premium_rounded,
  label: 'Start free trial',
)
```

In loading state the label is replaced with a 22 dp white spinner and
taps are swallowed even when `onPressed` is non-null — the Paywall
calls `purchasePackage()` async and a double-tap would charge the
user twice (this is locked down by a [CRITICAL] widget test).

### Paywall (`lib/features/paywall/paywall_screen.dart`)

First non-home screen on the glass theme. Sits over the same
`MeshGradientBackground` so the upgrade flow feels continuous with the
home screen. Structural changes from the M3 version:

- **No AppBar.** Close + Restore are floating glass controls in the
  top corners (`_GlassIconButton`, `_GlassPillButton`).
- **Hero medal disc.** 96 dp amber-gradient circle with a 32 dp amber
  bloom shadow replaces the flat `Icon(Icons.workspace_premium, size: 64)`.
- **Glass benefits card.** A single `GlassCard` holds 4 benefit rows;
  each row uses a 26 dp amber-gradient check disc instead of the
  Material `Icons.check_circle`.
- **Glass product tiles.** Each RevenueCat package is a `GlassCard`
  with a custom amber-when-selected radio + `BEST VALUE` gradient
  badge for the annual plan. Selected state tints the card with 12 %
  amber instead of swapping to a primary-color background.
- **Stub product tile.** Empty offerings (RevenueCat in stub mode)
  render an explanatory `GlassCard` instead of bricking the screen
  with a null-pointer dereference (the bug fixed in commit `7742178`).
- **Error chip.** Errors render as an inline error-tinted glass-style
  chip rather than red text under the button.
- **Primary CTA** is the new `GradientPillButton` so the Paywall's
  "Start free trial" matches the home screen's "Record call" pill.

### Record screen (`lib/features/recording/record_screen.dart`)

Second non-home screen on the glass theme. The recording "moment of
truth" feels like the same product as the home screen instead of a
Material 3 detour.

Structural changes from the M3 version:

- **No AppBar.** Cancel is a floating `GlassIconButton` in the top-left
  corner. Pressing the device back-button calls the same `_cancel()`
  flow via `PopScope`.
- **Sits over `MeshGradientBackground`** (same animated mesh as home + paywall).
- **`AmplitudePulseMic`** -- new widget in `lib/features/recording/widgets/`.
  140-200 dp amber-gradient mic disc with two stacked `BoxShadow` halos
  whose alpha + blur + spread are all driven by the live amplitude.
  Replaces the previous M3 `primaryContainer` circle.
- **Glass timer card.** Elapsed time + status sub-label live inside a
  `GlassCard` with a small `_RecordingDot` (red while recording, dim
  while preparing) so the user always knows the recorder's state.
- **`AmplitudeWaveform`** -- 20 bars; lit ones use the amber gradient,
  unlit use a low-alpha white (dark) / slate (light). Replaces the
  previous M3 primary-coloured bars.
- **Action row.** A red-tinted `GlassIconButton` (Discard) + an
  expanded `GradientPillButton` ("Stop & save"). The previous Material
  `_CircleButton` is gone.
- **`GlassAlertDialog`.** Replaces Material `AlertDialog` for the
  permission-needed and quota-reached prompts. Lives in
  `lib/core/widgets/glass/` (extracted in commit 4) so Settings can
  reuse it.

### Settings (`lib/features/settings/settings_screen.dart`)

Third non-home screen on the glass theme. Replaces a flat
`ListView`-of-`ListTile`s with mesh-backed sections, each section a
`GlassCard` containing semantically-grouped rows.

- **No AppBar.** Back is a floating `GlassIconButton` in the top-left.
- **Sits over `MeshGradientBackground`** (same as home / paywall / record).
- **Display title.** "Settings" rendered as a 32 dp display heading
  inside the scrollable content rather than a stock app-bar title.
- **Sections.** Four `GlassCard`s, each with a small all-caps muted
  `_SectionLabel` above ("ACCOUNT", "SUBSCRIPTION",
  "LEGAL & SUPPORT", "ACCOUNT ACTIONS"). Helps the eye scan the
  screen without reading every row.
- **`_SettingsRow` private widget.** Looks like a `ListTile` but is
  hand-rolled so the divider colour, ripple shape, icon tint, and
  destructive title tint can match the glass surface. Last row in
  each card sets `showDivider: false` so the card doesn't draw a
  divider against its own bottom border.
- **Pro tile.** Amber `workspace_premium` icon when the user is on
  Pro; lock-outline when on Free. Tap routes to the Play Store
  subscription manager (Pro) or `/paywall` (Free).
- **Delete account.** Uses the shared `GlassAlertDialog` with
  `primaryDestructive: true`, which swaps the amber CTA for a red
  outlined button -- destructive actions never sit in the visual
  slot the brain associates with "good".

### Note detail (`lib/features/notes/note_detail_screen.dart`)

Fourth non-home screen on the glass theme. The "open one note" view
that the home cards push into.

- **No AppBar.** Back is a floating `GlassIconButton` in the top-left,
  Delete is a red-tinted `GlassIconButton` in the top-right.
- **Sits over `MeshGradientBackground`** (consistent with home / paywall /
  record / settings).
- **Header.** 28 dp display title (`note.displayTitle`) with a 13 dp
  metadata row underneath: clock icon + duration + recorded date
  (`MMM d, y · h:mm a`). Replaces the old M3 "leading avatar +
  Duration X" `Card`.
- **`NotePlayer` redesigned.** Now a `GlassCard` with a 52 dp circular
  amber-gradient `_PlayPauseDisc` (white play / pause icon, soft
  amber bloom shadow) and an amber-tinted slider track + thumb.
  Disabled state drops the disc opacity to 0.55 instead of swapping
  to a desaturated grey -- the brand colour stays visible.
- **Three glass section cards**: Summary, Action items, Transcript.
  Each section card has a `_SectionHeader` with a small amber-tinted
  rounded-square icon avatar (Auto-awesome / Checklist / Subject)
  next to the title. Sections gracefully render four states:
  processing (amber spinner + "Processing…"), error (`error600`
  text), empty (muted placeholder), or content (selectable text so
  the user can copy partial passages).
- **Copy actions.** The Summary and Transcript headers expose a
  copy-to-clipboard `IconButton` (only visible when the content is
  populated). Tapping shows a Material `SnackBar` -- intentional, the
  Material snackbar reads naturally over the glass surface.
- **Action items.** Hand-rolled bulleted list with a 16 dp
  amber-bordered square bullet per item, consistent with the
  amber-as-accent rule. The list uses `SelectableText` everywhere so
  users can grab partial action items.
- **Delete confirmation.** Shared `GlassAlertDialog` with
  `primaryDestructive: true`.
- **Note-not-found state.** Renders a minimal glass screen (mesh +
  floating back button + a centred "Note not found." message) instead
  of falling back to a flat M3 surface mid-flow.

### Sign in (`lib/features/auth/sign_in_screen.dart`)

Fifth non-home screen on the glass theme -- and the _first_ screen
new users see, so it's the first impression of the brand. Layout:

- **Sits over `MeshGradientBackground`.**
- **Hero `_BrandMedal`.** 80 dp amber-gradient disc with a soft amber
  bloom shadow and the `graphic_eq_rounded` glyph. Replaces the
  M3 plain-text title-only header.
- **Display title.** "Welcome back" / "Create your account", 30 dp,
  `letterSpacing: -0.5`.
- **Single muted subtitle line.** "Sign in to sync your data across
  devices."
- **Email + password card.** A `GlassCard` wraps both inputs, the
  inline `_ErrorChip`, the primary CTA, and the sign-in / sign-up
  toggle so the whole "credentials" group reads as one surface.
- **`_GlassTextField` private widget.** Mesh-aware `TextField` wrapper
  with a 6 % white fill (dark) / 55 % white fill (light), 1 px hairline
  border, `borderRadius: 14`, amber-600 cursor + focus border. Prefix
  icon uses the muted-foreground colour. Replaces the M3 default
  underline-style `InputDecoration`.
- **Primary CTA** is the shared `GradientPillButton` with `loading: _busy`,
  so the busy state automatically swallows double-taps (matches the
  Paywall + Record CTAs).
- **`_ErrorChip`.** Inline red-tinted glass-style chip with an icon
  and the auth error message. Replaces the M3 plain-text red error.
- **`_OrDivider`.** Two hairlines flanking a centred "or" label,
  hairline colour adjusted for the mesh.
- **Google button.** Hand-rolled `_GoogleButton`: glass-outlined pill
  with the G mark + "Continue with Google" label. Disabled state
  drops opacity to 0.55 so the brand colour stays visible. Replaces
  the M3 `OutlinedButton.icon`.
- **Anonymous sign-in.** Quiet centred `TextButton` ("Skip — try it
  first") at the bottom.

The whole screen is centred + scrollable so it works on small
landscape phones too -- previously the M3 layout would crop the
"Skip" button on short keyboards.

### Onboarding (`lib/features/onboarding/onboarding_screen.dart`)

Sixth (and last) screen on the glass theme. The 3-page intro carousel
new users see before the first home screen render. Final piece of the
brand-first-impression chain: Onboarding → Sign in → Home.

- **Sits over `MeshGradientBackground`.**
- **Skip pill.** Floating `GlassPillButton` ("Skip") in the top-right,
  replacing the M3 `TextButton`. Calls the same `markComplete()` path
  as the final-page CTA.
- **Three pages, all RecapCoach-specific copy.** Old M3 cut still
  shipped the boilerplate "Your starter kit for shipping Android apps"
  language from a template; new pages are:
  1. _Recap any call instantly_ -- value prop.
  2. _Free to start_ -- tier explanation (5 free / 100 + 8h Pro).
  3. _Private by default_ -- privacy stance.
- **`_HeroDisc`.** 132 dp amber-gradient circle with a 1.5 px white
  hairline border and two stacked amber bloom shadows -- same halo
  vocabulary as the home FAB and the record-screen mic disc, so the
  brand feels consistent before the user has even seen those screens.
- **Display title.** 30 dp, `letterSpacing: -0.5`, centred.
- **Body copy.** 15.5 dp muted, `height: 1.5`, centred.
- **Page indicator.** `SmoothPageIndicator` with `WormEffect`,
  active dot tinted `AppColors.amber600`, inactive dots a
  low-alpha slate so they read on the mesh.
- **Bottom CTA.** Shared `GradientPillButton`. On the last page the
  label flips to "Get started" + adds a forward-arrow icon for an
  extra "this is the moment of commit" beat.
- **`use_build_context_synchronously` warning fixed.** The old
  M3 cut had a `context.go(...)` call after an `await` guarded only
  by an unrelated `mounted` check; the new
  `_completeAndGoHome()` adds the explicit guard before each
  `context` use.

### Tests

| File                                                            | Tests | Coverage                                                                              |
| --------------------------------------------------------------- | ----- | ------------------------------------------------------------------------------------- |
| `test/core/widgets/glass/gradient_pill_button_test.dart`        | 5     | idle / loading (CRITICAL: tap-swallow) / disabled / no-icon / dark-theme builds clean |
| `test/core/widgets/glass/glass_icon_button_test.dart`           | 4     | renders + onPressed / custom tint / dark-mode default fg / both themes build clean    |
| `test/core/widgets/glass/glass_pill_button_test.dart`           | 3     | label + onPressed / optional icon + tint / dark-theme builds clean                    |
| `test/features/recording/widgets/amplitude_pulse_mic_test.dart` | 4     | silence smoke / loud > quiet size / defensive amplitude clamp / dark-theme builds     |
| `test/features/recording/widgets/amplitude_waveform_test.dart`  | 4     | default 20 bars / custom barCount / defensive amplitude clamp / dark-theme builds     |

Paywall + Record screens themselves are not yet covered by widget
tests because they reach into Firebase Analytics + RevenueCat +
record-package statics during init; we'd need to refactor `Analytics`,
`PurchasesService`, and `AudioRecorderService` for full testability
first. The hang fix in commit `7742178` is exercised end-to-end in
dev (stub mode == empty offerings == stub tile renders).

```powershell
flutter test test\core\ test\features\recording\
```
