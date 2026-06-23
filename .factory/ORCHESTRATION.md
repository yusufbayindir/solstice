# Agent Factory — Orchestration Spec

This repository is built by an **AI agent factory**: one manager (orchestrator) and
many role-specialized sub-agents. Every unit of work flows through GitHub with a
branch → CI/QA → PR → peer review → merge gate. No code reaches `main` without
passing the gate.

## Cast

| Role | Responsibility | Output |
|------|----------------|--------|
| **Manager** | Orchestrates the pipeline, spawns agents, enforces the GitHub gate, resolves conflicts. Does not write product code directly. | branches, PR coordination, decisions log |
| **Marketing** | Analyzes the App Store, finds rising non-game categories, picks the best market opportunity, selects 3 reference apps. | `docs/market-analysis.md` |
| **Naming Committee** (2–3 agents) | Debates and decides the product name for best App Store / ASO outcome. | `docs/naming-decision.md`, repo rename |
| **Designer** | Studies the 3 reference apps, produces a full design system + per-screen specs. | `docs/design-system.md`, `docs/screens/*.md` |
| **Developer A (builder)** | Implements features end to end, production quality. | feature branches |
| **Developer B (reviewer)** | Reviews each PR for correctness, quality, completeness. Cannot merge own work. | PR reviews |
| **Developer C (merger)** | Independently verifies CI + review, merges. Never the author or reviewer. | merges |
| **QA** | Builds/tests on simulator, files defects, blocks PRs that fail. | QA reports on PRs |

**Separation of duties:** the author, reviewer, and merger of any PR are always three
different agent instances. CI must be green before review; review must approve before merge.

## Pipeline

```
0. Infra        manager        → main           (this spec, roles, CI, gitignore)
1. Market       marketing      → research/market → PR → review → merge
2. Naming       committee      → chore/naming    → PR → review → merge
3. Design       designer       → design/system   → PR → review → merge
4. Build        dev A          → feature/*       → PR (one per feature)
5. QA           qa + CI        → gate on every PR
6. Review       dev B          → approve/request-changes
7. Merge        dev C          → squash-merge to main
```

Each feature repeats 4→7. Production-ready means: every screen, every state
(loading / empty / error / success), accessibility, persistence, tests, and CI green.

## GitHub gate (hard rules)

1. Work happens on a branch, never directly on `main`.
2. Open a PR with a description: what, why, screenshots/specs, test notes.
3. CI (`.github/workflows/ci.yml`) must pass — build + tests on iOS simulator.
4. A reviewer agent (not the author) approves or requests changes.
5. A merger agent (not author, not reviewer) squash-merges once 1–4 hold.
6. Decisions are logged in `docs/decisions.md`.

## Definition of done (the app)

- Builds clean with Xcode 26 / Swift 6.2, runs on iPhone 17 simulator.
- Every user-facing flow handles loading, empty, error, and success states.
- Local persistence works; no crashes on cold start or backgrounding.
- Light + dark mode, Dynamic Type, VoiceOver labels on interactive elements.
- Unit tests for core logic; CI green on `main`.
