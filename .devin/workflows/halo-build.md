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

## Build Cycle Steps

### Step 1: Read State and Budget
- Read `STATE.md` completely
- Read `halo-budget.md` — confirm budget remaining
- Read `halo-run-log.md` — count today's cycles and token spend
- If budget exceeded → abort, log, set `STATUS: PAUSED`
- If 2 consecutive stories failed verification → abort, escalate to human

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

### Step 4: Write Tests First (TDD)
- Write tests that validate each acceptance criterion
- Tests must be specific and testable
- Include: unit tests, integration tests, edge case tests
- Run tests — they should ALL FAIL (feature not implemented yet)
- If tests pass before implementation → tests are wrong, rewrite
- Record test count in STATE.md

### Step 5: Implement the Feature
- Implement the minimum code to make all tests pass
- Follow existing project conventions (from `STATE.md` Project Profile)
- Do NOT add features beyond acceptance criteria
- Do NOT refactor unrelated code
- Do NOT touch denylist paths without human approval
- Keep changes minimal and focused

### Step 6: Run Full Test Suite
- Run the ENTIRE test suite using the detected test command
- All tests must pass — new and existing
- Run linter using detected lint command
- Run type checker if configured
- Record results

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
- If deployment fails:
    - Config issue → fix and retry (max 2)
    - Env var issue → escalate to human
    - Build issue → go back to Step 9
- Record the preview URL

### Step 11: Commit and Update State
- `git add -A`
- Commit: `feat: SXXX — <story title>`
- Update `STATE.md`:
    - Mark story status as `deployed`
    - Update Story Status Summary counts
    - Add entry to Deployment History with preview URL
    - Update Last Known Good Deployment
    - Clear Current Story section
    - Update `Last run` timestamp
- Append to `halo-run-log.md`: cycle number, story, status, tests, verifier, build, deploy URL, est. tokens

### Step 12: Post-Cycle Critique
- Record in STATE.md: friction, test difficulties, surprising verifier feedback, one adjustment for next cycle

### Step 13: Repeat or Exit
- Budget remaining AND cycles remaining AND stories pending → go to Step 1
- Budget exhausted → set `STATUS: PAUSED`, log, exit
- Cycle cap reached → log "daily cycle cap reached", exit
- All stories done → set `STATUS: COMPLETE`, log, exit
- All remaining blocked → escalate, exit

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

## What the Human Sees

While Halo runs, the human can:
1. **Check `STATE.md`** — current story, deployments, escalations
2. **Check deployment platform** — see checkpoints appear as stories complete
3. **Check `halo-run-log.md`** — detailed cycle history with token costs
4. **Click preview URLs** — interact with the working app at each checkpoint
5. **Promote to production** — when satisfied, promote in platform dashboard
