# Solstice — Monetization Strategy

Date: 2026-06-25
Decision owner: Manager (marketing pipeline)
Inputs: pricing/packaging strategist · privacy positioning & GTM lead · market sizing & unit economics analyst

---

## The decision (TL;DR)

**Hybrid model: a real free tracker, an annual subscription as the default paid tier, and a
prominent one-time "Lifetime" unlock as the hero offer — with privacy as the reason to pay.**

Why this and not the obvious "subscription like Flo":

1. **No backend = lifetime is cheap to honor.** Predictions run on-device, there are no servers.
   The usual reason apps fear lifetime pricing (owing service forever at $0 ongoing revenue) does
   not apply — serving a lifetime user costs ~$0/year. Flo and Clue *cannot* match this because
   they must fund cloud + ML infra with recurring revenue.
2. **Privacy buyers distrust subscriptions.** The exact psychographic that picks a no-account,
   no-cloud app dislikes recurring billing and data relationships. "Buy it once, it's yours" is the
   same promise as "your data stays yours." Lifetime is on-brand, not a discount.
3. **Health tracking churns ~40–60%/yr** and a privacy app has no profiling-based re-engagement
   hooks to fight it. A lifetime tier converts skeptics who'd never start a sub and pulls cash
   forward, hedging churn.

---

## 1. Free vs Paid split

Free must be a **complete, honest tracker** — crippling basics torches trust in this category.
Premium sells **depth, fertility, convenience, and data ownership** — never safety.

**Free forever**
- Period & cycle logging (unlimited history)
- On-device next-period prediction
- Symptom + mood logging (full taxonomy)
- Calendar
- Period reminder notification
- **App Lock / Face ID** — never paywall a privacy/safety feature in a privacy app
- Basic insights (current + average cycle length)

**Solstice+ (paid)**
- **Fertile window + ovulation prediction** ← highest willingness-to-pay feature (TTC cohort)
- Advanced insights & charts: cycle variability, symptom/mood correlations, PMS prediction
- Apple Health sync
- Home/Lock Screen widgets
- CSV / data export (privacy buyers love data ownership)
- Advanced notifications (fertile-window, late-period, custom reminders)

## 2. Price points (USD)

| Tier | Price | Notes |
|------|-------|-------|
| Monthly | **$4.99** | Deliberately under Flo's $9.99 — we have no server costs, signal honesty |
| Annual | **$29.99** (~$2.50/mo) | ~50% off monthly run-rate; ~40% under Flo's ~$49.99 |
| **Lifetime** | **$79.99** (hero) | ≈2.7 yrs of annual; near-pure margin; the offer competitors can't match |

- Show all three with **Lifetime visually emphasized** ("Pay once — it's yours").
- Periodic **Lifetime sale to $59.99** (launch/holidays) to harvest fence-sitters.

## 3. Trial & paywall mechanics

- **7-day free trial on the annual plan** (trials drive annual; lifetime needs no trial).
- **Soft paywall, value-first.** Onboarding → first period logged → show first *prediction* →
  THEN paywall framed around fertile-window + insights. A hard wall reads as predatory here.
- **Contextual upsell**: tapping fertile window / export / widgets surfaces a focused single-feature
  prompt, not a generic wall.
- Restate the **privacy promise on the paywall** ("No account. No cloud. Pay once if you want.")
  and make **Restore Purchase** prominent (privacy users reinstall / switch devices).

## 4. Positioning — why privacy *is* the product

**Promise:** *"Solstice tracks your cycle entirely on your phone — no account, no cloud, nothing
for anyone to subpoena, sell, or breach."*

You pay Solstice so that no one can monetize you. Three **verifiable** proof points:
1. **No account = nothing to breach** (contrast: Flo's 2021 FTC settlement for sharing health data).
2. **On-device prediction** — no server has to "see" your data to work.
3. **No tracking SDKs** — independently audited, ideally open-source ("don't trust us, read the code").

**Post-Roe angle, handled responsibly:** lead with control & peace of mind, state facts (data on
servers can be subpoenaed/sold; data that never leaves the phone can't be). Promise is data
*minimization*, not legal immunity — never imply the app keeps anyone out of legal jeopardy.

## 5. Target segments (ranked)

1. **Privacy-native consumers** (Proton/Signal/VPN users) — best converter, highest LTV, evangelize. **Lead here.**
2. **People in restrictive US states / politically-engaged women** — biggest PR & word-of-mouth engine.
3. **Trying-to-conceive (TTC)** — highest functional WTP; retention/upsell play, not the spearhead.
4. **Parents buying for teens** — real concern, slow cycle; pursue later via family plan.

## 6. Acquisition channels (top 3)

1. **ASO** — own "private period tracker," "no account cycle tracker," "offline period app." The
   Apple Privacy Nutrition Label should be the cleanest in the category — that label *is* advertising.
   30 localizations = 30 ASO surfaces; localize keywords, not just the binary.
2. **PR + SEO content** — post-Roe period privacy is evergreen press; pitch the audit, open-source
   release, and the Flo contrast. Cheapest durable channel.
3. **Community + creators** (r/privacy, r/TwoXChromosomes, privacy YouTubers/newsletters) — founder-led,
   authentic; trust transfers and the community does verification for you.

Deprioritize paid social/UA early — expensive, off-brand, distrusted by this audience.

## 7. Trust levers that justify the price

- **Named third-party security audit**, report published; auditor logo on the paywall.
- **Open-source the core** (at least the data-handling layer).
- **"We literally can't see your data"** — explain the no-account/no-server/no-SDK architecture in plain language.
- Merchandise these in **App Store screenshots 1–2** and **above the price on the paywall**.

## 8. Regional / PPP pricing (30 languages live)

Use App Store tiers with **manual PPP overrides** (Apple's auto-FX misprices emerging markets).

- **US / W. Europe / UK / AU / CA / Nordics / JP:** baseline ($4.99 / $29.99 / $79.99).
- **India, Brazil, Turkey, Indonesia, Vietnam, Philippines, Mexico:** ~55–70% off; weight presentation
  toward **Lifetime** (subscription churn & card distrust are worse). e.g. India lifetime ≈ ₹1,999,
  Brazil ≈ R$129, Turkey ≈ ₺899 (re-index quarterly for inflation).
- **E. Europe / SE Asia mid (Poland, Thailand, Malaysia):** ~35–45% off.
- Localize **price + paywall copy together**; never show a raw USD price in a localized UI.
- Guard the floor (never below ~$1.49/mo equiv) and protect the annual↔lifetime ratio so "pay once" survives translation.

## 9. Secondary revenue

- **Lifetime unlock** — yes, aggressively (already the hero; it's an anti-subscription statement).
- **Donations / pay-what-you-want** — yes, as a supplement for the open-source crowd.
- **Family plans** — yes, later (teen/parent persona, raises LTV with no new acquisition cost).
- **B2B2C (clinics/OB-GYN)** — selectively, as an **endorsement/referral** halo, not data integration.
- **White-label** — no, for now; dilutes the brand that *is* the asset.

---

## The math (Year 1, indie iOS, organic/ASO-led)

Apple **Small Business Program → 15% cut** (we qualify <$1M). **No server costs → ~85% gross margin,
~$0 marginal cost per user.** Break-even is in the **hundreds** of paying users, not thousands.

| Scenario | Downloads/mo | Free→Paid | Payers/yr | Gross/yr | Net after Apple (85%) |
|----------|-------------|-----------|-----------|----------|----------------------|
| Conservative | 1,500 | 3.0% | 540 | $16,190 | ~$13,760 |
| Base | 5,000 | 3.5% | 2,100 | $62,980 | ~$53,530 |
| Optimistic | 15,000 | 4.5% | 8,100 | $242,920 | ~$206,480 |

(Modeled at $29.99 annual ARPU; lifetime mix raises blended ARPU. Year-1 = gross bookings before churn.
Cash opex ex-dev-salary ≈ $8–30K/yr: $99 Apple, optional $5–15K audit, $2–10K ASO, $1–5K localization upkeep.)

**Strategic implication:** iOS-only + no backend + privacy moat → the math favors
**subscription-primary / lifetime-secondary hybrid**: high margin, churn-hedged, profitable at low scale,
and aligned with the exact users a privacy-first app attracts. Avoid ad-supported (kills the moat, pays
terribly at this scale) and pure-lifetime-only (caps the recurring base).

---

## Next concrete steps

1. Add a `SolsticeEntitlements` / StoreKit 2 layer with three products (monthly, annual, lifetime).
2. Build the soft paywall (value-first, after first prediction) + contextual upsells on gated features.
3. Gate the premium features listed in §1 behind an `isPremium` check; keep App Lock + basic tracking free.
4. Configure App Store Connect: Small Business Program, 3 IAP products, PPP price overrides, localized paywall copy.
5. Commission the third-party security audit; prepare the open-source data-layer release for credibility.
