# Plan 3 — Product & App Store Readiness

**Goal:** turn a correct, fast app into a shippable one for the photographer
audience. Do this plan **last** — `R3` (compliance) verifies that `C3` removed all
medical claims. **Rebase on latest `main` first.**

Execute tasks in order: **R1 → R2 → R3 → R4**. One branch + PR each. Stop for review
after every task.

---

## R1 — Photographer readouts (EV, f-stops, foot-candles)
**Branch:** `product/r1-exposure-readouts` · **Type:** `feat`

**Why:** photographers think in EV and stops, not lux.

**Do:**
- Add `LightMeter/Logic/ExposureValueCalculator.swift` (pure, tested):
  EV at ISO 100 = `log2(lux / 2.5)`; equivalent f-stops; foot-candles = `lux / 10.764`.
  Add the file to `Package.swift` sources.
- Show a secondary EV readout and a lux / foot-candle / EV unit toggle (persisted).
  Localize labels.

**Acceptance criteria:**
- Unit tests: known lux→EV values, foot-candle conversion, boundary/zero handling.
- Unit toggle persists across launches; labels localized EN/KO/FR.
- All existing tests pass; build clean.

---

## R2 — Accessibility (Dynamic Type + VoiceOver)
**Branch:** `product/r2-accessibility` · **Type:** `feat`

**Why:** a measurement app must announce its values and scale its text; tab labels
are currently hardcoded 9pt.

**Do:**
- Replace hardcoded font sizes with Dynamic Type-scalable fonts.
- Add `accessibilityLabel`/`accessibilityValue` to every live reading and tab;
  announce the value on capture.

**Acceptance criteria:**
- With VoiceOver on, each reading and tab is read aloud meaningfully.
- At the largest Dynamic Type size, nothing clips or overlaps.
- All existing tests pass; build clean.

---

## R3 — App Store compliance pass
**Branch:** `product/r3-compliance` · **Type:** `chore`

**Why:** this is the release gate.

**Do:**
- Add `PrivacyInfo.xcprivacy` (declare camera use; no tracking).
- Review `NSCameraUsageDescription` wording.
- **Verify no medical/health claims remain anywhere** (depends on C3).
- Ensure app icon + launch screen + localized App Store metadata exist.
- Make `xcodebuild archive` validate cleanly. Add a release checklist under `docs/`.

**Acceptance criteria:**
- Privacy manifest present and correct; archive validates.
- Repo-wide grep shows zero banned medical terms in user-facing copy.
- All existing tests pass; build clean.

---

## R4 — Capture polish
**Branch:** `product/r4-polish` · **Type:** `feat`

**Why:** the small touches that make it feel finished.

**Do:**
- Haptics + shutter feedback on capture.
- Persist the selected camera position across launches.
- Share a record from the Records tab.

**Acceptance criteria:**
- Capture gives haptic + audible feedback; camera position restores on relaunch;
  a record can be shared.
- All existing tests pass; build clean.
