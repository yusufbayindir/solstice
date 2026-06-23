# Solstice — Design System

Prepared by: Product Designer
Date: 2026-06-23
Platform: iOS 18+, SwiftUI, SF Pro (system font), Dynamic Type, light + dark mode.

Solstice is a privacy-first, local-first menstrual cycle tracker. Trust is the product, so
privacy must be *visible* in the UI. This document is the single source of truth for color,
type, spacing, motion, and components. Every value here is concrete: real hex, real point
sizes, real SF Symbol names. A developer should be able to build without guessing.

---

## 1. Brand feel & design principles

**Brand adjectives (the three): Calm. Premium. Trustworthy.**

(Inclusive and modern are table stakes carried throughout; the three above are the felt
identity.)

We synthesize the best of the references and discard their weaknesses:
- From **Flo**: prediction clarity and onboarding polish — *without* the cloud account or upsell.
- From **Clue**: science-forward, plain-language honesty — *without* the ads and paywall regressions.
- From **Drip/Euki**: genuine privacy and an inclusive, non-pink palette — *without* the dated,
  buggy, utilitarian feel.

### Design principles

1. **Calm by default.** Generous whitespace, one focal element per screen, muted surfaces,
   restrained motion. The app should feel like a quiet, well-made notebook, not a dashboard.
2. **Privacy you can see.** A persistent, honest visual language for "this stays on your phone":
   a lock glyph, the phrase "On this iPhone," and a Privacy Center that's one tap from anywhere.
   Never dark-pattern. Never nag.
3. **Inclusive, not pink-default.** No pink as the primary brand color, no gendered cutesy
   iconography, gender-neutral copy ("your cycle," "people who menstruate" where needed). Color
   communicates cycle *phases*, not gender.
4. **Fast over fancy.** Core logging is reachable in one tap and completable in under 5 seconds.
   Predictions and trends are glanceable. Depth is available but never in the way.
5. **Honest hierarchy.** Logged (known) data is rendered solid and confident. Predicted
   (uncertain) data is rendered lighter, dashed, or with an explicit confidence range. The user
   always knows what is fact vs. forecast.
6. **Native and respectful.** Follow Apple HIG: system materials, SF Symbols, Dynamic Type, Face
   ID, standard navigation. Feel like it belongs on iOS 18.

---

## 2. Color palette

Color is the brand's calm signature: a warm, grounded **terracotta/clay accent** (premium,
non-pink, gender-neutral) paired with a near-neutral warm-gray canvas. Cycle phases use a
distinct, color-blind-considerate hue family (clay/red = period, teal = fertile, amber =
ovulation) so meaning never relies on a single hue alone — it's reinforced by shape and label.

All foreground/background pairings below meet **WCAG AA** (≥4.5:1 for body text, ≥3:1 for large
text and UI components). Contrast ratios are noted where load-bearing.

### Accent

**Accent (primary brand): `#C2613D` (Clay / terracotta), light mode.**
Dark-mode accent lightens to `#E08A63` for contrast on dark surfaces.

Rationale: warm, premium, calm, and emphatically *not* pink-default. Reads as inclusive and
modern; evokes "solstice" warmth/light. It is also visually distinct from the period red so the
brand accent and the period semantic never get confused.

### Light mode

| Semantic name        | Hex        | Usage / notes |
|----------------------|------------|---------------|
| `background`         | `#FAF7F3`  | App canvas. Warm off-white (not pure white). |
| `surface`            | `#FFFFFF`  | Cards, sheets, list backgrounds raised above canvas. |
| `surfaceSecondary`   | `#F2EDE7`  | Grouped row fills, input fields, segmented track. |
| `separator`          | `#E4DDD4`  | Hairline dividers (1px @1x). |
| `primary`            | `#C2613D`  | Primary action / brand. On white = 4.6:1 (AA for large + UI; pair with weight ≥ semibold for body-size labels, or use `textPrimary` for long text). |
| `primaryPressed`     | `#A64F2F`  | Pressed/active state of primary. |
| `accentSoft`         | `#F3E2D8`  | Tinted fill behind accent icons / selected chips. |
| `textPrimary`        | `#2A2521`  | Body + headings. On `background` = 13.9:1. |
| `textSecondary`      | `#6B6258`  | Captions, secondary labels. On `background` = 5.2:1 (AA). |
| `textTertiary`       | `#9A9085`  | Placeholder, disabled. On `surface` = 3.0:1 — large/UI only, never body. |
| `period`             | `#C0392B`  | Logged period days. On white = 4.9:1. |
| `periodSoft`         | `#F6DCD8`  | Period fill behind text / calendar wash. |
| `fertile`            | `#2E8B8B`  | Fertile-window days (teal). On white = 4.0:1 (large/UI; use solid swatch + label). |
| `fertileSoft`        | `#D8ECEC`  | Fertile-window calendar wash. |
| `ovulation`          | `#C9882B`  | Ovulation day (amber). On white = 3.4:1 (UI/large + always paired w/ a dot marker). |
| `ovulationSoft`      | `#F6E9CF`  | Ovulation wash. |
| `predicted`          | `#B9AFA3`  | Predicted (not-yet-logged) outlines/dashes — warm gray, low confidence read. |
| `success`            | `#3C7D5A`  | Confirmations, "saved," Health-sync OK. 4.5:1 on white. |
| `warning`            | `#B26A1C`  | Caution states. |
| `destructive`        | `#C0392B`  | Delete-all, destructive actions (shares `period` red intentionally — but always labeled). |
| `lockTint`           | `#3E6B8B`  | Privacy/lock accent (calm slate-blue) used ONLY for privacy + Face ID UI, so "protected" is a recognizable second signal distinct from the warm brand. 4.5:1 on white. |

### Dark mode

True-dark-friendly but warm; surfaces are warm charcoals, not blue-black. Avoid pure `#000` for
the canvas to reduce smearing; use it only for OLED-edge accents if desired.

| Semantic name        | Hex        | Usage / notes |
|----------------------|------------|---------------|
| `background`         | `#181512`  | App canvas (warm near-black). |
| `surface`            | `#221E1A`  | Cards / sheets raised above canvas. |
| `surfaceSecondary`   | `#2C2722`  | Inputs, grouped fills, segmented track. |
| `separator`          | `#393229`  | Hairline dividers. |
| `primary`            | `#E08A63`  | Accent on dark. On `background` = 7.1:1. |
| `primaryPressed`     | `#C2613D`  | Pressed accent. |
| `accentSoft`         | `#3A2A20`  | Tinted fill behind accent icons. |
| `textPrimary`        | `#F4EFE9`  | Body + headings. On `background` = 14.6:1. |
| `textSecondary`      | `#B7ADA0`  | Secondary labels. On `background` = 7.4:1. |
| `textTertiary`       | `#7E756A`  | Placeholder/disabled. Large/UI only. |
| `period`             | `#E76A5B`  | Logged period days. On `background` = 5.6:1. |
| `periodSoft`         | `#3A201C`  | Period wash. |
| `fertile`            | `#4FB3B3`  | Fertile window. On `background` = 6.9:1. |
| `fertileSoft`        | `#16302F`  | Fertile wash. |
| `ovulation`          | `#E0A84A`  | Ovulation. On `background` = 8.1:1. |
| `ovulationSoft`      | `#332710`  | Ovulation wash. |
| `predicted`          | `#6C6359`  | Predicted dashes/outlines. |
| `success`            | `#5FB585`  | Confirmations. |
| `warning`            | `#D08A3A`  | Caution. |
| `destructive`        | `#E76A5B`  | Destructive. |
| `lockTint`           | `#6FA2C4`  | Privacy/lock accent. On `background` = 6.6:1. |

### Color usage rules

- **Never encode meaning by hue alone.** Calendar phase cells always carry a glyph or label in
  addition to color (period = filled dot, fertile = ring, ovulation = small diamond/star) so the
  app is usable with deuteranopia/protanopia and at a glance.
- **Accent ≠ period.** The clay brand accent (`primary`) and the period red (`period`) are
  deliberately separated in hue. Buttons/links use `primary`; cycle data uses `period`.
- **Privacy uses `lockTint`.** The slate-blue lock tint is reserved for Face ID, Privacy Center,
  and "stays on device" affordances so "protected" has its own consistent visual.
- Define all of the above as a `Color` asset catalog set with Any/Dark appearances, surfaced
  through a `Theme` enum (e.g. `Color.theme.period`). Do not hardcode hex in views.

---

## 3. Typography

System font **SF Pro** via `.font(.system(...))` mapped to iOS text styles so **Dynamic Type**
scales everything. Sizes below are the default (Large) content-size category; never hardcode —
use the named text style and let it scale. Rounded design is used only for the large numeric
"day of cycle" readout to feel friendly; everything else is default SF Pro.

| Token            | iOS text style | Default size / weight        | Use |
|------------------|----------------|------------------------------|-----|
| `displayRing`    | `.largeTitle` (rounded) | 48 pt / Bold, rounded | The big number inside the cycle ring ("Day 14"). |
| `largeTitle`     | `.largeTitle`  | 34 pt / Bold                 | Screen hero titles (onboarding steps). |
| `title1`         | `.title`       | 28 pt / Bold                 | Primary screen titles. |
| `title2`         | `.title2`      | 22 pt / Bold                 | Section headers, card titles. |
| `title3`         | `.title3`      | 20 pt / Semibold             | Sub-section / prominent row titles. |
| `headline`       | `.headline`    | 17 pt / Semibold             | Emphasized list rows, button labels. |
| `body`           | `.body`        | 17 pt / Regular              | Body copy, default. |
| `callout`        | `.callout`     | 16 pt / Regular              | Secondary body, helper text. |
| `subheadline`    | `.subheadline` | 15 pt / Regular              | Supporting labels. |
| `footnote`       | `.footnote`    | 13 pt / Regular              | Captions, metadata, "On this iPhone." |
| `caption1`       | `.caption`     | 12 pt / Regular              | Chart axis labels, calendar weekday row. |
| `caption2`       | `.caption2`    | 11 pt / Medium                | Smallest legal/footnote text. |

Rules:
- **Always use the semantic text style**, e.g. `.font(.title2)`, so Dynamic Type + accessibility
  sizes work. For the rounded numeric readout: `.font(.system(.largeTitle, design: .rounded).weight(.bold))`.
- Support up to and including the **AX5** accessibility sizes. Verify no clipping at AX5; allow
  text to wrap and rows to grow vertically rather than truncating cycle/predication data.
- Line length: cap body text at ~`66ch` on wide layouts (iPad later); on iPhone, full content width
  minus margins.
- Tracking/leading: rely on system defaults. Do not manually tighten — keep it calm and legible.

---

## 4. Spacing, radii, elevation

### Spacing scale (4pt base)

`xxs 4` · `xs 8` · `sm 12` · `md 16` · `lg 20` · `xl 24` · `xxl 32` · `xxxl 48`

- Screen horizontal margin: `md (16)` standard; `lg (20)` for hero/onboarding screens.
- Vertical rhythm between sections: `xl (24)`.
- Inside cards: `md (16)` padding.
- Min spacing between two tappable controls: `xs (8)`.

### Corner radii

| Token        | Value | Use |
|--------------|-------|-----|
| `radiusSm`   | 8 pt  | Chips, small controls, segmented thumb. |
| `radiusMd`   | 12 pt | Inputs, list-row groups. |
| `radiusLg`   | 16 pt | Cards, sheets content, primary buttons. |
| `radiusXl`   | 24 pt | Large hero cards, bottom-sheet top corners. |
| `radiusPill` | ∞ (capsule) | Pill buttons, tags, the FAB. |

### Elevation / shadow

Calm and minimal — prefer separation by surface color + hairline over heavy shadows. Two levels only.

- `elevation0`: no shadow. Flush content on `background`.
- `elevation1` (cards): `color black @ 6% opacity, y: 2, blur: 8, spread: 0`. In dark mode use
  `black @ 24%` and rely more on `surface` lightness for separation.
- `elevation2` (sheets, FAB, popovers): `black @ 10%, y: 6, blur: 20`. Dark: `black @ 36%`.
- Never stack shadows. Use system `Material` (`.regularMaterial`, `.thinMaterial`) for nav bars,
  the app-lock blur, and bottom sheets instead of custom translucency.

---

## 5. Iconography (SF Symbols)

Use **SF Symbols 6**, default weight matching adjacent text (Regular/Medium), rendered
`.hierarchical` for most UI and `.multicolor`/`.palette` only for phase legends. Standard mapping:

| Meaning            | SF Symbol                        |
|--------------------|----------------------------------|
| Home / today       | `house` / `house.fill`           |
| Calendar           | `calendar`                       |
| Log / add          | `plus` (in a capsule FAB)        |
| Insights / trends  | `chart.xyaxis.line` / `chart.bar.xaxis` |
| Privacy / settings | `gearshape`                      |
| Privacy center     | `lock.shield` (uses `lockTint`)  |
| App lock / Face ID | `faceid`, `lock.fill`            |
| Period / flow      | `drop.fill`                      |
| Flow level         | `drop`, `drop.halffull`, `drop.fill`, `drop.triangle` (light→heavy) |
| Fertile window     | `leaf.fill` (calm, ungendered)   |
| Ovulation          | `sparkle` / `star.fill` (amber)  |
| Symptom            | `bandage`, `bolt.heart`, `zzz` (per symptom, see Log spec) |
| Mood               | `face.smiling`, `cloud`, `wind` (per mood) |
| Export             | `square.and.arrow.up`            |
| Delete all         | `trash`                          |
| Apple Health       | `heart.text.square`              |
| Widget             | `square.grid.2x2`                |
| Edit / confirm     | `pencil`, `checkmark`            |
| Info / what's stored | `info.circle`                  |
| Prediction (forecast) | `sparkles` (subtle, used sparingly) |

Rules: icons accompany text labels for all primary actions (never icon-only for destructive or
privacy actions). Minimum rendered glyph size 17pt within a 44×44 hit target.

---

## 6. Motion

Calm, quick, purposeful. iOS-native spring feel; nothing bouncy or playful.

- **Default transition spring:** `.spring(response: 0.35, dampingFraction: 0.86)`.
- **Tap feedback:** controls scale to `0.97` on press, return on release; `.snappy(duration: 0.18)`.
- **Cycle ring:** on appear and after a new log, the active progress arc animates from its prior
  value to the new value over `0.6s` with ease-in-out; the day number cross-fades, never spins.
- **Sheet present/dismiss:** standard system sheet with `.presentationDetents`. No custom physics.
- **Haptics:** `.selection` on segmented/toggle changes; `.success` notification haptic on save /
  successful export / completed onboarding; `.warning` before destructive confirm.
- **Respect Reduce Motion:** when enabled, replace the ring arc animation and any cross-fade with
  an instant state change or a simple opacity fade ≤ 0.2s. No parallax, ever.
- Loading: prefer **skeleton placeholders** (surfaceSecondary shimmer at 0.6→1.0 opacity, 1.2s,
  disabled under Reduce Motion → static placeholder) over spinners, except for ≤1s system waits.

---

## 7. Component inventory

All components read colors from the `Theme`, scale with Dynamic Type, and meet a **44×44pt**
minimum touch target.

### 7.1 Buttons

| Variant        | Fill / border | Label | Height | Radius | States |
|----------------|---------------|-------|--------|--------|--------|
| **Primary**    | `primary` fill, white label | `headline` semibold, centered | 50 pt | `radiusLg (16)` | default / pressed (`primaryPressed`, scale 0.97) / disabled (`textTertiary` fill 40%) / loading (inline `ProgressView`, label hidden, button width fixed). |
| **Secondary**  | `surface` fill, `separator` 1px border, `primary` label | `headline` | 50 pt | `radiusLg` | pressed = `surfaceSecondary` fill. |
| **Tertiary / text** | none, `primary` label | `body` | 44 pt | — | pressed = 0.6 opacity. |
| **Destructive**| `destructive` label on `surface`, 1px `destructive` border (filled `destructive` only inside an explicit confirm dialog) | `headline` | 50 pt | `radiusLg` | requires confirm dialog for irreversible ops. |
| **FAB (log)**  | `primary` fill capsule, white `plus` + "Log" label | `headline` | 56 pt | `radiusPill` | floats bottom-trailing on Home & Calendar; `elevation2`. |

All buttons full-width by default on forms; FAB is content-sized. Disabled buttons keep their
shape but drop to `textTertiary` and are non-interactive (announce "dimmed" to VoiceOver).

### 7.2 Cards

- Container: `surface` fill, `radiusLg (16)`, `elevation1`, `md (16)` inner padding, full content
  width with `md` screen margins.
- Optional header row: `title3` title + trailing `info.circle` button (for "how this is
  predicted" explainers).
- Cards never have more than one primary action; deeper actions live in the card's destination.

### 7.3 List rows

- Standard `Form`/`List` with `.insetGrouped` style on a `background` canvas, `surface` rows.
- Row height ≥ 44pt; layout: leading SF Symbol (in `accentSoft` 28pt rounded-rect tile, optional)
  · `body` title (+ optional `footnote` subtitle in `textSecondary`) · trailing value/`chevron`.
- Toggle rows use system `Toggle` tinted `primary`. Destructive rows use `destructive` label.

### 7.4 Inputs & pickers

- **Text/number field:** `surfaceSecondary` fill, `radiusMd (12)`, `md` padding, `body` text,
  `textTertiary` placeholder, focus ring = `primary` 2px. Min height 44pt.
- **Date picker:** native `DatePicker` (`.graphical` for onboarding last-period selection,
  `.compact` inline elsewhere), tinted `primary`.
- **Stepper / length picker:** native wheel `Picker` in a sheet for cycle/period length (range
  shown, e.g. 21–35 days), or `Stepper` rows. Always show the chosen value large.
- **Flow / intensity selector:** horizontal row of 4 tappable `drop` glyphs (none/light/medium/
  heavy), selected = filled `period`, 44×44 each.

### 7.5 Segmented control

- Native `Picker(.segmented)` on `surfaceSecondary` track, selected thumb `surface` +
  `elevation1`, selected label `textPrimary` semibold, unselected `textSecondary`. `radiusSm`
  thumb. Used for Calendar month/cycle toggle and Trends time-range (3/6/12 cycles).

### 7.6 Cycle ring (the centerpiece — precise spec)

A single circular ring is the home dashboard's hero. It is a **fixed 360° track** representing the
*current predicted cycle* (day 1 → predicted next period). Diameter 260pt on standard iPhone
(scales down to fit width on small devices, min 220pt); stroke width **18pt**, round line caps.

**Geometry & segments** (drawn clockwise, 12 o'clock = day 1 of cycle):

1. **Track (base):** full circle, `separator` color, 18pt — the unfilled cycle.
2. **Period segment:** arc from day 1 spanning the (logged or predicted) period length, color
   `period`. If those days are *logged*, draw solid; if *predicted future* period, draw with a
   subtle inner texture — same color at 55% opacity — so logged vs forecast period reads
   differently.
3. **Fertile-window segment:** arc covering the predicted fertile window (typically ~6 days),
   color `fertile`. Drawn slightly *inset* (a thinner 10pt arc nested just inside the main ring at
   the same angular position) so it can coexist with the period/progress arcs without overlap
   ambiguity.
4. **Ovulation marker:** a single **amber `ovulation` diamond/dot (8pt)** sitting on the ring at
   the predicted ovulation day, plus a 2pt amber tick. It's a point, not an arc.
5. **Today / progress indicator:** a filled `primary` (clay) **knob** (16pt circle, white 2pt
   inner ring) positioned at *today's* angle. The arc from day 1 up to today is rendered in
   `primary` at 30% opacity *under* the phase arcs as a faint "elapsed" sweep, so you can see how
   far through the cycle you are. The knob is the "you are here."

**Center content (stacked):**
- Line 1: `footnote` `textSecondary` label — e.g. "CYCLE DAY".
- Line 2: `displayRing` (48pt rounded bold) number — e.g. "14".
- Line 3: `callout` `textSecondary` — the headline prediction, e.g. "Period in 12 days" or
  "Fertile window" or "Period — Day 2".
- The center text color shifts to the *current phase* color subtly (e.g. period red during
  menstruation) but stays AA against `surface`.

**Legend:** below the ring, a compact horizontal legend: ● Period · ◐ Fertile · ◆ Ovulation ·
● Today, each swatch + label (`caption1`), so color is never the only cue.

**Confidence:** when prediction confidence is low (sparse history), the predicted period arc is
drawn **dashed** and a `footnote` under the ring reads "Estimate improves as you log more."

**Accessibility:** the entire ring is a single VoiceOver element with a composed label, e.g.
*"Cycle day 14 of 28. Fertile window. Next period predicted in 12 days, on July 5. Estimate."*
The decorative arcs are `.accessibilityHidden(true)`; only the composed summary is announced.
Honor Reduce Motion (no sweep animation) and Increase Contrast (bump arc opacities to 100%,
thicken the today knob ring).

### 7.7 Calendar cell

- Month grid, 7 columns; cell is a 44×44 (min) tappable square with the day number centered
  (`body`). Today: `primary` 1.5pt ring around the number.
- **Logged period day:** solid `periodSoft` rounded-square wash with a small filled `period` dot
  under the number; the number stays `textPrimary`.
- **Predicted period day:** `period`-colored **dashed** rounded outline (no fill) + hollow dot —
  clearly "forecast."
- **Fertile day:** `fertileSoft` wash + tiny `fertile` ring glyph.
- **Ovulation day:** `ovulationSoft` wash + amber diamond glyph above the number.
- **Logged symptom/mood present:** a 4pt `textSecondary` dot beneath the number (indicates "has
  notes"); does not change the phase color.
- Selected day: `primary` filled circle behind number, white number.
- Out-of-month days: `textTertiary`, no decoration.
- Each cell VoiceOver label: "July 5, predicted period, cramps logged." Decorative glyphs hidden.

### 7.8 Charts (Swift Charts)

- Library: **Swift Charts**. Calm styling: thin 2pt lines, rounded caps, muted gridlines
  (`separator`), axis labels `caption1` `textSecondary`.
- **Cycle-length history:** bar chart, bars `primary`, average line dashed `textSecondary`.
- **Symptom/mood frequency by cycle day:** horizontal bars or a heat strip (day 1–N) per symptom,
  colored by `accentSoft`→`primary` intensity ramp; always with a numeric label, never color-only.
- **Mood over time:** line/area with `accentSoft` fill at 25% under a `primary` line.
- Empty data range → show the empty-state template (7.10), not an empty axis.
- Charts get an `.accessibilityChartDescriptor` and per-series summaries; support audio graphs.

### 7.9 App-lock screen (component)

See full screen spec, but as a component: full-screen `background`, centered Solstice wordmark/
glyph, a `lock.shield` in `lockTint`, copy "Solstice is locked," and a primary "Unlock with Face
ID" button (`faceid` symbol). Content behind is covered by `.regularMaterial` blur so no cycle
data is visible. Auto-invokes biometric on appear.

### 7.10 Empty / error state templates

**Empty template:** centered, vertically optical-centered stack — a hierarchical SF Symbol
(48pt, `textTertiary`/`accentSoft`), `title3` headline, `callout` `textSecondary` one-line
explanation, and (optional) one primary or tertiary CTA. Calm, encouraging copy. Examples:
- Trends with no data: `chart.xyaxis.line`, "No trends yet," "Log a few cycles and patterns will
  appear here — all computed on your iPhone." CTA: "Log today."
- Calendar future month: no empty state; show predictions.

**Error template:** same layout, symbol `exclamationmark.triangle` in `warning`, `title3`
headline ("Couldn't save"), `callout` cause + remedy, primary "Try again" + tertiary "Dismiss."
Errors are rare (local-only app) — mostly used for Health/export/Face ID failures. Never blame
the user; never expose raw error strings.

**Loading template:** skeleton placeholders matching the destination layout (ring outline +
gray bars), per motion rules. Spinner only for sub-second system calls.

### 7.11 Privacy badge (recurring component)

A small reusable inline element: `lock.fill` (12pt, `lockTint`) + `footnote` `textSecondary`
"On this iPhone." Appears on onboarding, the Privacy Center, export confirmations, and the
settings footer. This is the persistent, visible trust signal.

---

## 8. Navigation model

- Root: **TabView**, 4 tabs — **Home** (`house`), **Calendar** (`calendar`), **Insights**
  (`chart.xyaxis.line`), **Settings** (`gearshape`). Privacy Center is reached from Settings and
  from a `lock.shield` affordance on Home.
- The **Log** action is a floating capsule FAB on Home and Calendar (not a tab) — present logging
  as a fast modal sheet from anywhere, so it's always one tap.
- App-lock gates the entire TabView; onboarding is a separate full-screen flow shown once.
- Standard `NavigationStack` within each tab; large titles where appropriate; back swipe enabled.

---

## 9. Accessibility (global standards)

- **Dynamic Type:** all text uses semantic styles; verified legible and non-clipping through AX5.
- **Touch targets:** ≥44×44pt for every interactive element; ≥8pt between adjacent targets.
- **Contrast:** all body text AA (≥4.5:1); UI/large ≥3:1; verified against the tables in §2.
  Honor Increase Contrast (raise wash opacities, add borders).
- **VoiceOver:** every control has a label + (where useful) hint + value/trait. Composite visuals
  (ring, cells, charts) expose a single meaningful summary; decoration is hidden.
- **Color independence:** phases carry glyph/label, never hue alone (color-blind safe).
- **Reduce Motion / Reduce Transparency:** respected throughout (see §6); swap materials for
  solid fills when Reduce Transparency is on.
- **Privacy & a11y:** the app-lock and Privacy Center are fully VoiceOver-navigable; Face ID
  prompt uses the system sheet.
