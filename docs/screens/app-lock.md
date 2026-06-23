# Screen Spec — App Lock

Part of Solstice. References `design-system.md`. The gate screen shown on launch (and on foreground
return) when App Lock is enabled — the final, visible expression of the privacy promise.

## Purpose

Prevent unauthorized access to cycle data by requiring biometric or passcode authentication before
the TabView is shown. The screen should feel secure and calm — not alarming. The privacy message
is reinforced ("Your data stays on this device") so that even the lock screen carries the brand's
trust language.

## Layout

A full-screen, non-scrollable `ZStack` over `background`. No `NavigationStack`, no tab bar.

The content is centered vertically with optical adjustment (center of the content stack sits at
~45% of the screen height, slightly above true center, to account for the unlock button's weight
pulling the eye down).

### Layer 1 — Blur shield (content protection)

A `.regularMaterial` `Rectangle` fills the entire screen (`ignoresSafeArea()`). This sits between
the invisible TabView (which is rendered but opacity 0 behind) and the lock screen content, so no
cycle data is visible through the lock screen — not even a blur silhouette. On devices with Reduce
Transparency: replace `.regularMaterial` with a solid `background` fill (#FAF7F3 light /
#181512 dark).

### Layer 2 — Lock screen content

A `VStack(spacing: 0)` centered in the safe area, with explicit `Spacer()` elements to achieve the
visual balance described above. Horizontal padding: `lg (20)`.

From top to bottom within the centered content block:

1. **Wordmark / glyph** — the Solstice app icon glyph (custom asset, `SolsticeGlyph`), 64pt ×
   64pt, rendered with a `lockTint` (#3E6B8B light / #6FA2C4 dark) tint (`.colorMultiply` applied
   to the glyph asset or a styled `Image` with `renderingMode(.template)` if the glyph is a simple
   mark). `xl (24)` bottom spacing.

2. **Wordmark text** — `title1` "Solstice" (`textPrimary`, 28pt Bold, default SF Pro). `sm (12)`
   bottom spacing.

3. **Tagline** — `callout` `textSecondary` "Your cycle. Your phone. Your privacy." `xxxl (48)`
   bottom spacing.

4. **Lock status label** — `subheadline` `textSecondary` "Solstice is locked." `sm (12)` bottom
   spacing.

5. **Unlock button** — Full-width Primary button (design-system §7.1):
   - Fill: `primary` (#C2613D light / #E08A63 dark). Label: white.
   - Leading SF Symbol in button label: `faceid` (or `touchid`, or `lock.fill` if passcode-only —
     dynamically set at render time via `LAContext().biometryType`).
   - Label text (`headline` semibold): "Unlock with Face ID" / "Unlock with Touch ID" /
     "Enter Passcode" as appropriate.
   - Height: 50pt. `radiusLg (16)`. Full width minus `lg (20)` side margins.
   - `xl (24)` bottom spacing.

6. **Privacy reassurance line** — `Privacy badge` component: `lock.fill` 12pt `lockTint` +
   `footnote` `textSecondary` "Your data stays on this device." Centered.

No other elements. No close button. No "skip." No branding links. The screen exists solely to
authenticate and then disappear.

---

## States

### Idle / Locked

The screen as described above. The unlock button is enabled and prominent. No authentication is
in progress.

This state is shown briefly on every foreground return before `LAContext.evaluatePolicy` is
triggered on appear. The transition into this state (from the background) is instant — no fade-in
animation, no spring — to prevent any flash of data before the blur is in place.

### Authenticating

Triggered automatically on screen appear (after a ~0.3s delay to allow the screen to render fully
before the system Face ID animation plays). Also triggered manually when the user taps the unlock
button.

Visual changes during authentication:
- The unlock button's label is hidden; an inline `ProgressView` (white, `ProgressView(value: nil)`
  system style, 20pt) replaces it inside the button. Button width is fixed (no width jump).
- The button is non-interactive during authentication (to prevent double-prompt).
- The wordmark, tagline, lock label, and privacy line remain visible and unchanged.
- The Face ID / Touch ID system overlay (the ring animation, glow, or Touch ID pulse) presents
  above this screen — Solstice has no control over that UI; it is standard iOS behavior.

Under Reduce Motion: the button ProgressView is shown as a static `lock.open` symbol (20pt,
white) rather than an animated spinner, while biometric UI plays.

### Auth Failed (retry)

Shown after a failed Face ID / Touch ID attempt (wrong face, covered sensor, etc.) or after the
user cancels the biometric prompt.

Visual changes:
- The unlock button reverts from loading to its normal state (icon + label).
- A `callout` error label appears between the lock status label and the unlock button:
  `exclamationmark.circle` 16pt `warning` (#B26A1C / #D08A3A) + `callout` "Couldn't verify —
  try again." (`textPrimary`). This label appears with a `spring(response: 0.35,
  dampingFraction: 0.86)` upward slide from opacity 0 (or instant fade under Reduce Motion).
- If biometric failed but passcode is available (iOS default fallback behavior): after 2 biometric
  failures iOS presents the passcode entry sheet automatically. Solstice does not need to handle
  this; it results from `LAPolicy.deviceOwnerAuthentication` (which covers both biometric and
  passcode fallback) rather than `biometricOnly`.
- A `.error` (via `UINotificationFeedbackGenerator`) haptic fires on failure. One time only; do not
  repeat on every retry attempt (only on the transition to the failed state).

After the error label appears, the unlock button is immediately re-enabled. The user can tap it or
wait for the system passcode sheet.

### Auth Failed — Biometrics Locked (too many attempts)

iOS locks biometrics after 5 failures. At this point `LAContext.evaluatePolicy` returns
`LAError.biometryLockout`.

Visual changes:
- The unlock button label changes to "Enter Passcode" + `lock.fill` icon.
- Error label: "Face ID is locked — use your passcode to unlock Solstice." `callout` `textPrimary`.
- Tapping the button calls `LAContext.evaluatePolicy(.deviceOwnerAuthentication)`, which presents
  the system passcode entry UI.

### Auth Success

Triggered when `LAContext.evaluatePolicy` completes with `success == true`.

Transition:
1. The lock screen content fades to opacity 0 over 0.18s (`.snappy(duration: 0.18)`).
2. The `.regularMaterial` blur fades out over 0.25s simultaneously.
3. The TabView (Home dashboard) is revealed.
4. A `.success` haptic (`UINotificationFeedbackGenerator`) fires at step 1.

Under Reduce Motion: skip the fade — the lock screen disappears instantly (opacity 1 → 0 over 0s)
and the TabView appears immediately. Haptic still fires.

### Biometrics Unavailable — Passcode Fallback

Shown when `LAContext.canEvaluatePolicy` returns false for `.deviceOwnerAuthenticationWithBiometrics`
but true for `.deviceOwnerAuthentication` (i.e., the device has a passcode but no biometrics
enrolled or available — camera covered, hardware issue, etc.).

Visual changes from default:
- Glyph: replace `faceid`/`touchid` with `lock.fill` in the wordmark area (keep the `lockTint`
  color).
- Lock status label: "Solstice is locked."
- Unlock button: `lock.fill` icon + "Enter Passcode" label.
- Privacy reassurance line: unchanged.
- Tapping the button: calls `.deviceOwnerAuthentication` → system passcode sheet.
- No biometric icon or mention of Face ID/Touch ID.

### Biometrics Unavailable — No Passcode Set (edge case)

This state should never be reachable in normal use because enabling App Lock in Privacy Center
requires a successful biometric evaluation, which implicitly requires a passcode. However, if it
occurs (e.g., user removed their passcode after enabling App Lock):

- `LAContext.canEvaluatePolicy(.deviceOwnerAuthentication)` returns false.
- Replace the unlock button with a `surface` card, `radiusMd`, `md` padding:
  `exclamationmark.triangle` 24pt `warning` + `title3` "Can't unlock Solstice" + `callout`
  `textSecondary` "No passcode is set on this iPhone. Set a passcode in iPhone Settings to regain
  access." + a secondary button "Open iPhone Settings" (→ `UIApplication.openSettingsURLString`).
- The app is functionally locked; the user cannot bypass this screen without adding a passcode.
- Privacy reassurance line: unchanged.

### First-Time Enable Flow (in-context)

This is not the full-screen lock state but the moment App Lock is turned ON for the first time (in
Privacy Center). A brief transition sequence:

1. Privacy Center `LAContext.evaluatePolicy` succeeds.
2. App Lock is stored as enabled.
3. The next time the user backgrounds and foregrounds the app (or force-quits and relaunches), the
   App Lock screen appears for the first time.
4. On that first appearance: an additional `footnote` `textSecondary` sub-label appears below the
   lock status label: "You just enabled App Lock. Authenticate to continue." This is only shown once
   (persisted via `AppStorage("hasSeenFirstLock")`). Subsequent appearances show the standard layout.

### Face ID Not Enrolled

When `LAContext.biometryType == .none` (no biometrics enrolled on device) but the device has a
passcode:
- Same as "Biometrics Unavailable — Passcode Fallback." No Face ID / Touch ID UI shown.
- If App Lock was enabled on a device with biometrics and those biometrics are later un-enrolled
  in iOS Settings: same fallback behavior applies. The next successful passcode unlock re-validates
  and App Lock remains active.

---

## Key Interactions

- **Screen appear:** triggers `LAContext.evaluatePolicy` automatically after 0.3s. No need to tap
  anything on a clean Face ID read.
- **Tap unlock button:** manually re-triggers `LAContext.evaluatePolicy` (useful when auto-trigger
  was dismissed or cancelled).
- **System Face ID / Touch ID overlay:** standard iOS presentation; Solstice does not intercept
  it.
- **Background / foreground cycle:** every foreground return when App Lock is enabled shows this
  screen. The TabView is never briefly visible during this transition — the blur layer is applied
  before any transition begins (in `scenePhase` `.background` → `.inactive` → `.active`
  observation).
- **No dismiss / bypass gesture:** swipe-down, swipe-right, and edge gestures are all disabled
  (`interactiveDismissDisabled(true)` if presented as a sheet, or simply as a root `ZStack` that
  captures all gestures when active).
- **Open Settings (passcode fallback):** taps `UIApplication.openSettingsURLString` — leaves the
  app; returns to the lock screen on next foreground.

---

## Navigation

- **In:** every app launch when App Lock is enabled (presented as the `windowScene` root before the
  TabView is shown); every `scenePhase` `.active` foreground return when App Lock is enabled and the
  session timeout has elapsed (immediately if "Lock: Immediately").
- **Out:** successful authentication → Home (TabView, the last-active tab is restored). There is
  no "go back" from the lock screen — it is a gate, not a stack.

---

## Accessibility

### VoiceOver
The lock screen reading order (VoiceOver linearized):
1. Solstice glyph: `.accessibilityHidden(true)` (decorative; the wordmark text below names the app).
2. "Solstice" wordmark text: `.accessibilityAddTraits(.isHeader)`.
3. Tagline: read as-is (`callout` static text).
4. "Solstice is locked." (status label): `.accessibilityLiveRegion(.polite)` so state changes
   (e.g. "Couldn't verify — try again") are announced without focus hijacking.
5. Error label (when visible): `.accessibilityLiveRegion(.assertive)` — auth failure is important
   enough to interrupt.
6. Unlock button: label auto-composed from button text: "Unlock with Face ID, button." Hint:
   "Double-tap to authenticate with Face ID."
   - Passcode fallback: "Enter Passcode, button." Hint: "Double-tap to enter your iPhone passcode."
   - Loading state: button label "Authenticating, loading" — use `.accessibilityValue("loading")`
     and `.accessibilityLabel("Authenticating")`.
7. Privacy badge: "Your data stays on this device." Read as static text; `lock.fill` icon
   `.accessibilityHidden(true)`.

### Full Keyboard / Switch Control Support
- The unlock button must be reachable via Switch Control and external keyboard. Focus order: 1 →
  unlock button (only interactive element in the default state). Space / Return activates it.
- In the "No Passcode" edge case, "Open iPhone Settings" button is the focusable element.
- No other interactive elements exist on this screen (by design — there is nothing to navigate
  to except authenticate or open system settings).

### Dynamic Type
- "Solstice" title scales with `.title1` (28pt at Large, up to ~38pt at AX5). At AX3+ it may
  overlap the glyph — give `xl (24)` between glyph and wordmark text and allow natural wrap.
- Tagline (`callout`) wraps to 2 lines at large sizes.
- Unlock button (`headline` semibold) scales; button height expands beyond 50pt minimum to contain
  the label at AX5.
- Privacy badge `footnote` wraps at AX4–AX5; `lock.fill` icon remains 12pt (decorative, not
  informational).
- The entire content block may grow at AX5 such that it does not fit without scrolling — in that
  case, embed the `VStack` in a `ScrollView` with `bounceDisabled` so the content remains visible.
  The `.regularMaterial` blur layer still fills the full screen.

### Contrast
- Wordmark text `textPrimary` (#2A2521) on `background` (#FAF7F3): 13.9:1.
- Tagline and privacy badge `textSecondary` (#6B6258) on `background`: 5.2:1.
- Unlock button: white label on `primary` (#C2613D): 4.6:1 (meets AA for `headline` semibold at
  17pt+). In dark mode: white on `#E08A63` = 3.4:1 — this is acceptable for a large (17pt
  semibold) UI label with an icon, which falls under the 3:1 large-UI rule; but developers should
  verify with the iOS contrast checker tool and consider darkening the dark-mode button to
  `primaryPressed` (#C2613D) if the project's bar is higher.
- Under Increase Contrast: raise the button fill to `primaryPressed` in both modes, add a 1.5pt
  white inner border on the button, and add a 1pt `separator` border on the `.regularMaterial`
  blur area's edge if there is an adjacent surface.
- Error label `warning` (#B26A1C) on `background`: 4.5:1 AA.
- `lockTint` (#3E6B8B) on `background` (#FAF7F3): 4.5:1 AA (the glyph uses this color at 64pt —
  well above 3:1 large-UI threshold).
