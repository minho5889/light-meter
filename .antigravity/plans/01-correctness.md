# Plan 1 — Correctness & Measurement Integrity

**Goal:** make the numbers honest and remove App Review liability. Do this plan
**first** — `C3` (remove medical claims, honest flicker) is a hard App Review gate,
and these files (`CameraFrameProvider`, `CameraViewModel`, `FlickerAnalyzer`) are
re-touched by Plan 2, so settle semantics here first.

Execute tasks in order: **C1 → C2 → C3 → C4**. One branch + PR each. Stop for review
after every task (see [`../REVIEW-PROTOCOL.md`](../REVIEW-PROTOCOL.md)).

---

## C1 — Lux/Kelvin smoothing & honest readout
**Branch:** `correctness/c1-lux-smoothing` · **Type:** `feat`

**Why:** lux/Kelvin currently update raw every frame and jitter; the displayed
precision overstates a reflected-light estimate.

**Do:**
- Add `LightMeter/Logic/SignalSmoother.swift`: a pure, `Sendable` exponential
  moving-average smoother (configurable `alpha`, `reset()`, `update(_:) -> Double`).
- Apply it to lux and Kelvin before they reach the UI.
- Display lux rounded to ~2 significant figures (an estimate, not a precise number).
- Add the new file to `Package.swift` sources.
- **Do not** refactor the per-frame `Task` dispatch — that's Plan 2. Keep this minimal.

**Acceptance criteria:**
- New `SignalSmoother` unit tests: convergence to a constant input, bounded output
  (never overshoots input range), correct step-response direction, `alpha`
  edge values (0 and 1).
- On-device/sim: lux readout visibly stabilizes (no per-frame flicker).
- All existing tests pass; build clean.

---

## C2 — Color temperature: tint / Duv
**Branch:** `correctness/c2-tint` · **Type:** `feat`

**Why:** two lights at the same Kelvin look different on the green↔magenta axis;
`.tint` is currently discarded.

**Do:**
- In the Kelvin path (`CameraFrameProvider`), also read
  `device.temperatureAndTintValues(...).tint`.
- Expose tint through the view model; interpret it as a localized green/magenta
  descriptor (EN/KO/FR) matching the existing `KelvinInterpreter` style.
- Show a tint indicator on the Temperature tab.

**Acceptance criteria:**
- Unit tests for the tint interpreter: green/neutral/magenta mappings + boundaries,
  plus KO/FR translation assertions (mirror existing localization tests).
- Temperature tab shows tint without layout regressions.
- All existing tests pass; build clean.

---

## C3 — Flicker honesty  *(highest priority of this plan)*
**Branch:** `correctness/c3-flicker-honesty` · **Type:** `fix`

**Why:** the safety rating makes medical claims on data it physically cannot fully
capture, and its magnitude constant was fitted to the test oracle.

**Do:**
1. Replace the fudged magnitude scale in `FlickerAnalyzer` (the `3.0 * N` constant
   the comment admits was fitted) with a constant **derived** from the Hann window
   coherent gain (0.5) and real-FFT positive-bin doubling. Recompute
   `FlickerAnalyzerTests` expected values **analytically** from the synthetic wave
   amplitudes — not by curve-fitting to pass.
2. Compute the Nyquist ceiling (`sampleRate / 2`). Never return an absolute
   "Safe"/"Very Safe" claim — phrase as **"no flicker detected up to N Hz"** and
   state that PWM/LED flicker above N Hz cannot be measured by frame-rate sampling.
3. Rewrite **all** safety copy (`FlickerAnalyzer` + `FlickerInterpreter`, all 3
   locales) to be informational/relative. **Remove every medical claim**
   ("headaches", "dizziness", "eye fatigue", "risk", etc.). Add a short
   "informational, not medical advice" disclaimer string.

**Acceptance criteria:**
- The magnitude constant has a derivation comment citing window gain + FFT scaling;
  no "matches the oracle" language remains.
- Tests assert frequency + relative-amplitude accuracy against 50/100/120 Hz waves,
  the Nyquist-ceiling labeling, and that copy contains no banned medical terms.
- Flicker docs updated to describe the honest framing + frequency ceiling.
- All existing tests pass (updated as needed); build clean.

---

## C4 — Reflected-light disclosure & calibration
**Branch:** `correctness/c4-calibration` · **Type:** `feat`

**Why:** the camera measures reflected light but the app presents incident lux.

**Do:**
- Add a clear, dismissible disclosure on the LUX tab: readings are a
  **reflected-light estimate**, not incident lux.
- Add `LightMeter/Logic/CalibrationStore.swift`: a pure, tested multiplier applied
  to `LuxCalculator` output, persisted, with a simple "calibrate to a known lux
  value" entry point in the UI. Add the file to `Package.swift` sources.

**Acceptance criteria:**
- `CalibrationStore` unit tests: identity by default, correct multiplier from a
  known-value calibration, persistence round-trip, sane clamping.
- Disclosure visible and dismissible; calibration reachable from the UI.
- All existing tests pass; build clean.
