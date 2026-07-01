# Loop State — My Project

STATUS: ACTIVE
Last run: never
Readiness: L2 — Assisted (build + test + verify + deploy checkpoints)

## Human Setup Status

<!-- Checked by every loop run. Loop will not proceed if any REQUIRED item is incomplete. -->

### Required
- [ ] Vercel CLI installed (`which vercel`)
- [ ] Vercel authenticated (`vercel whoami`)
- [ ] Project linked to Vercel (`.vercel/project.json` exists)
- [ ] PRD file exists (`PRD.md` or `docs/prd.md`)
- [ ] Git repo initialized (`.git/` exists)
- [ ] Package manager lockfile exists

### Project-Specific (populated by /loop-init)
- [ ] Environment variables set in Vercel: _(loop-init will list)_
- [ ] Database provisioned: _(if required)_
- [ ] API keys configured: _(if required)_
- [ ] GitHub remote connected: _(if using PRs)_

### Optional
- [ ] Linear MCP connected
- [ ] Slack/Discord webhook configured
- [ ] Vercel Analytics enabled

## Build Backlog

<!-- Stories parsed from PRD by /loop-init. Each story has:
     ID, title, status, acceptance criteria, dependencies, attempt count, deployment URL.

     Status values: pending | in-progress | testing | verified | deployed | blocked | failed
-->

### Story Status Summary

| Status | Count |
|--------|-------|
| Pending | 0 |
| In Progress | 0 |
| Testing | 0 |
| Verified | 0 |
| Deployed | 0 |
| Blocked | 0 |
| Failed | 0 |
| **Total** | 0 |

### Stories

<!-- Format:
#### S001 — Story Title
- **Status**: pending
- **Priority**: high | medium | low
- **Dependencies**: none | S000, S002
- **Acceptance Criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2
- **Attempt**: 0 / 3
- **Deployment URL**: —
- **Notes**: —
-->

## Current Story

<!-- The story the loop is currently working on. Empty when between stories or paused. -->

- **Story ID**: —
- **Status**: idle
- **Started**: —
- **Attempt**: 0 / 3

## Deployment History

<!-- Every successful deployment is recorded here so the human can track progress.
     The most recent deployment is at the top. -->

| Checkpoint | Story | Commit | Preview URL | Deployed At | Status |
|-----------|-------|--------|-------------|-------------|--------|
| — | — | — | — | — | — |

### Last Known Good Deployment

- **Checkpoint**: —
- **Commit**: —
- **Preview URL**: —
- **Deployed at**: —

## Escalations (waiting on human)

<!-- Items the loop cannot resolve on its own. The human must review these. -->

<!-- Format:
### ESC-001 — Short description
- **Story**: S003
- **Reason**: 3 failed verification attempts
- **Details**: Verifier rejected — acceptance criterion 2 not met (form validation missing)
- **Action needed**: Human review of form validation logic
- **Escalated at**: 2026-07-01 14:30 UTC
-->

## Post-Run Critique (from last cycle)

- High-noise: —
- False positives: —
- Friction: —
- Adjustment: —

## Human Overrides

<!-- Record any human decisions that overrode the loop. -->

---

Run log: see `loop-run-log.md`
Budget: see `loop-budget.md`
Config: see `LOOP.md`
