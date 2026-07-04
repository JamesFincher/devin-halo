---
description: Halo Build Loop — pick next user story, implement with TDD, verify against acceptance criteria, build, and deploy a working checkpoint. Runs continuously until backlog is empty or paused.
---

# Halo Build Loop

**Goal**: Autonomously build a project story-by-story from the backlog. Each completed story produces a working deployment checkpoint so the human can see progress in real time.

**Readiness Level**: L2 — Assisted (build + test + verify + deploy to preview)

## When to Use

- After `/halo-init` has been run and human setup is complete
- When there are pending stories in the backlog
- When the human wants to walk away and let Halo build

## Prerequisites

Halo checks ALL of these before every cycle. If any fail, Halo aborts and tells the human exactly what to fix.

### Human Setup Check (every cycle)

1. **Read `STATE.md`** — check `STATUS` field. If `PAUSED`, abort immediately.
2. **Check git**: `.git/` exists? If not → abort: "Run `git init`"
3. **Check package manager**: lockfile exists? If not → abort: "Run `<install command>`"
4. **Check PRD/design docs**: exists? If not → abort: "Create a PRD or design doc"
5. **Check deployment platform** (if configured):
    - Vercel: `which vercel` + `vercel whoami` + `.vercel/project.json`
    - Netlify: `which netlify` + `netlify status`
    - Fly.io: `which flyctl` + `flyctl auth whoami`
    - Docker: `docker info`
    - (adapt for detected platform)
    - If any check fails → abort with exact command the human needs to run
6. **Check budget**: Read `halo-budget.md` and `halo-run-log.md`. If daily cap or cycle cap exceeded → abort, set `STATUS: PAUSED`.

If ALL checks pass → proceed to build cycle.

### Step 0b: Economic Circuit Breaker
Before starting a new build cycle, run an economic sanity check using the Spend Ledger in `HALO.md`:
1. **Read `halo-run-log.md`** and compute:
   - Running token total (actual) for today — sum `est. tokens` column from today's entries
   - Per-cycle token trajectory — is the last 3-cycles average trending up or down?
   - Cycles since last successful deploy — if ≥ 5, this is a Denial-of-Wallet signal
   - Verifier rejection ratio for last 5 stories — if > 80%, pause
2. **Check each Spend Ledger signal** from `HALO.md`:
   - If any signal is RED (over threshold) → log the specific signal that fired, set `STATUS: PAUSED`, escalate to human with: "Economic circuit breaker triggered: [signal name]. Halo-run-log.md has full details."
3. **Check cost escalation rate**: if per-cycle cost is trending up over 3 consecutive cycles, log a warning and flag in the critique — this may indicate context bloat or increasing story complexity
4. Only proceed to build cycle if ALL economic signals are GREEN


## Execution Architecture: Three-Phase Context Model

Halo-build uses a **Plan → Execute → Verify** three-phase architecture to preserve context
integrity in long-running loops. The build agent's context window is finite; phases let the
agent clear working memory between **qualitatively different kinds of work** while state
persists to disk via `STATE.md`, `halo-run-log.md`, and `progress.txt`.

| Phase | Purpose | Key Artifact | Context Anchor |
|-------|---------|--------------|----------------|
| **PLAN** (Steps 0-3) | Read state, pick story, study codebase | Story + acceptance criteria in working memory | `STATE.md`, `progress.txt` |
| **EXECUTE** (Steps 4-6) | TDD, implement, full test suite | Passing test suite | New tests, changed files |
| **VERIFY** (Steps 7-12) | Verifier, build, deploy, commit, critique | Deployed checkpoint URL | Verifier verdict, git diff |

**Context clearing rules:**
- After each phase, the agent **flushes detailed working memory** and re-reads only the
  minimal state artifacts needed for the next phase.
- PLAN passes the story + acceptance criteria + file list to EXECUTE.
- EXECUTE passes changed files + test results to VERIFY.
- VERIFY writes everything back to disk for the next cycle's PLAN phase.
- This prevents the "lost-in-the-middle" effect (accuracy degrades past ~50K tokens) and
  keeps KV-cache hits high by reusing the same preamble for each phase invocation.

**Token budget per phase:** ~60k (PLAN), ~90k (EXECUTE), ~40k (VERIFY) = ~190k/cycle.
Cycles exceeding this by >20% trigger the Economic Circuit Breaker.

## Build Cycle Steps

### ━━━ PHASE 1: PLAN ━━━

### Step 1: Read State and Budget
- Read `STATE.md` completely
- Read `halo-budget.md` — confirm budget remaining
- Read `halo-run-log.md` — count today's cycles and token spend
- Read `progress.txt` — read the last few lines for narrative context from prior cycles
- Read the **Post-Run Critiques** from the **last 3 cycles** in `STATE.md` — treat them as **instructions for this cycle**, not just logs. The most recent critique is directional ("do X next cycle"); earlier critiques provide compounding context. If critique N-1 said "write validation tests before UI tests" and critique N-2 said "async patterns cause race conditions," both apply. If fewer than 3 cycles exist, read all available.
- Read the **Full Attempt History** section in `STATE.md` — this accumulates every attempt count, retry reason, and verifier feedback across ALL prior cycles. Look for:
  - **Recurring verifier objections** — if the same objection appeared in cycles N-2 and N-1, it's a systemic gap, not a one-off
  - **Escalation patterns** — if 2+ cycles hit the max-attempt wall on stories with similar types, flag it
  - **Compounding friction signals** — increasing token cost across cycles, growing retry counts, shrinking deploy rate
- Read the **Failure Patterns** section in `STATE.md` — match the current story's type against accumulated patterns (by the `Story type:` tag); for each match, note the failure mode and the proven fix so EXECUTE can apply it proactively
- Build a **Pattern Pre-Flight List**: combine matches from all three sources (last 3 critiques + full attempt history + failure patterns). Every matching pattern becomes a concrete pitfall the implementer must actively avoid this cycle. Carry this list into Step 4b.
- If budget exceeded → abort, log, set `STATUS: PAUSED`
- If 2 consecutive stories failed verification → abort, escalate to human

### Step 1b: No-Progress Detection
- Run `git status --porcelain` and `git log --oneline -1` to capture current state
- Compare against the last cycle's recorded git state (from `progress.txt`)
- If the git state is **identical** to the last cycle (same HEAD commit, same working tree) AND no story was deployed last cycle:
- This means the previous cycle made no progress — abort immediately
- Log "no-progress detected — halting to prevent runaway" to `halo-run-log.md`
- Set `STATUS: PAUSED` in `STATE.md`
- Escalate to human: "Halo detected no progress between cycles. Last cycle may have failed silently. Review STATE.md and halo-run-log.md."
- This check prevents the most common weekend disaster: the loop spinning indefinitely without making changes

**⏸️ END PLAN PHASE — flush working memory. Re-read STATE.md, progress.txt on next invocation.**

### Step 2: Pick Next Story
- Read the Build Backlog in `STATE.md`
- Find next `Status: pending` story with all dependencies met
- Selection priority: high priority first, no deps first, by ID order
- If no pending stories with met dependencies:
  - All done → set `STATUS: COMPLETE`, log "backlog complete", exit
  - Stories blocked → log "all remaining stories blocked", escalate, exit
- Update story status to `in-progress` in `STATE.md`
- Update `Current Story` section

### Step 3: Read and Understand the Story
- Read the story's acceptance criteria
- Read related dependency stories for context
- Read the PRD section for this feature
- Read existing codebase to understand architecture and conventions
- Read `AGENTS.md` for build/test/lint commands
- Identify files to create or modify
- Check denylist paths — if touched, escalate to human

### ━━━ PHASE 2: EXECUTE ━━━

### Step 4: Write Tests First (TDD)
- Write tests that validate each acceptance criterion
- Tests must be specific and testable
- Include: unit tests, integration tests, edge case tests
- Run tests — they should ALL FAIL (feature not implemented yet)
- If tests pass before implementation → tests are wrong, rewrite
- Record test count in STATE.md

### Step 4b: Apply Pattern Pre-Flight List
- For each pattern from the **Pattern Pre-Flight List** (Step 1), write a test or guard that directly exercises the known failure mode before implementing the feature:
  - If the pattern was "async not awaited," write a test that asserts async behavior
  - If the pattern was "env var missing," assert env presence in setup
  - If the pattern was "form state reset," assert form empties on submit
- This converts accumulated scars into active defense — not "remember to avoid" but "prove it's avoided"
- If no patterns matched this story's type → skip this step silently

### Step 5: Implement the Feature
- Implement the minimum code to make all tests pass
- Follow existing project conventions (from `STATE.md` Project Profile)
- Do NOT add features beyond acceptance criteria
- Do NOT refactor unrelated code
- Do NOT touch denylist paths without human approval
- Keep changes minimal and focused

### Step 6: Run Full Test Suite
- Run the ENTIRE test suite using the detected test command
- **Capture full test output** (stdout + stderr) to `.halo/evidence/test-output-S<NNN>.txt` — this is the raw evidence the verifier inspects, not a pass/fail summary. Truncation hides failures; if the runner emits >50K lines, capture the head + tail with a note.
- All tests must pass — new and existing
- Run linter using detected lint command
- Run type checker if configured
- **If coverage tooling is available**, capture the coverage report to `.halo/evidence/coverage-S<NNN>.txt` (or `.json`) and compute the **coverage delta** vs the last deployed story's baseline (stored at `.halo/evidence/coverage-baseline`). Record: total %, delta %, and per-file coverage for changed files.
- Record results

**⏸️ END EXECUTE PHASE — flush working memory. Re-read changed files list and test results on next invocation.**

### ━━━ PHASE 3: VERIFY ━━━

### Step 7: Verifier Sub-Agent
- Spawn a **separate verifier** using `/halo-verifier`
- Verifier receives: acceptance criteria, changed files, test results, git diff
- Verifier independently checks each criterion, test quality, side effects, code quality
- Returns: `APPROVED`, `REJECTED`, or `NEEDS_REVISION`

### Step 8: Handle Verification Result
- **APPROVED** → proceed to Step 9
- **NEEDS_REVISION** → read feedback, make changes, re-run tests, re-run verifier, increment attempt counter (max 3)
- **REJECTED** → if fixable, attempt fix; if fundamental, start fresh from Step 3; increment attempt counter (max 3)
- If attempt count reaches 3 → escalate, mark story `failed`, move to next or pause
- If 2 stories in a row fail → pause loop, escalate to human

### Step 9: Build the Project
- Run the detected build command (e.g. `npm run build`, `cargo build`, `go build ./...`)
- If build fails: read errors, fix, re-run (max 2 build fix attempts, then escalate)
- Record build result and duration

### Step 10: Deploy Checkpoint
- Run the detected deploy command for PREVIEW/STAGING only (never production):
    - Vercel: `vercel --prod=false`
    - Netlify: `netlify deploy --build`
    - Fly.io: `flyctl deploy --remote-only`
    - Docker: `docker build && docker push` (to staging tag)
    - (adapt for detected platform)
- Wait for deployment to complete
- Capture the preview URL from output
- **Evidence capture**: store the preview URL in `.halo/evidence/deploy-S<NNN>.txt`. If a headless screenshot tool is available (`chromium --headless --screenshot`, `playwright`, `puppeteer`), capture a screenshot of the preview URL to `.halo/evidence/screenshot-S<NNN>.png` and record a visual smoke check (page loads without console error). If no tool is available, note `screenshot: unavailable` in the evidence file — absence is recorded, not silent.
- If deployment fails:
    - Config issue → fix and retry (max 2)
    - Env var issue → escalate to human
    - Build issue → go back to Step 9
- Record the preview URL

### Step 11: Commit and Update State
- `git add -A`
- **Evidence bundling**: if `.halo/evidence/` exists with this story's artifacts, include them in the commit (`git add .halo/evidence/*-S<NNN>.*`) and reference the evidence path in the commit body. Evidence is part of the audit trail, not ephemeral — it ships with the commit so post-hoc review can reconstruct what the verifier saw.
- Commit: `feat: SXXX — <story title>`
- **Coverage baseline rotation**: on successful deploy, update `.halo/evidence/coverage-baseline` with this story's coverage report so the next cycle's delta is computed against the new floor. Rotation happens only on deploy, never on failed verification.
- Update `STATE.md`:
    - Mark story status as `deployed`
    - Update Story Status Summary counts
    - Add entry to Deployment History with preview URL
    - Update Last Known Good Deployment
    - Clear Current Story section
    - Update `Last run` timestamp
- Append to `halo-run-log.md`: cycle number, story, status, tests, verifier, build, deploy URL, est. tokens

### Step 12: Post-Cycle Critique and Pattern Tracking
- Record in STATE.md under Post-Run Critique:
  - Friction encountered during implementation
  - Test difficulties
  - Surprising verifier feedback
  - Token cost (actual) for this cycle — compare to estimate (~190k)
  - Cost trajectory: is this cycle more or less expensive than the last 3 cycles?
  - **One actionable instruction for the next cycle** (e.g. "Next cycle: for form-related stories, write validation tests before UI tests")
  - **Preserve the last 3 critiques** — do not overwrite old ones. If 3+ critiques exist, drop the oldest beyond 3. This keeps the warm-start window populated for Step 1.
- **Append to Full Attempt History** in STATE.md with:
  - Cycle number, story ID, attempt count, verifier verdict chain (e.g., `NEEDS_REVISION → REJECTED → APPROVED`), and the final attempt's token cost
  - This is the structured log that Step 1 reads to detect escalation patterns and recurring objections across cycles
- Append cycle token cost to the Spend Ledger in `halo-run-log.md`
- If the story failed verification at least once before passing, record the failure pattern in STATE.md under Failure Patterns:
  - Pattern: "Story type: <type>, Failure: <what failed>, Fix: <what fixed it>"
  - **Deduplicate first**: scan existing patterns for the same `<type>` AND semantically similar `<Failure>`. If a match exists, increment its **Recurrence** count and update **Last seen** instead of appending a new entry. This prevents the section from becoming a noise log of repeats.
  - **Severity tagging**: mark each pattern `severity: low | medium | high`. `high` = blocked a deploy or required human escalation; `medium` = cost an extra verifier round; `low` = friction only. High-severity patterns are always included in the Pre-Flight List regardless of story-type match.
  - This accumulates over time and helps the implementer proactively avoid known pitfalls
- Append a 2-3 line summary to `progress.txt`:
  ```
  [2026-07-01 14:25 UTC] S001 deployed | 12 tests passing | HEAD: a1b2c3d | No friction | Next: pick S002
  ```
  This is the lightweight narrative bridge — cheap to read, gives instant context

### Step 13: Repeat or Exit
- Budget remaining AND cycles remaining AND stories pending → go to Step 1
- Budget exhausted → set `STATUS: PAUSED`, log, exit
- Cycle cap reached → log "daily cycle cap reached", exit
- All stories done → set `STATUS: COMPLETE`, log, exit
- All remaining blocked → escalate, exit

**⏸️ END VERIFY PHASE — write all state to disk. Next cycle's PLAN phase picks up fresh.**

## Rules

- **TDD is mandatory** — tests first, then implement
- **The implementer cannot mark its own work done** — verifier is always separate
- **Every story gets deployed** — if it passes verification and builds, it deploys
- **No production deployments** — preview/staging only
- **No touching denylist paths** without human approval
- **Max 3 attempts per story** — then escalate
- **Max 2 consecutive failures** — then pause
- **Minimal changes** — implement exactly what acceptance criteria say
- **Follow existing conventions** — match the project's code style
- **Commit per story** — each completed story gets its own git commit
- **Tech-agnostic** — use the build/test/lint/deploy commands detected during init

## Human Handoff Points

- Denylist paths touched → escalate
- 3 failed attempts → escalate with full context
- 2 consecutive failures → pause loop
- Build fails after 2 fix attempts → escalate
- Deploy fails with env var issue → escalate
- All stories blocked → escalate
- Backlog complete → notify human to review and promote to production

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| Story too large for one cycle | Split into smaller stories; implement what fits, note remainder |
| Tests don't test the right thing | Verifier checks test quality, not just pass/fail |
| Build passes locally but fails on platform | Check for env var differences; escalate if env-related |
| Deployment URL not captured | Parse CLI output carefully; retry deploy if URL missing |
| Loop runs forever on blocked stories | Early exit when all pending stories have unmet dependencies |
| Token budget exhausted mid-story | Save progress in STATE.md and pause |
| Consecutive failures indicate systemic issue | Pause after 2 — human investigates |
| No progress between cycles | Step 1b detects identical git state and halts immediately |
| Same failure pattern repeats | Failure Patterns section in STATE.md tracks and helps proactively avoid |
| Critique ignored | Step 1 reads last critique as an instruction, not just a log |
| **Last N=1 context misses compounding failures** | Warm-start now reads last 3 critiques + Full Attempt History — compounding patterns across cycles become visible instead of being lost each cycle |
| **Token cost trending up across cycles** | Economic Circuit Breaker (Step 0b) detects trajectory; flag in critique as context-bloat warning |
| **Denial-of-Wallet — 3 cycles, 2x cost, no deploy** | Step 0b circuit breaker fires → emergency PAUSE before next cycle |
| **Verifier rejection rate > 80% on last 5 stories** | Step 0b detects → pauses loop; systemic quality issue, not budget |
| **No deploy after 5 cycles** | Step 0b tracks cycles-since-deploy → pauses loop; tokens flowing with zero output |
| **Evidence not captured** | Step 6 + Step 10 write raw test output + coverage + deploy evidence to .halo/evidence/; verifier Step 7 blocks APPROVED if artifacts are MISSING |

## What the Human Sees

While Halo runs, the human can:
1. **Check `STATE.md`** — current story, deployments, escalations
2. **Check deployment platform** — see checkpoints appear as stories complete
3. **Check `halo-run-log.md`** — detailed cycle history with token costs
4. **Click preview URLs** — interact with the working app at each checkpoint
5. **Promote to production** — when satisfied, promote in platform dashboard
