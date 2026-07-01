---
description: Daily triage loop — monitor build health, deployment status, test coverage, and backlog progress. Produces a prioritized picture of what needs attention.
---

# Daily Triage Loop

**Goal**: Start each day with a prioritized, actionable picture of build health, deployment status, test coverage, and backlog progress — without manually checking everything yourself.

**Readiness Level**: L1 — Report only (monitors and reports, does not build)

## When to Use

Run this loop:
- At the start of each workday
- After being away from the project for >4 hours
- When you want a status summary of the build loop's progress

## Prerequisites

- `STATE.md` exists in project root
- `LOOP.md` exists with budget and gate configuration
- `loop-budget.md` exists with daily caps
- `loop-run-log.md` exists for append-only logging

## Steps

1. **Read state and budget**
   - Read `STATE.md` — check `STATUS` field. If `PAUSED`, abort and log "loop paused by human".
   - Read `loop-budget.md` — check daily token cap. Sum today's usage from `loop-run-log.md`. If over cap, abort and escalate.
   - Read `LOOP.md` — confirm readiness level and human gates.

2. **Check build loop health**
   - Read `loop-run-log.md` — count build cycles in last 24h
   - Check: are cycles completing successfully or failing?
   - Check: how many stories deployed in last 24h?
   - Check: any stories stuck in `failed` or `blocked` state?
   - Check: any escalations waiting for human?

3. **Check deployment status**
   - Read Deployment History in `STATE.md`
   - Check: is the last known good deployment still accessible?
   - Run: `vercel ls` to see recent deployments
   - Check: any deployments in `ERROR` state?
   - Check: preview URLs still valid?

4. **Check test coverage**
   - Run test suite with coverage if available (e.g. `npm run test -- --coverage`)
   - Compare coverage to previous run (if tracked)
   - Flag: any stories deployed with declining coverage?
   - Flag: any stories with no tests?

5. **Check backlog progress**
   - Read Build Backlog in `STATE.md`
   - Calculate: stories completed / total stories
   - Calculate: estimated remaining cycles
   - Flag: any stories blocked for >24h?
   - Flag: any stories with 2+ failed attempts?

6. **Check for human action items**
   - Read Escalations section in `STATE.md`
   - List all unresolved escalations with age
   - Flag: any escalation older than 24h?
   - List any missing env vars or setup items

7. **Produce triage report** with these sections:

   ### Build Health
   - Cycles in last 24h: X completed, Y failed
   - Stories deployed: X
   - Current story: SXXX (in-progress / idle)
   - Consecutive failures: X (pause if >= 2)

   ### Deployment Status
   - Last deployment: <URL> at <time>
   - Status: healthy / error / unknown
   - Total deployments: X

   ### Test Coverage
   - Current coverage: X%
   - Trend: up/down/stable
   - Stories without tests: list

   ### Backlog Progress
   - Completed: X / Y stories (Z%)
   - Remaining: X stories
   - Est. cycles remaining: X
   - Blocked stories: list

   ### Escalations (human action needed)
   - List each unresolved escalation with age and required action

8. **Update STATE.md**
   - Update `Last run` timestamp
   - Update Post-Run Critique section
   - Do NOT modify story statuses or deployment history (that's the build loop's job)

9. **Log the run**
   - Append entry to `loop-run-log.md` Triage & CI Sweeper Runs table

## Rules

- **Report only** — this loop does not build, deploy, or modify code
- **Do not modify story statuses** — that's the build loop's responsibility
- **Be brutally concise** — the human reading the report wants signal, not noise
- **Flag only actionable items** — don't report on things that are working fine
- **Age escalations** — if an escalation is >24h old, flag it prominently

## Human Handoff Points

- Escalations older than 24h
- Deployments in error state
- Stories blocked for >24h
- Test coverage declining
- Consecutive build failures (>= 2)

## Success Metrics

- Time from "something broke" to "human knows about it"
- Accuracy of status report vs actual project state
- Escalations resolved within 24h
