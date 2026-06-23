# Screen Spec — Calendar

Part of Solstice. References `design-system.md`. The historical + forecast view: see logged and
predicted days across months, and tap any day to log or edit.

## Purpose

Let the user scan their cycle over time — what they logged, what's predicted — and use a day as
the entry point for logging. The factual record that backs the prediction engine.

## Layout (top → bottom)

`NavigationStack` → `background`. Large nav title "Calendar." Top-trailing nav bar:
`lock.shield` → Privacy Center; top-leading "Today" button (jumps to current month) when scrolled
away.

1. **Weekday header row** — `caption1` `textSecondary`, localized first-weekday (S M T W T F S),
   pinned.
2. **Month grid(s)** — a vertically scrolling list of month sections (current month centered on
   open; scroll up for history, down for ~3 months of forecast). Each month: `title2` month/year
   header, then the 7-column grid of **calendar cells** (design-system §7.7). Forecast months
   render predicted (dashed) period/fertile/ovulation only.
3. **Selected-day detail sheet** — tapping a day presents a bottom sheet
   (`.presentationDetents([.medium])`):
   - Header: full date (`title3`) + cycle-day badge ("Cycle day 14").
   - Phase line: e.g. "Fertile window" with its colored glyph.
   - Logged data summary rows (flow, symptoms, mood) if present, else "Nothing logged."
   - Primary button: "Log for this day" / "Edit" → opens the Log sheet scoped to that date.
4. **Legend bar** — a pinned bottom `surface`/`.thinMaterial` strip showing the phase legend
   (● Period · ◐ Fertile · ◆ Ovulation · Today ring · dashed = predicted) so color is never the
   only cue.

**Floating FAB:** "Log" capsule (logs *today* by default), bottom-trailing above the legend bar.

## States

- **Loading:** skeleton month grid (gray rounded squares) if compute >~150ms; otherwise immediate.
- **Empty — no logs yet:** grid renders with only the *predicted/estimated* cycle (dashed) from
  setup; a `callout` banner above the grid: "Tap a day to log your period." No hard empty screen —
  the calendar is always useful.
- **Populated:** past months show solid logged days; current/future show predictions; today ringed.
- **Future beyond confident horizon:** predictions fade — periods further out drawn at reduced
  opacity with a section footnote "Further predictions are rough estimates."
- **Error:** a day-detail or save failure uses the error template inside the sheet ("Couldn't save,"
  "Try again"); the grid itself doesn't error (local data).

## Key interactions

- Tap a day → detail sheet → "Log/Edit" → Log sheet for that date.
- Long-press a day → quick action menu: "Log period start here," "Mark period end," "Add symptom."
- Scroll vertically through months (lazy-loaded). "Today" button snaps back to current month.
- Editing/logging updates affected cells immediately; predicted cells recompute (animated wash
  change, Reduce-Motion → instant).
- Tapping the today-ring vs. a past day both open the detail sheet (consistent).

## Navigation in / out

- **In:** Calendar tab, Home ring tap, Home prediction-row tap (jumps to relevant month).
- **Out:** Log sheet (modal), Privacy Center, day-detail sheet.

## Accessibility

- Grid exposed as a calendar; each cell is one VoiceOver element with a composed label: "Tuesday
  July 5, predicted period, cramps logged, double-tap to view." Decorative phase glyphs hidden;
  meaning is in the label.
- Month headers are headers; weekday row not focusable beyond its labels.
- Today cell announces "Today" trait. Selected/period/fertile/ovulation states all conveyed in text,
  not color alone (color-blind safe per §2).
- Cells are 44×44 min; at large Dynamic Type the grid keeps 7 columns but cell numbers scale and
  the detail sheet (not the grid) carries the fuller text. Legend bar text scales and wraps.
- Contrast AA; honor Increase Contrast (washes → bordered cells) and Reduce Motion (no animated
  recompute). FAB labeled "Log."
