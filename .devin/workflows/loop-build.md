---
description: Main build loop — pick next user story from backlog, implement with TDD, verify against acceptance criteria, build, and deploy a working checkpoint to Vercel. Runs continuously until backlog is empty or paused.
---

# Build Loop

**Goal**: Autonomously build a project story-by-story from the PRD backlog. Each completed story produces a working Vercel preview deployment so the human can see progress in real time.

**Readiness Level**: L2 — Assisted (build + test + verify + deploy to preview)

## When to Use

- After `/loop-init` has been run and human setup is complete
- When there are pending stories in the backlog
- When the human wants to walk away and let the loop build

## Prerequisites

The loop checks ALL of these before every cycle. If any fail, the loop aborts and tells the human exactly what to fix.

### Human Setup Check (every cycle)

1. **Read `STATE.md`** — check `STATUS` field. If `PAUSED`, abort immediately.
2. **Check Vercel CLI**: Run `which vercel`. If not found → abort with message: "Install Vercel CLI: `npm i -g vercel`"
3. **Check Vercel auth**: Run `vercel whoami`. If not authenticated → abort with message: "Run `vercel login`"
4. **Check project link**: Look for `.vercel/project.json`. If missing → abort with message: "Run `vercel link` in project root"
5. **Check PRD exists**: Look for `PRD.md` or `docs/prd.md`. If missing → abort with message: "Create a PRD file"
6. **Check git**: Look for `.git/`. If missing → abort with message: "Run `git init`"
7. **Check package manager**: Look for `package-lock.json` or `pnpm-lock.yaml`. If missing → abort with message: "Run `npm install` or `pnpm install`"
8. **Check budget**: Read `loop-budget.md` and `loop-run-log.md`. If daily cap or cycle cap exceeded → abort, set `STATUS: PAUSED`, escalate.

If ALL checks pass → proceed to build cycle.

## Build Cycle Steps

### Step 1: Read State and Budget

- Read `STATE.md` completely
- Read `loop-budget.md` — confirm budget remaining
- Read `loop-run-log.md` — count today's cycles and token spend
- If budget exceeded → abort, log, set `STATUS: PAUSED`
- If 2 consecutive stories failed verification → abort, escalate to human

### Step 2: Pick Next Story

- Read the Build Backlog in `STATE.md`
- Find the next story with `Status: pending` that has all dependencies met
- Selection priority:
  1. Stories with `Priority: high` first
  2. Stories with no dependencies first
  3. Stories with met dependencies next
  4. Stories by ID order (S001 before S002)
- If no pending stories with met dependencies → check if all stories are done
  - If all done → log "backlog complete", set `STATUS: COMPLETE`, exit
  - If stories are blocked → log "all remaining stories blocked", escalate, exit
- Update the story's status to `in-progress` in `STATE.md`
- Update `Current Story` section in `STATE.md`

### Step 3: Read and Understand the Story

- Read the story's acceptance criteria carefully
- Read any related stories that are dependencies (to understand context)
- Read the PRD section that describes this feature
- Read existing codebase to understand current architecture and conventions
- Identify which files will need to be created or modified
- Check if any denylist paths will be touched — if so, escalate to human

### Step 4: Write Tests First (TDD)

- Write tests that validate each acceptance criterion
- Tests must be specific and testable — not vague
- Test structure:
  - Unit tests for individual functions/components
  - Integration tests for feature workflows
  - Edge case tests for boundary conditions
- Run the tests — they should ALL FAIL (since the feature isn't implemented yet)
- If tests pass before implementation → tests are wrong, rewrite them
- Record test count in STATE.md

### Step 5: Implement the Feature

- Implement the minimum code to make all tests pass
- Follow existing project conventions (naming, structure, patterns)
- Do NOT add features beyond the acceptance criteria
- Do NOT refactor unrelated code
- Do NOT touch denylist paths (auth, payments, secrets, infra, migrations) without human approval
- Keep changes minimal and focused

### Step 6: Run Full Test Suite

- Run the ENTIRE test suite, not just the new tests
- All tests must pass — both new and existing
- If existing tests break → fix the issue or revert if the break is intentional
- Run linter and type checker
- Record results: `X tests written, Y tests passing, Z tests failing`

### Step 7: Verifier Sub-Agent

- Spawn a **separate verifier** using the `/loop-verifier` workflow
- The verifier receives:
  - The story's acceptance criteria
  - The list of changed files
  - The test results
  - The git diff
- The verifier independently checks:
  - Each acceptance criterion is met
  - Tests actually test the right things (not just passing)
  - No unrelated files changed
  - No denylist paths touched
  - Code follows project conventions
  - No obvious bugs or edge cases missed
- Verifier returns: `APPROVED`, `REJECTED`, or `NEEDS_REVISION`

### Step 8: Handle Verification Result

**If APPROVED** → proceed to Step 9

**If NEEDS_REVISION**:
- Read verifier feedback
- Make the specific changes requested
- Re-run tests
- Re-run verifier
- Increment attempt counter
- If attempt count reaches 3 → escalate, mark story as `failed`, move to next story or pause

**If REJECTED**:
- Read verifier reasoning
- If the issue is fundamental (wrong approach) → start fresh from Step 3
- If the issue is fixable → attempt fix, re-run tests, re-run verifier
- Increment attempt counter
- If attempt count reaches 3 → escalate, mark story as `failed`, move to next story or pause
- If 2 stories in a row fail → pause loop, escalate to human

### Step 9: Build the Project

- Run the project build command (e.g., `npm run build`, `next build`, `pnpm build`)
- If build fails:
  - Read error messages
  - Fix build errors (these are usually straightforward)
  - Re-run build
  - Max 2 build fix attempts, then escalate
- Record build result and duration

### Step 10: Deploy to Vercel

- Run `vercel --prod=false` (preview deployment, NOT production)
- Wait for deployment to complete
- Capture the preview URL from the output
- If deployment fails:
  - Read error messages
  - If it's a config issue → fix and retry (max 2 attempts)
  - If it's an env var issue → escalate to human (they need to set env vars)
  - If it's a build issue → go back to Step 9
- Record the preview URL

### Step 11: Commit and Update State

- Stage all changes: `git add -A`
- Commit with message: `feat: SXXX — <story title>`
- Update `STATE.md`:
  - Mark story status as `deployed`
  - Update Story Status Summary counts
  - Add entry to Deployment History table with preview URL
  - Update Last Known Good Deployment
  - Clear Current Story section (will be set by next cycle)
  - Update `Last run` timestamp
- Append to `loop-run-log.md`:
  - Cycle number
  - Story ID and title
  - Status: deployed
  - Test counts
  - Verifier result
  - Build result
  - Deploy URL
  - Estimated tokens

### Step 12: Post-Cycle Critique

- Record in STATE.md under Post-Run Critique:
  - Any friction encountered during implementation
  - Any tests that were hard to write or required unusual setup
  - Any verifier feedback that was surprising
  - One adjustment for the next cycle
- This helps the loop improve over time

### Step 13: Repeat or Exit

- If budget remaining AND cycles remaining today AND stories pending → go to Step 1
- If budget exhausted → set `STATUS: PAUSED`, log, exit
- If cycle cap reached → log "daily cycle cap reached", exit
- If all stories done → set `STATUS: COMPLETE`, log "backlog complete", exit
- If all remaining stories blocked → escalate, exit

## Rules

- **TDD is mandatory** — write tests first, then implement. No exceptions.
- **The implementer cannot mark its own work done** — verifier is always a separate check.
- **Every story gets deployed** — if it passes verification and builds, it goes to Vercel preview.
- **No production deployments** — preview only. Human promotes to production.
- **No touching denylist paths** without human approval — escalate instead.
- **Max 3 attempts per story** — then escalate and move on or pause.
- **Max 2 consecutive failures** — then pause the entire loop and escalate.
- **Minimal changes** — implement exactly what the acceptance criteria say, nothing more.
- **Follow existing conventions** — match the project's existing code style and patterns.
- **Commit per story** — each completed story gets its own git commit.

## Human Handoff Points

- **Denylist paths touched**: Story requires changes to auth, payments, secrets, infra, or migrations → escalate
- **3 failed attempts**: Story couldn't be completed in 3 tries → escalate with full context
- **2 consecutive failures**: Two stories in a row failed → pause loop, human needs to review
- **Build fails after 2 fix attempts**: Build issue beyond simple fixes → escalate
- **Deploy fails with env var issue**: Human needs to configure Vercel environment variables → escalate
- **All stories blocked**: Remaining stories have unmet dependencies → escalate for human to resolve
- **Backlog complete**: All stories deployed → notify human to review and promote to production

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| Story too large for one cycle | Split into smaller stories during /loop-init; if discovered mid-cycle, implement what fits and note remainder |
| Tests don't actually test the right thing | Verifier checks test quality, not just pass/fail |
| Implementation diverges from PRD intent | Verifier checks against acceptance criteria from PRD |
| Build passes locally but fails on Vercel | Check for env var differences; escalate if env-related |
| Deployment URL not captured | Parse `vercel` CLI output carefully; retry deploy if URL missing |
| Loop runs forever on blocked stories | Early exit when all pending stories have unmet dependencies |
| Token budget exhausted mid-story | Check budget at start of each cycle; if mid-story, save progress in STATE.md and pause |
| Consecutive failures indicate systemic issue | Pause after 2 consecutive failures — human needs to investigate |

## Success Metrics

- Stories deployed per day
- % of stories that pass verification on first attempt
- Time from story start to deployment
- Test coverage growth over time
- Number of escalations per 10 stories
- Human interventions required (target: zero for non-denylist stories)

## What the Human Sees

While the loop runs, the human can:
1. **Check `STATE.md`** — see which story is in progress, what's been deployed, any escalations
2. **Check Vercel dashboard** — see preview deployments appear as stories complete
3. **Check `loop-run-log.md`** — see detailed cycle history with token costs
4. **Click preview URLs** — interact with the actual working app at each checkpoint
5. **Promote to production** — when satisfied with a checkpoint, promote in Vercel dashboard

The human never needs to touch code. They just watch deployments appear and promote when ready.
