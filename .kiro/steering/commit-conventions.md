---
inclusion: always
---
# Commit Message Conventions

## Categories

| Category | Use When |
|----------|----------|
| `feat` | New feature or functionality |
| `fix` | Bug fix |
| `test` | Adding or updating tests |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation changes |
| `chore` | Project config, dependencies, tooling |
| `style` | Formatting, whitespace, no logic change |

## Commit Message Formats

### Spec Task Commits

Used when committing work tied to a specific spec task.

Format: `[S{XX}_T{YY}_{category}]: one-liner summary`

- `S{XX}` — spec number from the spec folder name (e.g., `01-ios-light-meter-skeleton` → `S01`)
- `T{YY}` — top-level task number only (e.g., task 1 → `T01`, task 3 → `T03`)
- `{category}` — one of the categories above

Example:
```
[S01_T01_feat]: add lux calculator with formula implementation

- Implements calibration constant formula with f/1.6 aperture default
- Returns 0.0 for invalid inputs (zero/negative ISO or exposure)
- Covers requirement 3.2 and 3.4
```

### Non-Task Commits

Used when committing work outside of any spec task.

Format: `[NT_{category}]: one-liner summary`

Example:
```
[NT_chore]: update gitignore for Xcode derived data

- Added DerivedData and xcuserdata patterns
- Prevents build artifacts from being tracked
```

## Rules

- One-liner summary: imperative mood, lowercase after the prefix, no period
- Body: bullet points describing what changed and why, separated from the one-liner by a blank line
- Keep the one-liner under 72 characters (including the prefix)
- Reference requirements or design properties in the body when relevant
