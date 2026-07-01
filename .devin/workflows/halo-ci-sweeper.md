---
description: Halo CI Sweeper — scan for failing CI pipelines and deployment errors between build cycles. Report and escalate, does not fix.
---

# Halo CI Sweeper Loop

**Goal**: Keep CI and deployments healthy by catching failures quickly. Escalate ambiguous failures with full context.

**Readiness Level**: L1 — Report only

## When to Use

- Every 15 minutes during active building
- On-demand after a deployment failure
- When the build loop reports a failed deployment

## Prerequisites

- `STATE.md`, `HALO.md`, `halo-budget.md`, `halo-run-log.md` exist
- Deployment platform CLI installed and authenticated (if platform configured)

## Steps

1. **Read state and budget**
   - Read `STATE.md` — if `PAUSED`, abort
   - Read `halo-budget.md` — check daily cap

2. **Check deployment status**
   - Vercel: `vercel ls` — look for ERROR/QUEUED deployments
   - Netlify: `netlify api listSites` — check deploy status
   - Fly.io: `flyctl status` — check app health
   - Docker: check container status
   - (adapt for detected platform)
   - Categorize: build error, runtime error, env error, timeout, stuck

3. **Check CI pipeline** (if CI provider exists)
   - GitHub Actions: check recent workflow runs
   - GitLab CI: check pipeline status
   - CircleCI: check build status
   - Categorize: build failure, test failure, lint failure, infra failure

4. **Early exit** — if no failures → log "all green", exit

5. **Triage each failure**:
   - Build error: read logs, code or config issue?
   - Runtime error: missing env var or code bug?
   - Env error: which var missing?
   - Timeout: build too complex?
   - CI test failure: test correct? code wrong? flaky?

6. **Update STATE.md** — add to Escalations with root cause analysis
7. **Log the run** — append to `halo-run-log.md`
8. **Escalate if needed**:
   - Env var issues → human
   - Infra failures → human
   - Denylist path failures → human
   - Same failure 3+ times → human
   - Build loop paused >1h → human

## Rules

- **Report and escalate only** — no fixing or building
- **Do not modify story statuses**
- **Distinguish code failures from infra failures**
- **Track recurring issues** — 3+ = escalate
- **Early exit when all green**
- **Tech-agnostic** — use whatever CI and platform the project uses

## Human Handoff Points

- Environment variable issues
- Infrastructure failures
- Failures in denylist paths
- Same failure recurring 3+ times
- Build loop paused for >1h

## Cost Profile

| Scenario | Tokens/run |
|----------|------------|
| No-op (all green) | ~5k |
| Triage pass | ~30k |

**Cadence**: 15m · **Daily cap**: 500k tokens
