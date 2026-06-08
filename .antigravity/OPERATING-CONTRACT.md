# Operating Contract

You are a senior iOS engineer working in the LightMeter repo. A Claude reviewer
approves every PR before you continue. Obey these rules exactly.

## Environment (critical — the default toolchain is broken)

The active `xcode-select` is CommandLineTools, which **lacks the Testing framework
and `xcodebuild`**. Always prefix build/test commands with the full Xcode developer
dir:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

- Regenerate the Xcode project after adding/moving files: `xcodegen generate`
- Build + test the full app (runs the real XCTest/Testing bundle):

```bash
xcodebuild -project LightMeter.xcodeproj -scheme LightMeter \
  -destination 'id=59C9F085-A353-40D4-867A-F9296E2FD665' build

xcodebuild -project LightMeter.xcodeproj -scheme LightMeter \
  -destination 'id=59C9F085-A353-40D4-867A-F9296E2FD665' test
```

If that simulator id is gone, run `xcodebuild -showdestinations -scheme LightMeter`
and pick any available iPhone simulator.

- Quick pure-logic iteration only (no UI/camera):
  `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test`

## Workflow

- **One task per branch per PR.** Branch: `<plan>/<task-id>-<slug>`
  (e.g. `correctness/c1-lux-smoothing`). Do exactly one task, then STOP.
- **Conventional Commits** (`feat:`, `fix:`, `perf:`, `refactor:`, `chore:`,
  `docs:`, `test:`). PR title = commit summary. Keep PRs focused (ideally < ~400
  changed lines).
- Push the branch to `origin` (SSH is configured and working). Open a PR if your
  tooling can; the pushed branch is what the reviewer reads.
- Follow [`REVIEW-PROTOCOL.md`](REVIEW-PROTOCOL.md) for the handshake.

## Architecture — do not violate the "deterministic split"

- Pure math/interpretation lives in `LightMeter/Logic/` as deterministic,
  hardware-free code **with unit tests**.
- Effects (`LightMeter/Camera/`) stay thin hardware wrappers.
- Views (`Features/`, `SharedViews/`) hold **no business logic**.
- When you add a pure-logic file, add it to **both** `project.yml` pickup
  (automatic via `xcodegen generate`) **and** the explicit `sources` list in
  `Package.swift`, or SPM tests won't compile it.

## Definition of Done (every task)

- Builds with **zero warnings**. All existing **133 tests** still pass. New logic
  ships with new tests.
- No new force-unwraps on the per-frame hot path (`CameraFrameProvider`).
- **App Store posture:** no medical/health claims in any user-facing copy.
  Accessibility must not regress.
- Update affected docs (`README.md`, `docs/developer-guide.md`) **in the same PR**
  when behavior, test counts, or features change — this repo tracks doc drift.

## Guardrails

- Do **not** recreate `.kiro/`. Do **not** commit `.swiftpm/` (gitignored).
- Do **not** change code signing or `DEVELOPMENT_TEAM`.
- Do **not** widen camera/privacy scope without calling it out in the review file.
- Do **not** merge a branch whose review verdict is not `APPROVED`.
