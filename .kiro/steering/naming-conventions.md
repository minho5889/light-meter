# Naming Conventions

## Directories

| Context | Convention | Example |
|---------|-----------|---------|
| Project directories you control | `kebab-case` | `docs/`, `screenshots/` |
| Xcode/SPM targets | `PascalCase` (required by tooling) | `LightMeter/`, `LightMeterTests/` |
| Tool-managed directories | Follow tool convention | `.kiro/`, `.build/` |

## Files

| Type | Convention | Example |
|------|-----------|---------|
| Swift source | `PascalCase.swift` (matches type name) | `CameraManager.swift` |
| Markdown docs | `kebab-case.md` | `code-review.md` |
| Screenshots/images | `kebab-case.png` | `live-measurement.png` |
| Config files | Ecosystem convention | `Package.swift`, `project.yml` |
| Root standard files | `UPPERCASE` or ecosystem convention | `README.md`, `LICENSE` |

## Rules

- No spaces in any file or directory name
- No underscores — use hyphens as separators
- No `SCREAMING-CASE` for docs (use `kebab-case.md`, not `CODE-REVIEW.md`)
- Swift files always match their primary type name (`struct CameraManager` → `CameraManager.swift`)
- Never rename directories that tooling depends on (`LightMeter/`, `LightMeterTests/`, `LightMeter.xcodeproj/`)
