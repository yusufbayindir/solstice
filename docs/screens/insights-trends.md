# Screen Spec — Insights & Trends

Part of Solstice. References `design-system.md`. The analytics view: surface meaningful patterns
across multiple logged cycles so the user can understand their body over time — without requiring
an account, cloud, or any data leaving the device.

## Purpose

Show symptom frequency, flow intensity, mood correlation, and cycle-length variability charted
across the user's logged history. All computation and rendering happens on-device via Swift Charts.
The screen is informational — no action is required, no nag, no upsell.

## Layout (top → bottom)

`NavigationStack` → `ScrollView` over `background`. Large nav title "Insights." Top-trailing nav
bar: `lock.shield` button (`lockTint`) → Privacy Center.

Below the nav title, a **segmented control** (design-system §7.5, full-width, `md` side margins):
"3 Cycles" · "6 Cycles" · "12 Cycles." Selected segment drives all charts. Default = 6 Cycles
(shows meaningful patterns without overwhelming). Segments are disabled (shown at 40% opacity with
a `textTertiary` label) if logged-cycle count is below that segment's threshold; the 3 Cycles
segment is always enabled once 2 cycles are logged.

---

### Section 1 — Cycle Length History

Section header: `title2` "Cycle Lengths" + trailing `info.circle` → explainer sheet ("Logged
cycle lengths measured from first day to first day of the next period. Longer or shorter bars are
not health signals on their own — natural variation is normal.").

A **vertical bar chart** (Swift Charts `BarMark`):
- X-axis: cycle number, labeled "Cycle 1," "Cycle 2," … `caption1` `textSecondary`. If N > 8,
  labels step by 2 or use abbreviated "C1," "C2" to avoid crowding. Never rotate labels; truncate
  axis label count before rotating.
- Y-axis: days (integer), gridlines `separator` 1pt, axis labels `caption1` `textSecondary`.
  Y-range: min(cycle lengths) − 2 to max + 2, minimum visible range 15–35.
- Bars: `primary` (#C2613D light / #E08A63 dark), `radiusSm` (8pt) top corners, 2pt gap between
  bars.
- Average line: dashed `RuleMark` at the user's mean cycle length, `textSecondary`, 1.5pt. Labeled
  with a trailing `caption1` annotation "Avg 28d."
- Logged (complete) bars are solid fill; any partial/in-progress current cycle bar is rendered at
  50% opacity with a `sparkles` tip icon (`caption2` "In progress").
- Tapping a bar pushes to **Cycle Detail** (see Navigation).

### Section 2 — Flow Intensity Over Days

Section header: `title2` "Flow Intensity" + trailing `info.circle` → explainer sheet.

A **grouped area/line chart** (Swift Charts `LineMark` + `AreaMark`):
- X-axis: cycle day (1 → longest logged period, usually 1–7), `caption1`.
- Y-axis: flow level 0–3 (None=0, Light=1, Medium=2, Heavy=3), labeled at those four integers:
  `caption1` "None" / "Light" / "Medium" / "Heavy."
- One translucent area series per cycle in the selected range. Series are `accentSoft`
  (#F3E2D8 light / #3A2A20 dark) fill at 20% opacity; the most recent cycle gets `primary` at 35%
  fill and a solid 2pt `primary` line on top. Older cycles use `textSecondary` 1pt lines.
- Gridlines: `separator`, horizontal only.
- A separate `RuleMark` average line (`textSecondary` dashed 1.5pt) plots the per-day mean across
  selected cycles.
- Tapping the chart → no drill-down; tapping a specific cycle's line/area highlights it (other
  series dim to 10% opacity) and shows an inline tooltip at the tap point: card-style popover,
  `surface`, `radiusMd`, showing "Cycle N · Day X · Medium flow."

### Section 3 — Symptom Frequency

Section header: `title2` "Symptoms" + trailing `info.circle`.

A **horizontal heat-strip** for each symptom the user has ever logged, showing frequency per cycle
day (design-system §7.8):
- Rows: one `HStack` per symptom. Leading: SF Symbol + symptom name (`subheadline` `textPrimary`),
  fixed 130pt width. Trailing: a horizontal strip of up to N (= selected range) cells, each cell
  `xs (8)` wide × 20pt tall, spaced `xxs (4)`. Cell color: `surfaceSecondary` (never logged),
  `accentSoft` (logged ≤ 33% of cycles), `primary` at 60% opacity (34–66%), solid `primary`
  (≥67%). Each cell also carries a numeric count as an `.accessibilityLabel`.
- A count-label `caption1` at the far right of each row: "4 / 6 cycles."
- Rows sorted descending by total logged frequency.
- If the user has > 8 symptom types, show the top 8 and a tertiary "Show all symptoms" button below.
- No tapping per cell; tapping the whole row → Cycle Detail filter view (future).

### Section 4 — Mood Correlation

Section header: `title2` "Mood Patterns" + trailing `info.circle` → explainer ("Mood is logged
alongside your cycle and shown as frequency by phase. Patterns may vary — this is your data, not a
diagnosis.").

A **grouped bar chart** with cycle phase on the X-axis and mood frequency on the Y-axis:
- X-axis groups: "Period," "Follicular," "Fertile," "Luteal" — `caption1`, colored by phase
  (`period`, `primary`, `fertile`, `ovulation`). Never hue-only: add the label below each group.
- Y-axis: frequency as a percentage (0–100%), gridlines `separator`.
- Each group contains bars for logged mood types (up to 4 most-frequent, `caption2` labels).
  Bar colors: phase-tinted `accentSoft` → `primary` ramp with pattern fills disabled (use hue
  only at sufficient contrast). Bars use `radiusSm` top corners.
- If fewer than 4 moods logged, render only the logged set; no phantom bars.

---

### Bottom privacy anchor

`Privacy badge` component (`lock.fill` `lockTint` + `footnote` `textSecondary` "Insights computed
on this iPhone — your data never leaves.") centered with `xl (24)` top padding, `xxxl (48)` bottom
padding (above tab bar).

---

## Cycle Detail (drill-down screen)

Pushed from tapping a bar in the Cycle Length chart or from a future row tap.

`NavigationStack` push → title "Cycle N" (e.g. "Cycle 3"). Back button standard.

Layout (compact, single screen if possible):
1. **Cycle summary card** — `surface`, `radiusLg`, `md` padding: date range (`callout`
   `textSecondary` "Jun 1 – Jun 28"), length (`title2` "28 days"), period length ("Period: 5 days").
2. **Flow by day** — the single-cycle version of the flow area chart (Section 2 style, one series,
   `primary` fill at 40%). Day 1–N on X-axis.
3. **Logged symptoms & moods** — two `List` sections, `.insetGrouped`, rows using
   design-system §7.3. Each symptom row: day range logged (e.g. "Days 1–3"), `caption1`. Each mood
   row: same. "None logged" placeholder if empty.
4. **Privacy badge** at bottom.

---

## States

### Loading (skeleton)
Visible only if chart compute or CoreData fetch exceeds ~150ms (uncommon on-device). Skeleton
layout matches final layout exactly:
- Segmented control: rendered at full width with faded placeholder text (`textTertiary` 40%
  opacity).
- Each chart area: `surfaceSecondary` rounded rectangle, same approximate height as the populated
  chart, shimmer animation (opacity 0.6 → 1.0, 1.2s ease-in-out, looping). Under Reduce Motion:
  static `surfaceSecondary` rectangle, no shimmer.
- Section headers: `surfaceSecondary` placeholder pill, 120pt wide × 20pt tall.

### Empty (fewer than 2 complete cycles logged)
A single centered empty-state template fills the scroll view below the segmented control (which is
fully disabled at this state):
- Icon: `chart.xyaxis.line`, 48pt, `textTertiary`.
- `title3` "No trends yet."
- `callout` `textSecondary` "Log a couple of cycles and patterns will appear here — everything
  computed on your iPhone."
- Primary CTA button "Log today" (full-width, `radiusLg`): opens the Log sheet.
- Below button: `Privacy badge` ("On this iPhone").
No charts are rendered; there is no empty axis, no partial chart.

### Populated (2+ complete cycles)
Full layout as described above. Segmented control enables available segments.

### Error
If CoreData fetch throws or Swift Charts encounters a rendering error (rare):
- The affected chart section's card replaces its content with the error template (design-system
  §7.10): `exclamationmark.triangle` `warning`, `title3` "Couldn't load this chart,"
  `callout` `textSecondary` "Your data is safe — try pulling down to refresh."
- Other sections still render independently. The error is scoped per section card.
- Pull-to-refresh re-runs the fetch for all sections. `.success` haptic on successful reload.

---

## Key Interactions

- Segmented control tap → all charts re-render for the new range with a `spring(response: 0.35,
  dampingFraction: 0.86)` cross-fade of the chart data. `.selection` haptic. No skeleton shown
  during range switch (data already on device; transition is fast).
- Tap a Cycle Length bar → push to Cycle Detail screen for that cycle.
- Tap a Flow chart series (line/area) → highlight that series, show tooltip popover.
- Tap a Symptom row → (currently no-op; reserved for future drill-down); tap `info.circle` on
  section header for the explainer sheet.
- Pull-to-refresh: recomputes all charts from the latest CoreData state. `.success` haptic on
  completion.
- `lock.shield` nav button → Privacy Center.

---

## Navigation

- **In:** Insights tab (4th tab, `chart.xyaxis.line` icon); from Home "Insight nudge" card.
- **Out:** Cycle Detail (push, back to Insights), Log sheet (modal from empty-state CTA), Privacy
  Center (nav button), other tabs.

---

## Accessibility

### VoiceOver / Charts
Every chart is backed by `.accessibilityChartDescriptor` implementing `AXChartDescriptorRepresentable`.
Descriptors include:
- **Cycle Length chart:** `AXChartDescriptor` with title "Cycle lengths over last N cycles," X-axis
  labeled "Cycle number," Y-axis "Days." Each `AXDataSeriesDescriptor` entry: "Cycle 3, 28 days."
  Average rule: "Average 27.3 days."
- **Flow Intensity chart:** title "Flow intensity by cycle day over last N cycles." Each series
  named "Cycle N." Data points: "Day 1, Heavy; Day 2, Medium; …"
- **Symptom heat strip:** each row's `HStack` exposes `.accessibilityElement(children: .combine)`
  with a label: "Cramps — logged in 4 of 6 cycles." The cell strip is `.accessibilityHidden(true)`;
  meaning is in the row label only.
- **Mood chart:** title "Mood frequency by cycle phase over last N cycles." Each bar group labeled
  with phase name and mood counts: "Period phase: Irritable 5 times, Fatigued 4 times."
- Enable Audio Graph (system `AXAudioGraph`) for the Flow Intensity and Cycle Length charts.

### Dynamic Type
- At AX1–AX3: chart labels (`caption1`) scale; the axis may reduce tick density automatically.
- At AX4–AX5: chart axis labels switch to `footnote` minimum size and reduce tick count to avoid
  overlap. Symptom row leading labels (fixed 130pt) grow and allow wrapping to 2 lines; the heat
  strip maintains its `xs` cell width (scrollable if needed). Section headers (`title2`) wrap.
- Charts themselves do not shrink below their intrinsic 180pt minimum height regardless of text
  size, to keep them readable.
- Bottom-sheet tooltips grow with text; popover width auto-adjusts.

### Color independence
All charts carry numeric labels or textual annotations. Phase colors in the Mood chart carry both
a colored swatch and the phase label beneath. Symptom heat cells carry numeric count labels.
No chart communicates meaning through hue alone.

### Touch targets
- Segmented control segments: ≥44pt height. Bars in Cycle Length chart: minimum 20pt wide with an
  invisible 44pt tap zone overlay (expanded with `.contentShape(Rectangle())`). Symptom rows ≥44pt.
  `info.circle` buttons ≥44pt tap target, minimum 8pt spacing from adjacent elements.

### Contrast
All axis label text uses `textSecondary` (5.2:1 on `background`). `primary` bars on `background`:
meets 4.5:1 (large UI). Under Increase Contrast: bar fill switches to 100% opacity, wash fills
get a 1pt `separator` border.
