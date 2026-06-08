# Review Protocol

A file-based handshake so Antigravity and the Claude reviewer coordinate without a
human relaying messages. The contract is: **the review file is committed on the
feature branch**, both sides read/write it there.

## File

For task `<task-id>` (e.g. `c1`), the review file is:

```
.antigravity/reviews/<task-id>.md
```

It has up to three sections, appended in order: **Request** (Antigravity),
**Verdict** (Claude), and optionally **Re-request** (Antigravity, after changes).

## States

A task moves through: `PENDING → IN_PROGRESS → AWAITING_REVIEW → (APPROVED | CHANGES_REQUESTED) → DONE`.
State is tracked by the presence/content of the sections below — `STATUS.md` is
only updated to `DONE` at merge time (to avoid branch conflicts).

## Step by step

### 1. Antigravity finishes a task

Create `.antigravity/reviews/<task-id>.md` with the **Request** section:

```markdown
# Review: <task-id> — <task title>

## Request
- **Branch:** <branch name>
- **PR:** <url or "n/a">
- **Summary:** <2–4 sentences on what changed and why>
- **Files touched:** <bullet list>
- **How I verified:** <exact build/test commands run + result, e.g. "133 + N tests pass">
- **Acceptance criteria self-check:** <copy each criterion from the plan, mark ✅/❌>
- **Notes / risks / deviations:** <anything the reviewer should scrutinize>

State: AWAITING_REVIEW
```

Commit (`docs: request review for <task-id>`), push the branch, then **STOP**.

### 2. Claude reviews

Claude fetches the branch, reads the diff against `main` + the Request, and appends:

```markdown
## Verdict: APPROVED        <!-- or: CHANGES_REQUESTED -->
- Reviewed by: Claude (reviewing architect)
- <if APPROVED: one-line confirmation + any non-blocking nits>
- <if CHANGES_REQUESTED: a numbered, specific, actionable list>

State: APPROVED              <!-- or: CHANGES_REQUESTED -->
```

Claude commits this to the **same branch** and pushes.

### 3a. On APPROVED

Antigravity:
1. Merges the branch into `main` (squash; conventional-commit title).
2. Updates `STATUS.md`: set the task to `DONE` with the merge commit short-hash.
3. Deletes the feature branch.
4. Starts the next `PENDING` task. Go to step 1.

### 3b. On CHANGES_REQUESTED

Antigravity:
1. Addresses **every** point on the **same branch** (do not open a new branch).
2. Appends a **Re-request** section:

```markdown
## Re-request
- <what changed in response, point by point>
- **Re-verified:** <commands + result>

State: AWAITING_REVIEW
```

3. Pushes and **STOPS**. Claude appends a new Verdict. Repeat until `APPROVED`.

## Rules

- Antigravity never writes a `Verdict`. Claude never writes a `Request`/`Re-request`.
- Never merge without `State: APPROVED` as the latest state line.
- Keep one review file per task. Re-requests append; they don't overwrite.
- If blocked or a plan task is ambiguous, write your question in the **Notes** field
  and set `State: AWAITING_REVIEW` anyway — the reviewer will answer in the Verdict.
