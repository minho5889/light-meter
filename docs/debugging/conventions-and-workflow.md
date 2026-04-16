# Conventions and Workflow

This document explains the naming conventions, commit message strategy, and spec-driven development workflow used in this project. If you're reading the git log and wondering what `[S09_T01_fix]` means or why there are numbered spec folders, this is the guide.

---

<a id="table-of-contents"></a>
## Table of Contents

1. [Commit Message Format](#1-commit-message-format)
2. [Naming Conventions](#2-naming-conventions)
3. [Spec-Driven Development with Kiro](#3-spec-driven-development-with-kiro)
4. [Reading the Git History](#4-reading-the-git-history)

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

- Wrap TabView in ZStack with single CameraPreviewView behind it
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

### Spec folders

Format: `{number}-{description}` — all lowercase, hyphen-separated, max 50 characters.

Examples from this repo:

```
01-ios-light-meter-skeleton
05-deterministic-split-refactor
08-camera-session-black-screen
09-single-preview-layer
```

Numbers are sequential and never reused. If a spec is revised, append `-v2`.

---

## [3. Spec-Driven Development with Kiro](#table-of-contents)

This project was built using Kiro, an AI-assisted IDE that supports spec-driven development. Here's what that means and how it shows up in the repo.

### What is Kiro

Kiro is an IDE (built on VS Code) with an integrated AI agent that can read, write, and reason about code. It has two key features relevant to this project:

- **Specs** — structured documents that define requirements, design decisions, and implementation tasks for a feature. The agent works through tasks incrementally, with the developer reviewing and guiding each step.
- **Steering files** — persistent instructions (in `.kiro/steering/`) that guide the agent's behavior across all interactions. Things like "use this commit format" or "follow the deterministic split architecture" live here so they don't need to be repeated.

### How specs work

Each spec lives in `.kiro/specs/{number}-{description}/` and contains three files:

| File | Purpose |
|------|---------|
| `bugfix.md` or `requirements.md` | What needs to be built or fixed, with numbered requirements |
| `design.md` | Technical design decisions and constraints |
| `tasks.md` | Ordered implementation checklist with checkboxes |

The agent works through `tasks.md` top to bottom. Each task references specific requirements from the requirements doc. When a task is done, it gets checked off. Commits are tagged with the spec and task number (`[S09_T01_fix]`).

### How steering files work

Steering files in `.kiro/steering/` are markdown documents that the agent loads automatically. They define project-wide rules:

| File | What it controls |
|------|-----------------|
| `commit-conventions.md` | The commit message format described above |
| `naming-conventions.md` | File and directory naming rules |
| `deterministic-split.md` | The pure logic / effects / glue architecture |
| `document-formatting.md` | TOC structure, source citations, section linking |

These are the reason the git history is so consistent — the agent follows these rules on every commit.

### Why this matters for reading the repo

If you're looking at the git log and see patterns like `[S08_T03_fix]`, you can trace that commit back to:

1. Spec folder: `.kiro/specs/08-camera-session-black-screen/`
2. Task 3 in `tasks.md`
3. The requirements it addresses (listed at the end of each task)

This gives you full traceability from commit → task → requirement → design decision.

---

## [4. Reading the Git History](#table-of-contents)

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

The full investigation is documented in [troubleshooting.md](troubleshooting.md), section 8.

### Quick reference

| Prefix | Meaning |
|--------|---------|
| `S{XX}` | Spec number — maps to `.kiro/specs/{XX}-*/` |
| `T{YY}` | Task number — maps to a checkbox in `tasks.md` |
| `NT` | Non-task — work outside any spec |
| `feat` | New feature |
| `fix` | Bug fix |
| `test` | Test changes |
| `refactor` | Restructuring |
| `docs` | Documentation |
| `chore` | Config/tooling |
| `style` | Formatting only |
