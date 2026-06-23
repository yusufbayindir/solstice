# Naming Decision — Privacy-First iOS Cycle Tracker

Prepared by: The Naming Committee (3 voices)
Date: 2026-06-23
Input: `docs/market-analysis.md`

Product: A privacy-first, local-first menstrual / cycle tracker for iOS. Positioning: the
privacy of Drip/Euki with the polish of Flo. Calm, modern, inclusive — explicitly **not**
pink-gimmicky. **Trust is the product.**

Hard constraint: the name must be a clean, identifier-safe word (one or two words) usable as a
SwiftUI app / module name, and must avoid the names of major incumbents (Flo, Clue, Stardust,
Drip, Euki, Periodical, Natural Cycles, Spot On, Eve, Glow, Ovia, Cycles).

---

## 1. Per-voice proposals

### Voice 1 — ASO / keyword strategist
Wants the name to do search work: hint at "cycle," be brandable enough to rank on its own
term, and pair cleanly with category keywords in the subtitle. Avoids dictionary collisions.

1. **Cadence** — "cycle/rhythm" semantics without saying "period." Strong, calm, human.
   ASO risk: a prominent GPS bike/run tracker owns the term; common English word dilutes ranking.
2. **Tideline** — evokes a recurring natural rhythm (tides ↔ cycles). Distinctive two-syllable
   coinage-feel. ASO clean in femtech, but a women's-health clinic and consulting firm hold the word.
3. **Tempo** — rhythm/pacing metaphor; very short. Crowded as a generic word; weak ownability.
4. **Cyclo** — maximally on-keyword. But the App Store is saturated with Cylo / Cyclia / Cycli /
   Cicle near-clones; zero distinctiveness, high confusion. Reject.
5. **Lunary** — lunar = monthly cycle, soft and brandable. But the "Luna/Lunari/Lunation" space
   is packed with period trackers; collision-heavy and reads slightly mystical/woo (off-brief).

### Voice 2 — brand / poetry
Wants a name that *feels* like calm, safety, and bodily autonomy — a name that earns trust
emotionally and reads beautifully on a Home Screen. Leans toward natural-cycle imagery, away
from clinical or pink-cute.

1. **Solstice** — a turning point in a natural cycle; warm, premium, calm. Suggests rhythm and
   light without "period." Six letters of brand, not a category cliché.
2. **Vela** — a constellation ("the sail"); quiet, modern, inclusive, ungendered. A short open
   vowel-name with a feeling of steady navigation. No femtech collision.
3. **Vellum** — old paper for private writing; "your record, kept by you." Privacy-coded. But
   semantically distant from cycles and already crowded on the App Store (wallpapers, AI writers).
4. **Selene** — Greek moon goddess; lovely, but **already a privacy-first period tracker** on
   iOS (two of them). Direct collision. Reject.
5. **Cove** — a sheltered, private place. On-brief emotionally, but heavily used in health/
   mental-health apps (Cove Behavioral Health, Cove music-for-mental-health). Crowded.

### Voice 3 — skeptic / availability checker
Mandate: kill anything that collides on the App Store, clashes in women's-health trademark
classes, or can't plausibly get a domain. Trust is the product — a confusable name is a
self-inflicted wound, and a name shared with another health entity is a legal liability.

Verdicts after live checks (June 2026):
- **Cyclo / Lunary** — App Store is a swamp of near-identical cycle/luna names. **Veto.**
- **Cadence** — a well-known GPS fitness tracker already owns the term; dictionary word, hard to
  own in search. **High risk; demote.**
- **Tideline** — clean in the *app* space, but there is a **"Tideline Center for Health &
  Aesthetics" doing women's intimate health**, and `tideline.com` is held by an impact-investing
  firm. Same-field trademark adjacency + taken primary domain. **Elevated risk; demote.**
- **Selene** — two existing iOS period trackers (one explicitly local/offline). **Veto.**
- **Cove / Vellum** — crowded in adjacent health/utility categories. **Medium risk.**
- **Solstice** — the only iOS "Solstice" apps are a TCM ear-seed app and a daylight widget;
  **no femtech collision, no women's-health trademark clash found.** Common word → must rely on a
  distinctive subtitle/icon, and `solstice.com` likely taken (use `.app` / a qualified domain).
  **Low-to-medium risk — acceptable and the cleanest of the evocative set.**
- **Vela** — no period-tracker collision, no major app collision, no obvious health trademark.
  Very short → some genericness/domain pressure, but **lowest collision risk in the set.**
  **Low risk.**

---

## 2. Scoring matrix

Scale 1–5 (5 = best). "Availability" is scored so that 5 = lowest risk.

| Candidate | Clarity (cycle/privacy hint) | Distinctiveness | ASO keyword value | Brevity | Brandability | Availability (5=low risk) | **Total** |
|-----------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **Solstice** | 4 | 4 | 3 | 4 | 5 | 4 | **24** |
| **Vela**     | 2 | 5 | 2 | 5 | 5 | 5 | **24** |
| **Tideline** | 4 | 4 | 3 | 4 | 4 | 2 | **21** |
| **Cadence**  | 4 | 3 | 3 | 4 | 4 | 2 | **20** |
| **Cove**     | 3 | 3 | 2 | 5 | 4 | 3 | **20** |
| **Vellum**   | 2 | 3 | 2 | 4 | 4 | 2 | **17** |
| **Lunary**   | 4 | 2 | 3 | 4 | 3 | 1 | **17** |
| **Cyclo**    | 5 | 1 | 4 | 4 | 2 | 1 | **17** |

Notes:
- **Solstice**: high brand + clean field, modest ASO (common word) but recoverable with subtitle.
- **Vela**: ties on total via near-perfect distinctiveness/brevity/availability, but pays for it in
  clarity and ASO — the name alone says nothing about cycles, so it leans entirely on positioning.
- **Tideline / Cadence**: strong on meaning, dragged down by real availability/trademark adjacency.

---

## 3. The vote

A two-way tie at 24 (Solstice vs. Vela). Resolved by discussion, then a recorded vote.

- **Voice 1 (ASO):** Votes **Solstice**. "Vela is gorgeous but it's a blank — it carries *zero*
  category signal, so every install has to be bought with the subtitle and the icon. Solstice at
  least whispers 'cycle, turning point, rhythm,' which is the metaphor we *want* to own. I can rank
  'Solstice — Private Cycle Tracker.' I can't easily rank 'Vela.'"
- **Voice 2 (brand/poetry):** Votes **Solstice**. "Both are beautiful. But Solstice means
  something on-brief: a turning point in a *natural cycle*, warmth and light, calm and premium —
  no pink, no clinic. It tells the trust story without a single gendered or cutesy note. Vela is
  serene but arbitrary; Solstice is serene *and* meaningful."
- **Voice 3 (skeptic):** Votes **Solstice (with a guardrail)**. "Vela is the safest name on
  paper, and if Solstice's domain/word-genericness scared me I'd switch. But Solstice has **no
  femtech App Store collision and no women's-health trademark clash** — that clears my bar. It's a
  common word, so we **must** lock distinctiveness through the subtitle, icon, and a qualified
  domain (`getsolstice.app` / `solstice.health`-style), and file the trademark in the app/health
  class early. With that, I'm comfortable. 3–0."

**Vote: Solstice 3 — Vela 0.** Vela is recorded as the official fallback if a late trademark or
domain block emerges.

---

## 4. WINNER

# Solstice

A turning point in a natural cycle — calm, premium, and meaningful without being clinical or
pink. It signals rhythm and light, carries the trust story, and is the cleanest evocative name in
the femtech App Store field.

- **Tagline (one line):** *Your cycle, kept private — and beautifully understood.*
- **App Store subtitle (≤30 chars):** `Private cycle tracker` (21 chars)
  - Alternates: `Private period tracker` (22), `Calm, private cycle log` (23)
- **Swift-safe form (Xcode project / module):** `Solstice` (already PascalCase, identifier-safe).
  - Bundle id suggestion: `app.solstice.ios` or `com.<org>.solstice`.

### Keyword seed list (App Store / ASO)
`period tracker`, `cycle tracker`, `menstrual cycle`, `ovulation tracker`, `fertility window`,
`period calendar`, `private period tracker`, `local period tracker`, `offline cycle tracker`,
`no account period app`, `secure period tracker`, `cycle prediction`, `symptom tracker`,
`mood tracker`, `PMS tracker`, `women's health`, `cycle log`, `menstrual health`,
`Face ID privacy`, `on-device health`.

### Guardrails (from Voice 3, carried into launch)
1. Lock distinctiveness via subtitle + icon + a qualified domain (`.app` / `.health`), since
   "solstice" is a common word.
2. File the trademark early in the relevant app / digital-health class.
3. Keep monitoring for any new "Solstice" femtech entrant before launch; if blocked, fall back to
   **Vela**.
