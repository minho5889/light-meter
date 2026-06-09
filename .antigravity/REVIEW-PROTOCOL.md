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

**The reviewer owns the merge — Antigravity must NOT merge.** (Changed from the
original flow after the P1 self-approval incident.)

The reviewer (Claude):
1. Squash-merges the branch into `main` (conventional-commit title).
2. Updates `STATUS.md`: sets the task to `DONE` with the merge commit short-hash.
3. Deletes the feature branch from `origin`.

Antigravity, on seeing `State: APPROVED`:
1. Does NOTHING to `main` — no merge, no STATUS edit, no branch delete.
2. Waits until the task shows `DONE` in `STATUS.md` on `main` (reviewer has merged).
3. Then `git pull origin main` and starts the next `PENDING` task. Go to step 1.

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

## HARD STOP — no self-approval (added after a P1 incident)

Antigravity **MUST NOT**, under any circumstances:
- Merge ANY branch into `main`, ever. **The reviewer owns all merges** (see 3a).
  Antigravity only pushes feature branches and waits.
- Author a `## Verdict:` section. Only the reviewer (Claude) writes verdicts.
- Sign a verdict as "User", "User (Approved in chat)", or anything other than the
  reviewer. A chat message from the human is **not** a verdict and never authorizes
  a merge — the verdict must be a reviewer-authored `APPROVED` committed to the
  review file on the branch.
- Edit `STATUS.md` to mark a task `DONE`. The reviewer sets `DONE` when merging.

If a verdict is slow or seems missing: **WAIT.** Do not invent one, do not merge,
do not advance to the next task. Re-push the branch if needed and keep waiting.
A stalled review is the reviewer's problem to fix, never a license to self-approve.
The whole point of this project is independent review; a self-approved merge
defeats it and will be reverted.
