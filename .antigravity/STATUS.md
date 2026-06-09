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
| P2 | `@Observable` migration | PENDING | — |
| P3 | Decompose the god object | PENDING | — |
| P4 | Records → SwiftData (+ CSV export) | PENDING | — |

## Plan 3 — Product & App Store Readiness  *(do last)*

| Task | Title | State | Merge |
|------|-------|-------|-------|
| R1 | Photographer readouts (EV / f-stops / fc) | PENDING | — |
| R2 | Accessibility (Dynamic Type + VoiceOver) | PENDING | — |
| R3 | App Store compliance pass | PENDING | — |
| R4 | Capture polish | PENDING | — |

---

**Current task:** none started yet → begin with **C1**.
