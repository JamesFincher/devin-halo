---
description: Halo Triage — daily build health, deployment status, test coverage, and backlog progress report. Report only, no building.
---

# Halo Triage Loop

**Goal**: Start each day with a prioritized picture of build health, deployment status, test coverage, and backlog progress.

**Readiness Level**: L1 — Report only

## When to Use

- At the start of each workday
- After being away for >4 hours
- When you want a status summary of the build loop's progress

## Prerequisites

- `STATE.md`, `HALO.md`, `halo-budget.md`, `halo-run-log.md` exist

## Steps

1. **Read state and budget**
   - Read `STATE.md` — if `PAUSED`, abort
   - Read `halo-budget.md` — check daily cap
   - Read `HALO.md` — confirm readiness level

2. **Check build loop health**
   - Read `halo-run-log.md` — count build cycles in last 24h
   - Cycles completing successfully or failing?
   - Stories deployed in last 24h?
   - Stories stuck in `failed` or `blocked`?
   - Escalations waiting for human?

3. **Check deployment status**
   - Read Deployment History in `STATE.md`
   - Is last known good deployment accessible?
   - Check platform for recent deployments (if CLI available):
     - Vercel: `vercel ls`
     - Netlify: `netlify api listSites`
     - Fly.io: `flyctl apps list`
   - Any deployments in ERROR state?

4. **Check test coverage**
   - Run test suite with coverage if available
   - Compare to previous run
   - Flag: stories deployed with declining coverage?
   - Flag: stories with no tests?

5. **Check backlog progress**
   - Read Build Backlog in `STATE.md`
   - Calculate: completed / total, estimated remaining cycles
   - Flag: stories blocked for >24h?
   - Flag: stories with 2+ failed attempts?

6. **Check escalations**
   - List all unresolved escalations with age
   - Flag: any older than 24h?

7. **Produce triage report**:
   - Build Health: cycles, stories deployed, current story, consecutive failures
   - Deployment Status: last deployment URL, status, total deployments
   - Test Coverage: current %, trend, stories without tests
   - Backlog Progress: completed / total, remaining, blocked
   - Escalations: list with age and required action

8. **Update STATE.md** — update `Last run` timestamp and Post-Run Critique
9. **Log the run** — append to `halo-run-log.md`

## Rules

- **Report only** — no building, deploying, or code changes
- **Do not modify story statuses** — that's the build loop's job
- **Be concise** — signal, not noise
- **Flag only actionable items**
- **Age escalations** — >24h = flag prominently
- **Tech-agnostic** — use whatever platform and tools the project uses

## Human Handoff Points

- Escalations older than 24h
- Deployments in error state
- Stories blocked for >24h
- Test coverage declining
- Consecutive build failures (>= 2)
