# Antigravity — Start Here

This folder is the autonomous development workspace for the LightMeter project.
**Antigravity** does the engineering. **Claude** reviews every change and writes an
approval or change-request. The human stays out of the loop except to launch and
to merge-gate if they choose to.

Read these in order, then begin:

1. [`OPERATING-CONTRACT.md`](OPERATING-CONTRACT.md) — environment, workflow, architecture rules, definition of done. **Non-negotiable.**
2. [`REVIEW-PROTOCOL.md`](REVIEW-PROTOCOL.md) — the exact file-based handshake between Antigravity and the Claude reviewer.
3. The plans, executed in this order:
   - [`plans/01-correctness.md`](plans/01-correctness.md) — Measurement integrity (do first; gates App Review)
   - [`plans/02-performance.md`](plans/02-performance.md) — Performance & architecture
   - [`plans/03-product.md`](plans/03-product.md) — Product & App Store readiness
4. [`STATUS.md`](STATUS.md) — the live task ledger (source of truth for "what's next").

## The one rule that makes this work

**One task → one branch → one PR → STOP and wait for the reviewer's verdict.**

Never start the next task before the current task's review verdict is `APPROVED`.
Never batch multiple tasks into one PR. When in doubt, do less and ask via the
review file.

## The loop, in one breath

```
pick next PENDING task in STATUS.md
  → branch  <plan>/<task-id>-<slug>
  → implement ONLY that task
  → build clean + all tests green (see OPERATING-CONTRACT.md)
  → write .antigravity/reviews/<task-id>.md  (Request section)
  → commit, push branch, open PR
  → set task state to AWAITING_REVIEW in the review file
  → STOP. wait for the reviewer to append a Verdict.
on APPROVED        → DO NOT MERGE. The reviewer owns merges. Wait until the
                     reviewer has merged + marked the task DONE in STATUS.md,
                     then `git pull origin main` and start the next task.
on CHANGES_REQUESTED → fix on the SAME branch, append a Re-request, push, STOP
```

Target end state: an App-Store-ready build. Flicker stays frame-rate-limited but
**honest** (no medical claims). Goal-weighting and decisions live in each plan file.
