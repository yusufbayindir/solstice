# Screen Spec — Onboarding (multi-step)

Part of Solstice. References `design-system.md`. Shown once on first launch; re-enterable later
only via Settings → "Re-run setup." No account, no email, no network calls — privacy is
established in the first 30 seconds.

## Purpose

Get the user from launch to a working prediction in under a minute, while making the privacy
promise *the first thing they feel*. Collect the minimum: last period start date, typical cycle
length, typical period length, and (optional) Face ID + Health + notifications opt-ins.

## Flow / steps

A `NavigationStack`-free, swipe-or-button paged flow (custom `TabView(.page)` with a top progress
indicator). 6 steps; steps 4–6 are skippable.

1. **Welcome / privacy promise**
2. **Last period date**
3. **Cycle length**
4. **Period length**
5. **Protect it** (Face ID lock opt-in) — optional
6. **Connect & finish** (Apple Health + notifications) — optional → Done

## Layout (top → bottom, per step)

Common chrome:
- Top: thin segmented **progress bar** (6 pips, filled `primary`, unfilled `separator`), `lg (20)`
  side margins, `md` top safe-area inset. A `Skip` text button (tertiary, `textSecondary`) top-
  trailing on optional steps 5–6 only.
- Content area: hero `largeTitle` headline, `body` `textSecondary` subcopy, then the step's input.
- Bottom: pinned **Primary button** ("Continue" / step-specific) full-width, `lg` margins, with a
  safe-area bottom inset; on optional steps a tertiary "Not now" sits below it.

### Step 1 — Welcome / privacy promise
- Solstice glyph/wordmark (centered, top third).
- `largeTitle`: "Your cycle, kept private."
- `body`: "Solstice predicts your period and fertile window right here on your iPhone. No account.
  No cloud. Your data never leaves this device unless you choose to export it."
- **Privacy badge** component (`lock.fill` lockTint + "On this iPhone").
- Primary button: "Get started." Tertiary link: "How Solstice protects you" → opens Privacy
  Center in a sheet (read-only preview).

### Step 2 — Last period date
- `title1`: "When did your last period start?"
- `body` subcopy: "Pick the first day of bleeding. An estimate is fine — you can change it later."
- `DatePicker(.graphical)` tinted `primary`, future dates disabled, default = none selected
  (button stays disabled until a date is chosen). Selected date echoed in `headline` above picker.
- Primary: "Continue."

### Step 3 — Cycle length
- `title1`: "How long is your cycle, usually?"
- `body`: "From the first day of one period to the first day of the next. Most are 21–35 days.
  Not sure? We'll use 28 and refine it as you log."
- Large centered value readout (`displayRing`, e.g. "28 days") + a wheel `Picker` (range 21–45) OR
  a `−/＋` stepper flanking the number, 44pt targets. Default highlighted = 28.
- Tertiary: "I'm not sure" → sets 28 and continues.
- Primary: "Continue."

### Step 4 — Period length
- `title1`: "How many days does your period last?"
- `body`: "Typically 3–7 days." Same large value + picker pattern, range 1–10, default 5.
- Primary: "Continue."

### Step 5 — Protect it (Face ID) — optional
- Icon: `faceid` 48pt in `lockTint`.
- `title1`: "Lock Solstice with Face ID?"
- `body`: "Require Face ID to open the app, so your cycle stays yours even if someone has your
  phone. You can change this anytime in Settings."
- Primary: "Turn on Face ID" (triggers system biometric enrollment check / `LAContext`).
  Tertiary below: "Not now."
- If biometrics unavailable on device, replace with passcode-lock copy or skip the step entirely.

### Step 6 — Connect & finish — optional
- Two grouped opt-in rows on a card:
  - `heart.text.square` "Sync with Apple Health" toggle — "Read and write cycle data. You control
    this in the Health app." (Triggers `HKHealthStore` authorization on enable.)
  - `bell` "Period reminders" toggle — "A gentle heads-up before your next period. Notifications
    are scheduled on-device."
- Privacy badge repeated.
- Primary: "Finish setup" → success state.

### Success (post-finish)
- Brief success animation: cycle ring draws in with the computed Day N (`.success` haptic, respects
  Reduce Motion → fade). `title2`: "You're all set." `callout`: "Here's your cycle." Auto-advances
  to Home after ~1.2s, or "Go to Solstice" primary button.

## States

- **Loading:** none meaningful (local). Health/biometric authorization shows the system sheet;
  while awaiting, the primary button shows inline `ProgressView`.
- **Empty / default:** date step has no preselected date (button disabled); length steps default to
  28/5 highlighted.
- **Error:**
  - Face ID enrollment fails/declined → inline `footnote` `warning`: "Face ID isn't set up on this
    iPhone. You can enable it later in Settings." Continue is unaffected.
  - Health authorization denied → `footnote` "You can connect Health later in Settings." Non-blocking.
- **Success:** see Success state above.
- **Resume:** if the app is killed mid-onboarding, restart at step 1 (no partial persistence of
  sensitive data); only persist once "Finish setup" completes.

## Key interactions

- Swipe between completed steps or use Continue; cannot swipe forward past an incomplete required
  step. Back = swipe right or a top-leading `chevron.left` button from step 2 onward.
- Changing a value updates the large readout live with `.selection` haptic.
- "Skip"/"Not now" on optional steps advances without setting that capability.

## Navigation in / out

- **In:** first launch (no persisted setup), or Settings → "Re-run setup."
- **Out:** Success → Home (root TabView). The onboarding view is dismissed and never shown again
  unless setup is re-run.

## Accessibility

- Progress bar exposes `.accessibilityValue("Step 2 of 6")`; not a focusable trap.
- Each step's headline is the first VoiceOver element and gets `.accessibilityAddTraits(.isHeader)`.
- DatePicker, pickers, steppers use native controls (already accessible); large numeric readout
  has a clear label ("Cycle length, 28 days") and adjustable trait for the stepper.
- Primary button always reachable; disabled state announces "dimmed, Continue."
- Full Dynamic Type support to AX5 — hero headlines wrap; bottom button stays pinned and visible
  (content scrolls above it if needed). Touch targets ≥44pt. All copy AA contrast.
- Honor Reduce Motion on the page transitions and success animation.
