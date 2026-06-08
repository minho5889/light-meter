# Plan 2 — Performance & Architecture

**Goal:** remove the per-frame allocation storm and modernize the app for iOS 17.
Do this plan **after Plan 1** — `P1` restructures the same hot-path files Plan 1
edited, so **rebase on latest `main` first**.

Execute tasks in order: **P1 → P2 → P3 → P4**. One branch + PR each. Stop for review
after every task.

---

## P1 — Kill the per-frame allocations
**Branch:** `performance/p1-hot-path` · **Type:** `perf`

**Why:** `CameraFrameProvider.captureOutput` spawns a `Task` per frame for the
pixel-buffer actor hop, and `onFrameUpdate` spawns another `Task { @MainActor }`
per frame — up to ~480 heap allocations/sec at 240 fps, plus invalidations.

**Do:**
- Store the latest `CVPixelBuffer` behind an `OSAllocatedUnfairLock` (iOS 17-safe),
  not an `await` to an actor.
- Coalesce lux/Kelvin UI updates to ~10 Hz max, and **skip them when the active tab
  isn't LUX/Temperature** (today they fire at up to 240 fps on the Check tab).
- Don't retain pool-backed buffers longer than necessary.

**Acceptance criteria:**
- No per-frame heap `Task` allocations on the capture path (explain how verified).
- Lux still updates smoothly; no new frame drops; no data races (Swift 6 strict
  concurrency stays clean).
- **The two known `CameraFrameProvider` `sending`/data-race warnings (lines ~37–38,
  the per-frame pixel-buffer Task) are eliminated** — this task owns them. After
  P1 the build must be truly zero-warning.
- All existing tests pass; build clean.

---

## P2 — `@Observable` migration
**Branch:** `performance/p2-observable` · **Type:** `refactor`

**Why:** the project requires iOS 17 but uses `ObservableObject`/`@Published`;
the Observation macro gives per-property tracking and cuts SwiftUI churn.

**Do:**
- Migrate `CameraViewModel` to the `@Observable` macro; update all observing views
  (`@StateObject`/`@ObservedObject` → `@State`/plain references as appropriate).

**Acceptance criteria:**
- Behavior identical; build clean; all tests pass.
- No remaining `@Published`/`ObservableObject` in migrated types.

---

## P3 — Decompose the god object
**Branch:** `performance/p3-decompose` · **Type:** `refactor`

**Why:** `CameraViewModel` owns lux, Kelvin, flicker, records, localization, and
permission — too much, now that Records is real.

**Do:**
- Split into `MeasurementModel` (lux/Kelvin), `FlickerModel` (flicker state/control),
  and `RecordsStore` (persistence), coordinated by a thin owner.
- Move any extractable logic into `Logic/` with tests; keep views thin.

**Acceptance criteria:**
- Each model has a single clear responsibility; no view gains business logic.
- New/!moved logic is tested; all existing tests pass; build clean.

---

## P4 — Records → SwiftData (+ CSV export)
**Branch:** `performance/p4-swiftdata` · **Type:** `feat`

**Why:** records persist as UserDefaults-JSON encoded on the main actor, unbounded.

**Do:**
- Replace persistence with a SwiftData model + store; encode off the main actor;
  cap history with paging; **migrate existing saved records on first launch**.
- Add CSV export via the share sheet.

**Acceptance criteria:**
- Tests for the legacy→SwiftData migration and the history cap.
- Existing records survive upgrade; export produces valid CSV.
- All existing tests pass; build clean.
