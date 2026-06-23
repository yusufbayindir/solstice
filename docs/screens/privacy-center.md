# Screen Spec — Privacy Center

Part of Solstice. References `design-system.md`. The trust headquarters: a dedicated screen that
makes privacy tangible, auditable, and controllable. One tap from anywhere in the app.

## Purpose

Give the user a single, honest view of exactly what data exists, where it lives, and what can leave
the device — then let them act on it (lock the app, export, or delete everything). Privacy is not
a policy paragraph buried in settings; it is a visible, first-class feature.

## Layout (top → bottom)

`NavigationStack` push (from Home nav button, Settings row, or any `lock.shield` affordance) →
`List(.insetGrouped)` style on `background` canvas. Large nav title "Privacy." No tab bar visible
(standard stack presentation).

Nav bar: standard back button (leading). Top-trailing: none (no secondary actions at this level —
every action is in the list body where the user can read context first).

---

### Hero banner

A `surface` card, `radiusLg (16)`, `md (16)` horizontal margins, `md` top margin below the nav
title. Inner padding `md (16)`.

Layout inside the card (top → bottom):
- `lock.shield` SF Symbol, 32pt, `lockTint` (#3E6B8B light / #6FA2C4 dark), `.hierarchical`
  rendering.
- `title2` "Your data stays here" (`textPrimary`).
- `body` `textSecondary` "Solstice stores everything on this iPhone using encrypted local storage.
  Nothing is sent to servers, no account is required, and no third-party analytics run in this app."
- `Privacy badge` component (`lock.fill` 12pt `lockTint` + `footnote` `textSecondary` "On this
  iPhone") at the bottom of the card, left-aligned.

---

### Section A — What stays on this iPhone

Section header: `subheadline` `textSecondary` "WHAT STAYS ON THIS IPHONE" (all-caps, standard
`List` grouped section title style).

A checklist of data types. Each row uses design-system §7.3 list row style:
- Leading: `checkmark.circle.fill` SF Symbol, 22pt, `lockTint`, inside a 28pt `lockTint`-tinted
  `accentSoft`-equivalent tile (`#F3E2D8` / `#3A2A20`). Actually use a specific lockTint-tinted
  tile: fill `lockTint` at 15% opacity (`#3E6B8B` at 0.15).
- `body` title + `footnote` `textSecondary` subtitle.

Rows (in order):
1. `drop.fill` tile → "Period & flow logs" · "Every date, flow level, and note you've entered."
2. `bolt.heart` tile → "Symptoms" · "All symptom tags and custom symptoms."
3. `face.smiling` tile → "Mood entries" · "All mood tags, any cycle."
4. `chart.xyaxis.line` tile → "Cycle history" · "Lengths, dates, and predictions."
5. `gearshape` tile → "Your settings" · "Cycle length preferences, notification settings."

(Use the data-type SF Symbols listed above, all `lockTint` colored, to keep this section visually
unified and distinct from the warm-accent brand.)

Trailing on every row: `checkmark` 16pt `lockTint` — confirming the item is stored locally.
No `chevron`; these rows are informational, not tappable.

---

### Section B — What leaves this iPhone

Section header: "WHAT LEAVES THIS IPHONE."

One row:
- Leading: `xmark.circle.fill` 22pt `success` (#3C7D5A) tile — a positive "nothing" rather than
  a warning.
- `body` "Nothing — by default" (textPrimary).
- `footnote` subtitle: "No data is sent anywhere automatically. The only ways data leaves this
  iPhone are: (1) if you choose to export it below, or (2) if you enable Apple Health sync in
  Settings and the Health app shares it per your Health privacy settings."

One informational sub-row (indented `callout` `textSecondary`, no icon, no tap):
"Apple Health data is governed by Apple's privacy policy, not Solstice's. Disable Health sync in
Settings → Apple Health at any time."

No `chevron`. Non-tappable.

---

### Section C — App Lock

Section header: "APP LOCK."

Row 1 — **Face ID / Touch ID toggle:**
- Leading icon tile: `faceid` or `touchid` (auto-detect via `LAContext.biometryType`; fallback
  `lock.fill` if neither enrolled) 22pt `lockTint`.
- `body` title: "Lock with Face ID" (or "Touch ID" / "Device Passcode" as appropriate).
- `footnote` subtitle (visible below the toggle row when lock is OFF): "Require biometrics to open
  Solstice. Your data stays hidden even if someone has your phone."
- Trailing: system `Toggle`, tinted `lockTint`.
- When toggled ON: `LAContext.evaluatePolicy` is invoked immediately to verify biometrics before
  enabling (user must authenticate once to confirm they can unlock). On success, toggle stays ON,
  `footnote` changes to "Face ID is on. Solstice will lock when you leave the app." On failure:
  toggle reverts to OFF, an inline `warning` `footnote` appears: "Face ID couldn't be verified —
  lock not enabled." (See States: app-lock-enabled.)

Row 2 — **Auto-lock timing** (visible only when App Lock is enabled — conditionally inserted row,
not a separate section):
- Leading: `timer` 22pt `lockTint` tile.
- `body` "Lock after" · trailing: tappable `callout` `textSecondary` current value (e.g.
  "Immediately") + `chevron.right`.
- Tapping opens a sheet (`.presentationDetents([.medium])`) with a simple `Picker` (wheel or
  list): "Immediately," "1 minute," "5 minutes." Default: Immediately. `.selection` haptic on change.

---

### Section D — Export Your Data

Section header: "EXPORT."

Row 1 — **Export as CSV:**
- Leading: `tablecells` 22pt `primary` (#C2613D / #E08A63) tile.
- `body` "Export CSV" · `footnote` "A spreadsheet of every logged day, all symptoms, flow, and
  mood entries."
- Trailing: `square.and.arrow.up` 20pt `primary`.
- Full-width secondary button appearance for this row when in a non-List context; here rendered as
  a standard tappable row with the trailing icon acting as the affordance. Row tap → initiates
  export (see States: export-in-progress).

Row 2 — **Export as PDF:**
- Leading: `doc.richtext` 22pt `primary` tile.
- `body` "Export PDF" · `footnote` "A formatted summary of your cycle history — readable, shareable."
- Trailing: `square.and.arrow.up` 20pt `primary`.
- Row tap → initiates export.

Both exports present the system share sheet (`UIActivityViewController`) on completion with the
file attached. The share sheet is standard iOS — Solstice does not control where the file goes
after the user acts on it. An inline `footnote` below both rows (non-tappable, `textSecondary`):
"Once exported, a file on your device or in another app is outside Solstice's control."

Row 3 — **Privacy badge echo:**
Not a row — below the Export section, centered `Privacy badge` ("On this iPhone") to remind the
user that the source data stays local; exporting is a user-initiated exception.

---

### Section E — Delete All Data

Section header: "DANGER ZONE." (Standard grouped section label; no red color on the header itself —
the destructive style is on the row, not the header, to avoid over-alarming on scroll.)

Row 1:
- Leading: `trash` 22pt `destructive` (#C0392B / #E76A5B) — no tile background so this row
  reads as serious and distinct from the blue-tinted lock rows above.
- `body` "Delete All Data" in `destructive` color.
- `footnote` `textSecondary`: "Permanently removes all logs, settings, and cycle history from this
  iPhone. This cannot be undone."
- No trailing chevron — tapping opens a confirmation dialog (see States: delete-confirm).

---

### Footer

Below all sections, `footnote` `textSecondary` centered:
"Solstice v1.0 · Privacy policy · Open source" (the latter two are tappable tertiary links using
`primary` label color). Privacy policy is an on-device static HTML document (no external link
required, though an external URL can be provided as fallback for users who want the canonical
source). `xl (24)` bottom padding above safe area.

---

## States

### Default
Full layout as described. App Lock toggle reflects current setting (OFF or ON). Export rows are
enabled. Delete row is enabled.

### App-Lock-Enabled
App Lock toggle is ON (`lockTint` tint). The auto-lock timing row is inserted immediately below the
toggle row with a `spring(response: 0.35, dampingFraction: 0.86)` row insertion animation. The
toggle `footnote` reads "Face ID is on. Solstice will lock when you leave the app." Reduce Motion:
instant row appearance, no spring.

### Export In-Progress
When either Export row is tapped:
1. The tapped row's trailing icon is replaced by a `ProgressView` (system spinner, `primary` tint,
   16pt). The row title adds a `footnote` "Preparing…" below it. Both export rows are disabled
   (non-interactive) during preparation.
2. The rest of the screen remains scrollable and interactive.
3. On completion: the `ProgressView` reverts to the `square.and.arrow.up` icon, the share sheet
   presents, and a `.success` haptic fires.

### Export Complete (share sheet dismissed)
No persistent change to the screen. The export rows return to default. No banner ("Your data is in
the share sheet" is the affordance). If the user cancels the share sheet without saving anywhere,
nothing changes on this screen — no error state (the user just chose not to share).

### Export Error
If file generation fails:
- An inline `warning` `footnote` row appears below the failed export row (row-level, not full
  screen): `exclamationmark.triangle` 14pt `warning` + "Couldn't create the export file. Try again."
- The export row is re-enabled immediately.

### Delete-Confirm Dialog
Tapping the Delete All Data row presents a system `Alert` (not a custom sheet, to match iOS
destructive-action conventions and ensure VoiceOver announces the warning clearly):

- Title: "Delete All Data?"
- Message: "This permanently removes all your cycle logs, symptoms, mood entries, and settings from
  this iPhone. It cannot be undone."
- Buttons:
  - "Delete Everything" — `destructive` role. Triggers deletion.
  - "Cancel" — `cancel` role (dismisses dialog; no changes).

A `.warning` haptic fires when the alert appears, before the user confirms.

### Deleted
After confirmation and successful deletion:
1. A brief full-screen success-style overlay (not a separate screen — a `ZStack` overlay on the
   current view): centered `checkmark.circle` 48pt `success`, `title3` "All data deleted,"
   `callout` `textSecondary` "Solstice is now a clean slate." Duration ~1.5s, then auto-dismiss.
2. The app navigates to Onboarding (the `TabView` root is replaced with the onboarding flow, same
   as first launch). All sections of Privacy Center are no longer populated.
3. `.success` haptic on deletion completion.
4. Under Reduce Motion: skip the checkmark overlay animation; go directly to Onboarding after a
   0.2s opacity fade.

---

## Key Interactions

- `lock.shield` row toggle → immediate biometric prompt → enables/disables lock with feedback.
- Auto-lock sheet picker → `.selection` haptic on each wheel tick.
- Export CSV / PDF row tap → file preparation → system share sheet. No intermediate confirmation
  dialog for export (it is not destructive — the user retains the data on device).
- Delete All Data row tap → system `Alert` with `.warning` haptic before the user confirms.
- Privacy policy / open-source footer links → open in-app `SFSafariViewController` (no raw Safari
  navigation that leaks context; if offline, show the bundled static document).

---

## Navigation

- **In:** `lock.shield` button on Home dashboard (nav bar, top-trailing); Settings → Privacy Center
  row; Onboarding Step 1 tertiary link "How Solstice protects you" (sheet, read-only — Delete and
  Export are disabled in onboarding context).
- **One-tap rule:** From any screen where the nav bar is visible (Home, Calendar, Insights), the
  `lock.shield` affordance is always present, making Privacy Center reachable in one tap.
- **Out:** back button → the screen that presented this (Home, Settings, etc.); Delete All → forced
  to Onboarding; share sheet is modal over Privacy Center.

---

## Accessibility

### VoiceOver
- Nav title "Privacy" is read as a header.
- Hero banner is a single focusable element with combined label: "Your data stays here. Solstice
  stores everything on this iPhone. Nothing is sent to servers. On this iPhone."
- Section A rows: each is read as "Period and flow logs, stored on this iPhone, checkmark." The
  `checkmark.circle.fill` leading icon and trailing `checkmark` are `.accessibilityHidden(true)` —
  the word "stored on this iPhone" in the synthesized label carries the meaning.
- Section B row: "Nothing leaves by default. No data is sent automatically." The `xmark.circle`
  icon is hidden; the subtitle is appended to the combined label.
- App Lock toggle: label "Lock with Face ID, toggle" + value "off" / "on." Hint: "Requires Face ID
  to open Solstice." After enabling: value "on," hint "Face ID is active. Double-tap to disable."
- Delete row: label "Delete All Data, button." Hint (VoiceOver hint, not visible): "Warning:
  permanently removes all data from this iPhone. Cannot be undone." Use
  `.accessibilityHint("Warning: permanently removes all data. This action cannot be undone.")`.
  System Alert additionally announces its own destructive-role button with "Delete Everything,
  destructive button."
- Export rows: label "Export CSV, button" / "Export PDF, button." Hint: "Generates a file and
  opens the share sheet." During progress: value "Preparing, loading" — use `.accessibilityValue`.
- Footer links: "Privacy policy, link" / "Open source, link." Each ≥44pt tap zone.

### Destructive actions
Every destructive affordance (Delete All) has VoiceOver warning in both label and hint. The system
Alert's destructive-role button is announced by iOS as such. The `.warning` haptic cues non-visual
users that a high-stakes action is about to be confirmed.

### Dynamic Type
- Section headers scale with `.subheadline`. Row titles scale with `.body`; subtitles with
  `.footnote`, allowed to wrap to 2 lines before the row height expands (design-system §7.3 row
  growth rule). Hero banner `body` text wraps freely.
- At AX4–AX5: icon tiles are fixed 28pt (they are decorative; their meaning is in the text label),
  so they do not scale. Row heights expand to contain wrapped text. Section separators remain
  visible. All text stays `textPrimary`/`textSecondary` (no truncation).
- Toggle control is native `Toggle`; it scales with the system control size. Auto-lock timing row
  trailing value also scales with `.callout`.

### Contrast
`lockTint` (#3E6B8B) on `surface` (#FFFFFF): 4.5:1 (AA). `destructive` (#C0392B) on `surface`:
4.9:1 (AA). All body text `textPrimary` on `surface` exceeds 13:1. Under Increase Contrast:
the `accentSoft`-tinted tile backgrounds get a 1pt `lockTint`-colored border; the hero banner card
gets a 1pt `separator` border; export/delete row dividers are enforced at full `separator` opacity.

### Touch targets
All row heights ≥44pt. Toggle has a 44pt height. The Delete row is a full-width tap zone (the
entire row, not just the label). Footer links have invisible `.contentShape(Rectangle())` expansions
to 44pt. App Lock timing row trailing tap zone ≥44pt.
