# Conventions and Workflow

This document explains the naming conventions and commit message strategy used in this project. If you're reading the git log and wondering what `[S09_T01_fix]` means, this is the guide.

> **Note:** This project was originally developed in the Kiro IDE using spec-driven development, where each feature had a spec folder under `.kiro/specs/`. Those spec folders have since been removed, but their numbering lives on in the commit prefixes below — `S{XX}` is the spec number and `T{YY}` is the task number within it.

---

<a id="table-of-contents"></a>
## Table of Contents

1. [Commit Message Format](#1-commit-message-format)
2. [Naming Conventions](#2-naming-conventions)
3. [Reading the Git History](#3-reading-the-git-history)

---

## [1. Commit Message Format](#table-of-contents)

Every commit follows one of two formats depending on whether it's tied to a spec task or not.

### Spec task commits

Format: `[S{XX}_T{YY}_{category}]: one-liner summary`

- `S{XX}` — spec number, zero-padded (e.g., `S01`, `S09`)
- `T{YY}` — task number within that spec (e.g., `T01`, `T04`)
- `{category}` — one of: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `style`

Examples from this repo:

```
[S09_T01_fix]: move CameraPreviewView to ContentView as shared single instance
[S09_T04_test]: verify no regressions in existing test suite
[S08_T03_fix]: fix camera session black screen on tab transitions
[S07_T08_feat]: add per-tab camera session management in ContentView
```

### Non-task commits

Format: `[NT_{category}]: one-liner summary`

`NT` stands for "non-task" — work done outside of any spec.

Examples from this repo:

```
[NT_docs]: update docs to reflect spec 08 camera session bugfix
[NT_fix]: use ISO 2720 incident-light constant (C=250) for lux calculation
[NT_refactor]: reorganize source and test files into subdirectories
```

### Categories

| Category | Use When |
|----------|----------|
| `feat` | New feature or functionality |
| `fix` | Bug fix |
| `test` | Adding or updating tests |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation changes |
| `chore` | Project config, dependencies, tooling |
| `style` | Formatting, whitespace, no logic change |

### Body format

The one-liner is followed by a blank line and bullet points describing what changed:

```
[S09_T01_fix]: move CameraPreviewView to ContentView as shared single instance

- Wrap the custom switcher in ZStack with single CameraPreviewView behind it
- Gate preview on permissionGranted and isCameraTab
- Non-camera tabs show opaque placeholder backgrounds
```

---

## [2. Naming Conventions](#table-of-contents)

### Files

| Type | Convention | Example |
|------|-----------|---------|
| Swift source | `PascalCase.swift` (matches type name) | `CameraSessionManager.swift` |
| Markdown docs | `kebab-case.md` | `developer-guide.md` |
| Screenshots/images | `kebab-case.png` | `live-measurement.png` |
| Config files | Ecosystem convention | `Package.swift`, `project.yml` |

### Directories

| Context | Convention | Example |
|---------|-----------|---------|
| Project directories | `kebab-case` | `docs/`, `screenshots/` |
| Xcode/SPM targets | `PascalCase` (required by tooling) | `LightMeter/`, `LightMeterTests/` |

---

## [3. Reading the Git History](#table-of-contents)

Here's how to decode the commit log for this project.

### Chronological flow

The specs were implemented in order. The git history reads roughly as:

1. `S01` through `S07` — initial app build, feature by feature
2. `S08` — camera session black screen bugfix (tab transition lifecycle)
3. `S09` — single preview layer fix (the architectural root cause of the black screen)
4. `NT_*` commits — documentation updates, refactors, and fixes done between or after specs

### Tracing a bug fix

Example: the black screen bug.

- `S08` commits fixed the symptom (unnecessary session stop/start cycles on tab switches)
- `NT_docs` commits documented the root cause analysis (multiple competing `AVCaptureVideoPreviewLayer` instances)
- `S09` commits fixed the root cause (moved to a single shared preview layer in `ContentView`)

The full investigation is documented in the [Black Screen Post-Mortem](black-screen-post-mortem.md).

### Quick reference

| Prefix | Meaning |
|--------|---------|
| `S{XX}` | Spec number (spec folders were removed when the project left Kiro; the numbers remain in history) |
| `T{YY}` | Task number within that spec |
| `NT` | Non-task — work outside any spec |
| `feat` | New feature |
| `fix` | Bug fix |
| `test` | Test changes |
| `refactor` | Restructuring |
| `docs` | Documentation |
| `chore` | Config/tooling |
| `style` | Formatting only |
