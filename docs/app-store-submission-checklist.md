# Solstice — App Store Submission Playbook (step by step)

Everything the code/assets side needs is done. Follow these steps in order.
Ready-made assets:
- Listing copy: `docs/app-store-listing.md` (English + Turkish, full) and
  `docs/app-store-localized/<lang>.md` (29 more languages: name, subtitle, keywords, promo, description).
- Screenshots: `docs/app-store-screenshots/01–05` (1320×2868, 6.9" — the size App Store requires).
- Hosted pages (already live):
  - Privacy: https://yusufbayindir.github.io/solstice/privacy.html
  - Terms: https://yusufbayindir.github.io/solstice/terms.html
  - Support: https://yusufbayindir.github.io/solstice/support.html

---

## Step 1 — Apple Developer Program
Enroll at https://developer.apple.com/programs/ ($99/year). Skip if you already have it (your other app suggests you might).

## Step 2 — Paid Apps agreement (money cannot flow without this)
App Store Connect → **Business** (Agreements, Tax, and Banking) → accept the **Paid Applications** agreement, add your **bank account (IBAN)** and **tax forms** (W-8BEN for Turkey).

## Step 3 — Register the App ID
developer.apple.com → Certificates, IDs & Profiles → Identifiers → add `app.solstice.ios` with the **HealthKit** capability enabled.

## Step 4 — Signing in Xcode
Open `Solstice.xcodeproj` → target Solstice → Signing & Capabilities → check **Automatically manage signing** and pick your **Team**. (Or set `DEVELOPMENT_TEAM` in `project.yml` to your 10-char Team ID and run `xcodegen generate`.)

## Step 5 — Create the app record
App Store Connect → **My Apps → + → New App**:
- Platform iOS, Name **Solstice** (or "Solstice: Cycle Tracker"), Primary language English (U.S.), Bundle ID `app.solstice.ios`, SKU `solstice-ios`.
- Under **App Information**:
  - Privacy Policy URL → `https://yusufbayindir.github.io/solstice/privacy.html`
  - Category: Health & Fitness.

## Step 6 — Create the 3 in-app purchases (IDs must match EXACTLY)
App Store Connect → your app → **Monetization → Subscriptions**:
- Create a **Subscription Group** named `Solstice Plus`, then add:
  - `app.solstice.ios.plus.monthly` — $4.99 / month
  - `app.solstice.ios.plus.annual` — $29.99 / year, add an **Introductory Offer → Free → 1 week**
- **Monetization → In-App Purchases** → add Non-Consumable:
  - `app.solstice.ios.plus.lifetime` — $79.99
- For each: add a localized display name, description, and a **review screenshot** (use `docs/app-store-screenshots/05-paywall.png`).

## Step 7 — Privacy "nutrition label"
App Store Connect → your app → **App Privacy** → answer the questionnaire → **Data Not Collected** (no account, no server, no analytics). This is your strongest selling point.

## Step 8 — Listing text + screenshots
In the app version page:
- Paste **Name / Subtitle / Promotional Text / Keywords / Description** from `docs/app-store-listing.md` (English) and add Turkish + any other locales from `docs/app-store-localized/`.
- Support URL → `https://yusufbayindir.github.io/solstice/support.html`
- Upload the 5 screenshots from `docs/app-store-screenshots/` to the **6.9-inch** display slot.

## Step 9 — Build & upload
Xcode → device target **Any iOS Device (arm64)** → **Product → Archive** → **Distribute App → App Store Connect → Upload**. Wait for it to finish processing (a few minutes), then select that build on the version page.

## Step 10 — Attach IAPs and submit
On the version page, in the **In-App Purchases** section, **add all 3 products to this version** (first submission requires the IAPs to be reviewed *with* the binary). Then **Add for Review → Submit**.

---

## The 3 mistakes that cause first-submission rejection (all avoided here)
1. Submitting IAPs separately from the binary → **attach them to the version (Step 10).**
2. Paid Apps agreement not active → products stay "Missing Metadata" (**Step 2**).
3. Dead privacy/terms links → **ours are live (Steps 5 & in-app).**

## Notes
- The Widget is not a shipping target in 1.0 (loose file) — fine, it just won't appear. Add a Widget Extension + `group.app.solstice.ios` app group later if you want it.
- After approval, you can change **Promotional Text** anytime without a new build.
