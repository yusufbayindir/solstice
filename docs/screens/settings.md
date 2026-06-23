# Screen Spec — Settings

Part of Solstice. References `design-system.md`. The configuration hub: cycle parameters,
notifications, Apple Health, appearance, and access to Privacy Center and About.

## Purpose

Let the user adjust how Solstice models their cycle and delivers information, without burying
important controls or exposing unnecessary complexity. Everything is local; no account state to
manage.

## Layout (top → bottom)

`NavigationStack` → `List(.insetGrouped)` on `background`. Large nav title "Settings." No trailing
nav bar buttons. Standard back swipe enabled (from pushed sub-screens).

---

### Section 1 — Cycle Setup

Section header: `subheadline` `textSecondary` "CYCLE SETUP."

Row 1 — **Average Cycle Length:**
- Leading: `arrow.triangle.2.circlepath` 22pt `primary` tile (`accentSoft` background, `radiusSm`).
- `body` "Average Cycle Length." Trailing: `callout` `textSecondary` current value (e.g. "28 days")
  + `chevron.right`.
- Tap → push to **Cycle Length Editor** (see Sub-screens below).

Row 2 — **Average Period Length:**
- Leading: `drop.fill` 22pt `period` (#C0392B / #E76A5B) tile (`periodSoft` background, `radiusSm`).
- `body` "Average Period Length." Trailing: `callout` `textSecondary` current value (e.g. "5 days")
  + `chevron.right`.
- Tap → push to **Period Length Editor**.

Row 3 — **Last Period Start Date:**
- Leading: `calendar.badge.clock` 22pt `primary` tile (`accentSoft` background).
- `body` "Last Period Start." Trailing: `callout` `textSecondary` formatted date (e.g. "Jun 1")
  + `chevron.right`.
- Tap → push to a date-picker screen: `title2` "Last Period Start," `DatePicker(.graphical)`
  tinted `primary`, future dates disabled. Save button in nav bar saves and pops.

Section footer: `footnote` `textSecondary` "Solstice refines these averages automatically as you
log more cycles. Editing them resets to manual values."

---

### Section 2 — Notifications

Section header: "NOTIFICATIONS."

Row 1 — **Period Reminder:**
- Leading: `bell` 22pt `primary` tile (`accentSoft`).
- `body` "Period Reminder." Trailing: `callout` `textSecondary` current value ("3 days before") +
  `chevron.right`. When disabled: trailing "Off."
- Tap → push to **Period Reminder Settings** (see Sub-screens).

Row 2 — **Fertile Window Reminder:**
- Leading: `leaf.fill` 22pt `fertile` (#2E8B8B / #4FB3B3) tile (`fertileSoft` background).
- `body` "Fertile Window Reminder." Trailing: current value ("Day of") or "Off" + `chevron.right`.
- Tap → push to **Fertile Window Reminder Settings**.

Row 3 — **Custom Reminders:**
- Leading: `bell.badge` 22pt `primary` tile (`accentSoft`).
- `body` "Custom Reminders." Trailing: badge count (`callout` `textSecondary` e.g. "2 active") +
  `chevron.right`.
- Tap → push to a list of custom reminder rows (each with an editable label, day-of-cycle offset,
  time-of-day picker, and a swipe-to-delete). An "Add Reminder" primary button at the bottom of
  that list.

Section footer: `footnote` `textSecondary` "Notifications are scheduled on-device. Solstice does
not send push notifications through a server." + inline `Privacy badge` (lock.fill lockTint +
"On this iPhone").

---

### Section 3 — Apple Health

Section header: "APPLE HEALTH."

Row 1 — **Health Sync Toggle:**
- Leading: `heart.text.square` 22pt `success` (#3C7D5A / #5FB585) tile (light `success` at 15%
  opacity background).
- `body` "Sync with Apple Health." Trailing: system `Toggle`, tinted `primary`.
- When toggled from OFF to ON: triggers `HKHealthStore.requestAuthorization` (system sheet);
  see States: Apple Health permission request.
- When toggled from ON to OFF: toggle disables immediately (no system prompt). A `footnote`
  confirmation appears below the row: "Health sync disabled. Existing Health data is unchanged —
  manage it in the Health app."

Row 2 — **What gets shared** (non-tappable informational row, visible always):
- No leading icon.
- `callout` `textSecondary` multiline: "When enabled, Solstice reads and writes: Menstrual Flow,
  Cycle Start, Basal Body Temperature (if logged). Solstice never reads other Health categories.
  Apple controls what other apps can access from the Health app."
- Row has no trailing affordance; it is a disclosure/info row. `rowSeparator` above it only.

Section footer: `footnote` `textSecondary` "Apple Health data is governed by Apple's Privacy
Policy. Disable sync at any time here or in the Health app → Sources."

---

### Section 4 — Appearance

Section header: "APPEARANCE."

Row 1 — **Color Scheme:**
- Leading: `circle.lefthalf.filled` 22pt `textSecondary` tile (`surfaceSecondary` background).
- `body` "Appearance." Trailing: current value ("System," "Light," or "Dark") + `chevron.right`.
- Tap → push to a simple list of three rows: "System (auto)," "Light," "Dark," each with a
  leading checkmark (`checkmark` `primary`) when selected. Selecting updates `@AppStorage` and
  applies `.preferredColorScheme`. `.selection` haptic on change.

Section footer: `footnote` `textSecondary` "Solstice respects your system setting by default."

---

### Section 5 — Privacy

Section header: "PRIVACY."

Row 1 — **Privacy Center:**
- Leading: `lock.shield` 22pt `lockTint` tile (`lockTint` at 15% opacity background — same pattern
  as nav bar affordance).
- `body` "Privacy Center" in `lockTint` color (exceptionally, this label echoes the `lockTint` to
  reinforce its distinctiveness, but it remains legible: `lockTint` on `surface` = 4.5:1).
- Trailing: `chevron.right`.
- Tap → push to Privacy Center screen.

Row 2 — **App Lock status shortcut** (non-tappable, informational):
- Leading: `faceid` or `lock.fill` 22pt `lockTint` tile.
- `body` "App Lock." Trailing: `callout` `textSecondary` "On" / "Off" (reads the same setting
  managed in Privacy Center). The trailing value is non-interactive here; tapping the row navigates
  to Privacy Center where the toggle lives (no duplicate toggle to avoid sync issues).
- Trailing: `chevron.right` → tap = same as Row 1 (push to Privacy Center, scrolled to App Lock
  section via `ScrollViewProxy.scrollTo`).

---

### Section 6 — About

Section header: "ABOUT."

Row 1 — **Version:**
- Leading: `info.circle` 22pt `textSecondary` tile.
- `body` "Solstice." Trailing: `callout` `textSecondary` version string (e.g. "1.0 (42)").
- Non-tappable.

Row 2 — **Open-Source Licenses:**
- Leading: `doc.text` 22pt `textSecondary` tile.
- `body` "Open-Source Licenses." Trailing: `chevron.right`.
- Tap → push to a `List` of bundled license acknowledgements (rendered from a plist; each row:
  library name + license type; tapping a row shows the full license text in a `ScrollView`).

Row 3 — **Send Feedback:**
- Leading: `envelope` 22pt `primary` tile (`accentSoft`).
- `body` "Send Feedback." Trailing: `chevron.right`.
- Tap → `MFMailComposeViewController` pre-addressed to the feedback address; fallback: copies the
  address to clipboard + inline `footnote` confirmation "Address copied." If Mail is unavailable.

Row 4 — **Re-run Setup:**
- Leading: `arrow.counterclockwise` 22pt `textSecondary` tile.
- `body` "Re-run Setup" (`textSecondary` label — de-emphasized since it's rarely needed).
- Trailing: `chevron.right`.
- Tap → confirmation alert: "Re-run Setup? Your logs and history won't be changed — only your
  cycle length and period preferences will be reset." Buttons: "Re-run Setup" (default) · "Cancel."
  On confirm → presents Onboarding flow (steps 1–4 only; steps 5–6 skipped since permissions are
  already set).

Section footer: `footnote` `textSecondary` centered "Made with care. No tracking, no cloud."
`xl (24)` bottom padding above safe area.

---

## Sub-screens (pushed from Settings rows)

### Cycle Length Editor
`title2` nav title "Cycle Length." Back button auto ("Settings").

Layout:
- `title3` "Average cycle length" with `callout` `textSecondary` "From the first day of one period
  to the first day of the next." (`md` top padding below nav).
- Large centered value readout: `displayRing` (48pt rounded bold) "28" + `callout` "days"
  (`textSecondary`) beneath it.
- Native wheel `Picker` (`.wheels` style) immediately below, range 21–45. Centered, full width.
  Selected row scrolls to current value on appear. `.selection` haptic on each tick.
- `footnote` `textSecondary` centered "Typical range: 21–35 days."
- At the bottom, pinned above safe area: **Primary button** "Save" (full-width, `radiusLg`, `md`
  margins). Disabled until value differs from saved value (or always enabled — UX call: keep always
  enabled to not confuse first-time visitors).
- Save → persist value to `AppStorage`, trigger prediction recompute, `.success` haptic, pop.

### Period Length Editor
Same pattern as Cycle Length Editor. Nav title "Period Length." Range 1–10. `callout` "Typical
range: 3–7 days." Large readout + wheel Picker.

### Period Reminder Settings
Nav title "Period Reminder."

Layout (`List(.insetGrouped)`):
- **Enable toggle row:** `body` "Remind me before my period." System `Toggle` tinted `primary`.
- **Days-before picker row** (visible only when enabled): `body` "Days before." Trailing:
  tappable `callout` `textSecondary` value ("3 days") + `chevron.right` → a sheet
  (`.presentationDetents([.medium])`) with a wheel Picker of 1–7.
- **Time of day row** (visible only when enabled): `body` "Time." Trailing: `DatePicker`
  (`.compact`, time-only) tinted `primary`.
- Section footer: `footnote` "Reminder scheduled on this iPhone. Tapping it opens Solstice."

Saving is automatic (any change persists immediately). No explicit Save button. Navigation bar
standard back.

### Fertile Window Reminder Settings
Same pattern as Period Reminder Settings. Options: "Day of fertile window start," "1 day before,"
"2 days before." Time-of-day picker same.

---

## States

### Default
Full list as described. All rows populated with current values. Health sync toggle reflects current
authorization state (ON if authorized, OFF if not authorized or revoked).

### Apple Health Permission Request
When the user toggles Health sync ON:
1. The toggle shows an inline `ProgressView` (replacing the toggle control briefly, 16pt, `primary`)
   while `HKHealthStore.requestAuthorization` is called.
2. The system Health authorization sheet presents (full-screen modal from iOS — Solstice has no
   control over this UI).
3. On authorization granted: toggle reverts to showing ON. Footer row "What gets shared" is still
   visible. `.success` haptic.
4. On authorization denied: toggle reverts to OFF. An inline `warning` `footnote` appears below
   the toggle row: "Health access wasn't granted. You can change this in iPhone Settings → Health →
   Solstice." The footnote is dismissible (small `xmark` trailing the footnote).
5. On authorization for some but not all types: toggle shows ON with a `warning` footnote listing
   which types were denied.

### Notification Permission Request
If notifications have not been authorized when the user attempts to enable a notification reminder:
1. The toggle shows an inline `ProgressView` while `UNUserNotificationCenter.requestAuthorization`
   is called.
2. On denied: toggle reverts to OFF, inline `warning` `footnote`: "Notifications are off for
   Solstice. Enable them in iPhone Settings → Notifications → Solstice."
3. On granted: toggle stays ON. `.success` haptic.

### Notification Previously Denied (system-level)
If notifications are denied at the OS level, all notification-related toggles appear greyed out
(`textTertiary`) with a non-tappable `footnote`: "Notifications are disabled in iPhone Settings."
and a tertiary `textSecondary` link "Open Settings" (opens `UIApplication.openSettingsURLString`).

### Health Previously Revoked (detected on screen appear)
If Health authorization was previously granted but the user revoked it in the Health app, on screen
appear Solstice detects the changed `HKAuthorizationStatus`. The Health sync toggle shows OFF and
an inline `callout` `warning` row appears below: `exclamationmark.triangle` `warning` + "Health
access was removed. Re-enable the toggle to restore sync." Non-blocking, dismissible.

---

## Key Interactions

- All `List` rows with a `chevron.right` are tappable (full-row tap zone, ≥44pt).
- Cycle/period length editors: wheel Picker scroll → immediate large readout update, `.selection`
  haptic per tick. Save → pop with `.success` haptic.
- Health toggle ON → immediate system sheet. No confirmation step from Solstice (iOS system sheet
  is the confirmation).
- Appearance picker: immediate visual change on selection; no confirmation needed.
- "Re-run Setup" → system `Alert` confirmation before any action.
- "Send Feedback" → `MFMailComposeViewController` or clipboard fallback.
- Version row: 5 rapid taps (hidden easter-egg pattern) optionally enables developer debug mode
  (future; no visual change until feature exists).

---

## Navigation

- **In:** Settings tab (4th tab, `gearshape` icon); deep link from onboarding success screen "You
  can always change these in Settings."
- **Out:** Privacy Center (push from Privacy row), sub-screens (push), Onboarding (re-run setup),
  Health app / iPhone Settings (external; opens system app). Back swipe returns to the calling
  screen.

---

## Accessibility

### VoiceOver
- Nav title "Settings" is a header.
- Section headers are headers (`.accessibilityAddTraits(.isHeader)` or standard `List` section
  title treatment, which iOS already marks as headers).
- Each row combines icon, label, and trailing value: "Average Cycle Length, 28 days, button." The
  `chevron.right` is `.accessibilityHidden(true)`.
- Toggle rows: label + "toggle" + value "on" / "off." Hint: purpose of the setting.
- Health sync toggle: hint "Requires iPhone Settings permission. Will show a system authorization
  sheet."
- "What gets shared" informational row: read as a block of body text, not a button — no action
  trait.
- "Send Feedback" row: label "Send Feedback, button." Hint: "Opens Mail."
- "Re-run Setup" row: label "Re-run Setup, button." Hint: "Resets cycle parameters — not your logs."
- Version row: label "Solstice, version 1.0 build 42." No button trait (non-interactive).

### Dynamic Type
- Section headers scale with `.subheadline`. All row labels scale with `.body`; trailing values
  with `.callout`. Rows expand vertically to contain wrapped text at AX4–AX5.
- Sub-screen large value readout (`displayRing`) scales with `.largeTitle`; wheel Picker row height
  also grows at larger sizes.
- Notification sub-screen: the DatePicker (`.compact`) remains compact but the surrounding row
  height expands. At AX5, if the compact picker label would overlap other text, the time row grows
  to its expanded height.
- Informational multi-line rows (Health "What gets shared") allow free text wrapping.

### Touch Targets
All rows ≥44pt height. Toggle controls ≥44pt via native `Toggle`. Wheel Picker rows ≥44pt. Save
button in sub-screens ≥50pt (Primary button spec). Section footer links: invisible
`.contentShape(Rectangle())` padding to 44pt. `xmark` dismiss buttons on footnotes: 44pt target
centered on the glyph.

### Contrast
`lockTint` on `surface`: 4.5:1. `primary` labels on `surface`: 4.6:1 (semibold). `textSecondary`
on `background`: 5.2:1. `warning` on `surface` (inline footnotes): `warning` (#B26A1C) on
`#FFFFFF` = 4.5:1 (AA). All destructive and informational labels meet AA. Under Increase
Contrast: tile icon backgrounds get a 1pt border; section separators full opacity.
