# Screen Spec — Home / Dashboard

Part of Solstice. References `design-system.md`. The default tab and the app's emotional center:
glance, understand where you are in your cycle, and log in one tap.

## Purpose

Answer instantly: "What day of my cycle am I on, what phase, and when's my next period?" — then
make logging today frictionless. Reinforce the privacy promise quietly.

## Layout (top → bottom)

`NavigationStack` → `ScrollView` over `background`. Large nav title "Today" (or the weekday/date,
e.g. "Tuesday, June 23"). Top-trailing nav bar: `lock.shield` button (lockTint) → Privacy Center.

1. **Cycle ring card** (hero) — a `surface` card, `radiusXl`, `elevation1`, containing the
   **cycle ring** component (see design-system §7.6) centered with its legend below. Center
   readout shows CYCLE DAY / big number / phase headline. Tapping the ring → Calendar (current
   month) for detail.

2. **Prediction summary card** — a `surface` card with up to three glance rows:
   - `drop.fill` (period) "Next period" — "in 12 days · Jul 5" (predicted → `textSecondary`).
   - `leaf.fill` (fertile) "Fertile window" — "Jun 28 – Jul 3" or "Now" when active.
   - `sparkle` (ovulation) "Ovulation" — "Jul 1 (estimated)."
   Each row: leading phase icon tile, `body` label, trailing `headline` value. A trailing
   `info.circle` opens an explainer sheet: "How Solstice predicts this" (transparent model: rolling
   average of your N logged cycles ± variance; all on-device).

3. **Today / quick-log strip** — `title3` "Today" then a horizontal row of quick-log chips:
   - "Log period" (`drop.fill`) — toggles period start/stop; reflects current logged state.
   - "Flow" · "Symptoms" · "Mood" chips → open the Log sheet pre-focused on that section.
   If today already has entries, show them as filled summary chips (e.g. "Medium flow," "Cramps")
   that tap to edit.

4. **Insight nudge (optional)** — a single calm `surfaceSecondary` card when a fresh insight
   exists: e.g. "You usually feel cramps on days 1–2." → Insights tab. Dismissible. Hidden if none.

5. **Privacy footer** — the **Privacy badge** component centered (`lock.fill` + "On this iPhone").

**Floating FAB:** "Log" capsule (`plus`), bottom-trailing, `elevation2` — opens the Log sheet.

## States

- **Loading (first frame / re-compute):** skeleton — ring drawn as a plain `separator` outline,
  gray placeholder bars for prediction rows. Resolves near-instantly (local compute); skeleton only
  if >~150ms.
- **Empty — no cycles logged yet** (fresh onboarding with only the setup estimate): ring shows the
  *estimated* cycle from setup with a dashed predicted period arc and a `footnote` "Estimate —
  improves as you log." Prediction rows show estimates labeled "(estimate)." Quick-log strip
  prominent. A one-line coachmark: "Log your period to sharpen predictions."
- **Empty — truly no data & estimate impossible** (edge: user cleared the last-period date): ring
  collapses to the empty template inside the card — `drop` symbol, "Start your first log," CTA
  "Log period."
- **Populated (normal):** full ring + predictions + today summary as above.
- **Period currently active:** ring center reads "Period — Day 2," center text in `period` color;
  quick-log shows "End period" affordance.
- **Low-confidence prediction:** predicted arcs dashed, prediction values suffixed "(estimate)",
  footnote present.
- **Error:** rare. If prediction compute fails, show error template inside the ring card ("Couldn't
  calculate your cycle," "Try again") — other cards still render. Health-sync failure shows a small
  non-blocking `footnote` warning under the relevant row.

## Key interactions

- Tap FAB or any quick-log chip → Log sheet (`.presentationDetents([.medium, .large])`).
- Tap ring → Calendar tab, current month.
- Tap a prediction row's `info.circle` → explainer sheet.
- Pull-to-refresh recomputes predictions (mostly cosmetic; local). `.success` haptic on completion.
- Tap `lock.shield` → Privacy Center.
- Logging from Home updates the ring with the arc animation (§6) on dismiss.

## Navigation in / out

- **In:** app launch (after lock + onboarding), Home tab, or ring-tap return from Calendar.
- **Out:** Log sheet (modal), Calendar (ring tap / prediction tap), Insights (nudge), Privacy
  Center (`lock.shield`), Settings (tab).

## Accessibility

- Nav title is a header. Ring is a single VoiceOver element with the composed summary (see §7.6);
  reading order: title → ring summary → prediction rows → today summary → privacy badge.
- Prediction rows: label + value combined, e.g. "Next period, in 12 days, July 5, predicted."
- Quick-log chips: label + state ("Log period, button" / "Medium flow logged, button, double-tap to
  edit").
- FAB: "Log, button." 56pt target. All chips ≥44pt with ≥8pt spacing.
- Dynamic Type to AX5: ring scales/center text wraps; cards stack and grow; at AX sizes the
  horizontal quick-log strip wraps to a vertical list. Contrast AA. Reduce Motion honored on ring
  animation.
