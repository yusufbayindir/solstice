# Screen Spec — Log Entry (period / flow / symptoms / mood)

Part of Solstice. References `design-system.md`. The fast-logging sheet — the most-used surface.
Hard requirement: a complete log in **under 5 seconds**.

## Purpose

Capture today's (or a selected day's) cycle data with minimal taps: period start/end, flow level,
symptoms, mood, and an optional note. Everything saved locally, instantly.

## Presentation

A bottom **sheet** (`.presentationDetents([.medium, .large])`, drag indicator on), presented from
the FAB or any quick-log chip. Opens at `.medium`; expands to `.large` when the user scrolls or
taps a section needing room. Defaults to **today**; when opened from a calendar day, scoped to that
date (date shown in header, tappable to change via inline `DatePicker`).

## Layout (top → bottom)

1. **Header** — `title2` "Log" + the date as a tappable `headline` `textSecondary` subtitle
   ("Today · Jun 23"). Top-leading "Cancel," top-trailing "Save" (primary text button; `.success`
   haptic on save → dismiss). Save is always enabled (logging nothing is allowed = clears the day
   after confirm, or is simply a no-op dismiss).

2. **Period toggle (top, most prominent)** — a full-width control:
   - If no period logged for this date's cycle context: **"Log period start"** primary button
     (`drop.fill`).
   - If a period is currently open: **"Period — started Jun 21"** with an "End period today"
     secondary button.
   - Toggling on reveals the flow selector inline.

3. **Flow** — section `title3` "Flow." A horizontal row of 4 `drop` glyphs:
   none · light (`drop`) · medium (`drop.halffull`) · heavy (`drop.fill`), each a 44×44 target;
   selected = filled `period` with a label beneath. Single-select.

4. **Symptoms** — section `title3` "Symptoms." A wrapping grid of tappable **chips** (capsule,
   `surfaceSecondary` default → `accentSoft` fill + `primary` border when selected). Multi-select.
   Default set with SF Symbols:
   - Cramps `bolt.heart`, Headache `bandage`, Bloating `circle.dashed`, Tender breasts `heart`,
     Fatigue `zzz`, Acne `face.dashed`, Backache `figure.walk`, Nausea `wind`, Cravings `fork.knife`,
     Discharge `drop.triangle`, Spotting `drop`, Insomnia `moon.zzz`.
   - Trailing "＋ Add" chip → custom symptom (free text, saved to the user's set; free, never
     paywalled — unlike Clue).

5. **Mood** — section `title3` "Mood." A horizontal scroll of mood chips (single or multi per
   preference; default multi): Calm `face.smiling`, Happy `sun.max`, Sensitive `cloud`, Sad
   `cloud.rain`, Anxious `wind`, Irritable `bolt`, Energetic `sparkles`, Low `moon`.
   Selected = `accentSoft` fill.

6. **Note (optional)** — a `surfaceSecondary` text field, `radiusMd`, placeholder "Add a note
   (optional)…", expands as typed. Stays on-device like everything else.

7. **Privacy footer** — small **Privacy badge** ("On this iPhone") so the trust signal is present
   even at the point of data entry.

## States

- **Empty / new day:** nothing selected; period button reads "Log period start"; Save dismisses
  (no-op) if nothing chosen.
- **Editing existing entry:** all previously logged values pre-selected; header shows the date;
  Save updates; a tertiary "Clear this day" (destructive, with confirm) removes all entries for the
  date.
- **Period active context:** shows "End period" affordance; selecting flow is encouraged.
- **Saving:** Save button shows inline `ProgressView` very briefly (local write); then `.success`
  haptic and sheet dismiss. Effectively instant.
- **Error:** if the local write fails (very rare), error template inline at the top of the sheet
  ("Couldn't save — try again"); selections preserved, nothing lost. Health-write failure (if
  enabled) surfaces a non-blocking `footnote` "Saved on device; Health sync will retry."
- **Success:** sheet dismisses; originating screen (Home ring / Calendar cell) updates with
  animation.

## Key interactions

- Single tap toggles flow level / symptom / mood chips (`.selection` haptic).
- "Log period start" → reveals flow; "End period today" closes the period span.
- Date subtitle tap → inline `DatePicker(.compact)` to re-scope (e.g. logging yesterday).
- Cancel discards unsaved changes (confirm only if changes exist).
- Designed so the common path — open FAB → tap "Log period start" → tap a flow drop → Save — is 3
  taps / under 5 seconds.

## Navigation in / out

- **In:** Home FAB / quick-log chips, Calendar FAB, Calendar day-detail "Log/Edit," Widget deep
  link ("Log today").
- **Out:** Save or Cancel → dismiss back to originator. Custom-symptom add is an inline mini-sheet,
  not a new screen.

## Accessibility

- Sheet header title is a header; "Save"/"Cancel" clearly labeled buttons.
- Flow drops: each labeled with its level and selected state ("Medium flow, selected, button");
  expose as an adjustable/segmented group where possible. Color-blind safe (labels under glyphs).
- Symptom/mood chips: label + selected state; the wrapping grid is logically ordered for VoiceOver.
- Every chip/control ≥44×44, ≥8pt apart. Note field labeled.
- Dynamic Type to AX5: at large sizes the sheet opens at `.large`, chip rows wrap to vertical lists,
  flow drops grow; nothing truncates. Contrast AA. Reduce Motion: no chip bounce, instant select.
- The Privacy badge is read last so the trust cue is conveyed without interrupting the task.
