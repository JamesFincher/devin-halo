# Halo Budget — My Project

## Daily Token Caps

| Level | Daily Cap | Build Cycles | Sub-agent Spawns | Auto-deploy |
|-------|-----------|-------------|-----------------|-------------|
| L1 — Report | 100k | 0 | 0 | No |
| L2 — Assisted | 2M | 20 | 2 per cycle | Yes (preview only) |
| L3 — Unattended | 5M | 50 | 3 per cycle | Yes (preview + PR) |

**Current level**: L2 — Assisted

## Per-Loop Budget

| Loop | Cadence | Est. Tokens/Cycle | Daily Cap | Early Exit |
|------|---------|-------------------|-----------|------------|
| Build | Continuous | ~150k–300k | 2M | Yes — if backlog empty or all stories blocked |
| Verifier | Per story | ~50k | Included in build | N/A |
| Triage | 1d | ~50k | 100k | N/A |
| CI Sweeper | 15m | ~30k | 500k | Yes — if no failures |

## Build Cycle Token Breakdown

| Phase | Est. Tokens | Notes |
|-------|------------|-------|
| Read state + pick story | ~5k | Small context read |
| Write tests (TDD) | ~30k | Test design for acceptance criteria |
| Implement feature | ~80k | Code generation |
| Run test suite | ~5k | Execute + parse results |
| Verifier sub-agent | ~50k | Independent review against criteria |
| Build project | ~5k | Execute build + parse |
| Deploy checkpoint | ~5k | Execute deploy + parse URL |
| Update state + log | ~10k | Write STATE.md + run log |
| **Total per cycle** | **~190k** | One story from start to deployed |

## Kill Switch

To pause all loops:
1. Set `STATUS: PAUSED` in `STATE.md`
2. Or delete the workflow files from `.devin/workflows/`
3. Or set `HALO_KILL_SWITCH=true` in your environment

## Budget Check Protocol

At the **start** of each build cycle:
1. Read this file and `halo-run-log.md`
2. Sum tokens used today (from run log)
3. Count build cycles completed today
4. If over daily cap OR over cycle cap → abort, log "budget exceeded", set `STATUS: PAUSED`
5. If 2 stories in a row failed verification → abort, escalate to human

At the **end** of each build cycle:
1. Append token estimate to `halo-run-log.md`
2. Increment cycle count for today

## Cost Red Flags

- Same story has had 3 implementation attempts → escalate, stop spending
- Build cycle producing >300k tokens consistently → story may be too large, split it
- Verifier rejecting >80% of stories → implementation quality issue, escalate
- Backlog empty but loop still running → early exit not working, investigate
- Deployments failing repeatedly → check platform config, escalate after 2 failures
