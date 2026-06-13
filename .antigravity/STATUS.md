# Status Ledger

Source of truth for "what's next." Antigravity updates a task to `DONE` (with the
squash-merge short-hash) only **after** the reviewer approves and the branch merges
to `main`. Work the first `PENDING` task whose predecessors are all `DONE`.

Legend: `PENDING` · `IN_PROGRESS` · `AWAITING_REVIEW` · `CHANGES_REQUESTED` · `DONE`

## Plan 1 — Correctness  *(do first)*

| Task | Title | State | Merge |
|------|-------|-------|-------|
| C1 | Lux/Kelvin smoothing & honest readout | DONE | 6c4d0e7 |
| C2 | Color temperature tint / Duv | DONE | 1c016d8 |
| C3 | Flicker honesty (no medical claims) | DONE | 5359a89 |
| C4 | Reflected-light disclosure & calibration | DONE | 613cfd6 |

## Plan 2 — Performance & Architecture

| Task | Title | State | Merge |
|------|-------|-------|-------|
| P1 | Kill per-frame allocations | DONE | c0acaf7 |
| P2 | `@Observable` migration | DONE | 0f5fa17 |
| P3 | Decompose the god object | DONE | 67ec9eb |
| P4 | Records → SwiftData (+ CSV export) | DONE | 0383528 |

## Plan 3 — Product & App Store Readiness  *(do last)*

| Task | Title | State | Merge |
|------|-------|-------|-------|
| R1 | Photographer readouts (EV / f-stops / fc) | DONE | fdc6d45 |
| R2 | Accessibility (Dynamic Type + VoiceOver) | DONE | 1f50052 |
| R3 | App Store compliance pass | DONE | 8b0a535 |
| R4 | Capture polish | DONE | c438d34 |

---

**Current task:** 🎉 ALL TASKS DONE — C1–C4, P1–P4, R1–R4 all merged. No PENDING work
remains. The app is feature-complete and App-Store-build-ready; remaining work is
TestFlight signing (pending Sunny InnoLab files — see docs/release-checklist.md).

> **Note:** R3 was implemented directly by the reviewer (Claude) to fast-track the
> TestFlight gate, not via Antigravity. Antigravity must SKIP R3 and go straight to R4.
