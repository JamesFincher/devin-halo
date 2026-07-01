---
description: CI sweeper loop — scan for failing CI pipelines and Vercel deployment errors, identify root causes, and escalate. Runs between build cycles to catch issues early.
---

# CI Sweeper Loop

**Goal**: Keep CI and Vercel deployments healthy by catching failures quickly. Escalate ambiguous failures with full context to the human.

**Readiness Level**: L1 — Report only (monitors and escalates, does not fix)

## When to Use

Run this loop:
- Every 15 minutes during active building
- On-demand after a deployment failure
- When the build loop reports a failed deployment

## Prerequisites

- `STATE.md` exists in project root
- `LOOP.md` exists with budget and gate configuration
- `loop-budget.md` exists with daily caps
- `loop-run-log.md` exists for append-only logging
- Vercel CLI installed and authenticated

## Steps

1. **Read state and budget**
   - Read `STATE.md` — check `STATUS` field. If `PAUSED`, abort.
   - Read `loop-budget.md` — check daily token cap. If over cap, abort.
   - Read prior CI entries in STATE.md — any known issues?

2. **Check Vercel deployment status**
   - Run: `vercel ls` to list recent deployments
   - Identify any deployments in `ERROR` or `QUEUED` (stuck) state
   - Categorize:
     - **Build error**: Vercel build failed (compilation, missing dependency)
     - **Runtime error**: Deployment built but app crashes on load
     - **Env error**: Missing environment variables
     - **Timeout**: Build took too long
     - **Stuck**: Deployment queued for too long

3. **Check CI pipeline** (if CI provider exists)
   - Check GitHub Actions / GitLab CI / CircleCI for failing workflows
   - Categorize failures:
     - **Build failure**: compilation error
     - **Test failure**: assertion failure, timeout
     - **Lint failure**: style violation, type error
     - **Infra failure**: runner issue, network timeout

4. **Early exit check**
   - If no failures found → log "all green" and exit
   - If only known issues already in STATE.md → log "known issues only" and exit

5. **Triage each failure**:
   - **Build error**: Read Vercel build logs. Is it a code issue or config issue?
   - **Runtime error**: Check browser console errors. Is it a missing env var or code bug?
   - **Env error**: Which env var is missing? Is it in the required list?
   - **Timeout**: Is the build too complex? Is a dependency causing slowness?
   - **CI test failure**: Is the test correct? Is the code under test wrong? Is it flaky?

6. **Update STATE.md**
   - Add new failures to Escalations section with root cause analysis
   - Do NOT modify story statuses (that's the build loop's job)
   - Record any recurring issues

7. **Log the run**
   - Append entry to `loop-run-log.md` Triage & CI Sweeper Runs table

8. **Escalate if needed**
   - Env var issues → human (they need to configure Vercel env)
   - Infra failures → human (not a code issue)
   - Failures touching denylist paths → human
   - Same failure recurring 3+ times → human (deeper issue)
   - Build loop has been paused for >1h due to failures → human

## Rules

- **Report and escalate only** — this loop does not fix or build
- **Do not modify story statuses** — that's the build loop's responsibility
- **Distinguish between code failures and infra failures** — infra is not the loop's job
- **Track recurring issues** — same failure 3+ times = escalate
- **Early exit when all green** — don't burn tokens on no-ops

## Human Handoff Points

- Environment variable issues (human must configure Vercel)
- Infrastructure failures (runner issues, network)
- Failures in auth, payments, secrets, or core infrastructure code
- Same failure recurring 3+ times
- Build loop paused for >1h

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| Loop tries to fix things | This loop is report-only — escalate instead |
| False positive on known issue | Track known issues in STATE.md, skip them |
| Missed failures between runs | Reduce cadence interval |
| Vercel CLI not authenticated | Phase 1 of loop-init should catch this; re-verify |

## Cost Profile

| Scenario | Tokens/run | Notes |
|----------|------------|-------|
| No-op (all green) | ~5k | Exit early |
| Triage pass | ~30k | Scan + classify failures |

**Cadence**: 15m · **Tier**: medium · **Suggested daily cap**: 500k tokens
