# Halo Configuration — Devin AI

> Devin Halo: a loop engine that studies your project, grills you, then builds autonomously.
> Inspired by [cobusgreyling/loop-engineering](https://github.com/cobusgreyling/loop-engineering)
>
> **Setup**: Run `/halo-init` to study your project, verify prerequisites, and generate a customized version of this file.

## Purpose

Halo **builds a project autonomously** — implementing user stories, writing tests, verifying quality, and deploying working checkpoints so the human can see progress in real time. The human sets up prerequisites once, answers Halo's questions, then walks away.

## Human Setup Requirements

Before Halo can run unattended, the human **must** complete a project-specific todo list. `/halo-init` generates this list after studying the project. The loop checks for all items on every run and refuses to proceed if any are missing.

### How Halo Determines What You Need

`/halo-init` detects your deployment platform, tech stack, and required tooling, then generates a checklist. Common items include:

**If Vercel detected:**
- `npm i -g vercel`
- `vercel login`
- `vercel link`
- `vercel env add <VAR>` for each required env var

**If Netlify detected:**
- `npm i -g netlify-cli`
- `netlify login`
- `netlify link`

**If Fly.io detected:**
- `curl -L https://fly.io/install.sh | sh`
- `flyctl auth login`

**If AWS detected:**
- `aws configure`
- Ensure deployment credentials are set

**If Docker detected:**
- Ensure Docker daemon is running
- Ensure registry credentials are configured

**Always required:**
- Git repo initialized
- Package manager lockfile exists
- PRD or design docs exist in repo

### Setup Checklist Template

```
BEFORE YOU WALK AWAY — complete this checklist:

[ ] 1. <platform CLI install command>  (detected by Halo)
[ ] 2. <platform auth command>  (detected by Halo)
[ ] 3. <platform link command>  (detected by Halo)
[ ] 4. <design docs / PRD> exist in repo
[ ] 5. git init && git add -A && git commit -m "initial"
[ ] 6. <package manager install command>
[ ] 7. <env var setup commands>  (one per required var)
[ ] 8. git remote add origin <url>  (if using GitHub)
[ ] 9. Run /halo-init to verify everything is ready
[ ] 10. Run /halo-build to start building

After step 10, you can walk away. Check your deployment platform for checkpoints.
```

## Active Loops

| Pattern | Cadence | Status | Workflow | Purpose |
|---------|---------|--------|----------|---------|
| Build | Continuous | L2 assisted | `/halo-build` | Implement stories, test, verify, deploy checkpoints |
| Triage | 1d | L1 report-only | `/halo-triage` | Monitor build health, deployment status, coverage |
| CI Sweeper | 15m | L1 report-only | `/halo-ci-sweeper` | Catch build/deploy failures quickly |
| Verifier | On-demand | Active | `/halo-verifier` | Maker/checker for every story before deploy |

## Build-Deploy Checkpoint Cycle

```
Pick next story from backlog
  → Read acceptance criteria
  → Implement feature (TDD: write tests first, then code)
  → Run full test suite
  → Verifier sub-agent checks against acceptance criteria
  → If REJECTED → revise and retry (max 3 attempts)
  → If APPROVED → build project
  → If build succeeds → deploy checkpoint (preview/staging, NOT production)
  → Record deployment URL in STATE.md
  → Commit with story reference
  → Update STATE.md: mark story done, pick next
  → Repeat
```

## Readiness Levels

| Level | Description | What's Active |
|-------|-------------|---------------|
| **L0 — Draft** | PRD ingested, backlog generated, nothing built | — |
| **L1 — Report** | Triage only, no building | Triage + CI Sweeper |
| **L2 — Assisted** | Build + test + verify + deploy checkpoints | ✅ Current — all loops active |
| **L3 — Unattended** | Full autonomy including PR creation and merge | Future |

## Human Gates

- **No auto-merge to production** — Halo deploys previews, human promotes
- **No skipping tests** — every story must pass full test suite before deploy
- **No skipping verification** — every story must pass `/halo-verifier` before deploy
- All high-risk paths require human review even in preview:
  - `auth/` — authentication and authorization
  - `payments/` — billing and payment processing
  - `secrets/` — API keys, credentials, env files
  - `infra/` — infrastructure and deployment config
  - `migrations/` — database migrations
- Max 3 implementation attempts per story before escalation
- If 2 stories in a row fail verification → pause and escalate to human

## Deployment Strategy

- **Every completed story** → deploy to preview/staging (never production)
- **Preview URL** recorded in `STATE.md` so human can check progress
- **Production deployment** → human promotes when satisfied
- **Rollback** → if a deployment breaks something, Halo reverts to last known good commit and redeploys
- **Platform-agnostic** — Halo uses whatever deployment platform it detected during init

## Budget

- Max sub-agent spawns per build cycle: 2 (implementer + verifier)
- Max tokens/day: 2M (build loop is token-intensive)
- Max build cycles/day: 20 (safety cap to prevent runaway)
- Append each cycle to `halo-run-log.md`
- Check `halo-budget.md` at start and end of each cycle
- **Kill switch**: Set `STATUS: PAUSED` in `STATE.md` or delete workflow files

## Maker / Checker Split

- The agent that writes code **cannot** mark its own work "done"
- A separate verifier sub-agent must confirm:
  - All acceptance criteria from the user story are met
  - All tests pass (unit + integration)
  - No unrelated files were touched
  - Build succeeds
  - No denylist paths touched without human approval
- See `/halo-verifier` workflow

## Links

- State: [`STATE.md`](./STATE.md)
- Budget: [`halo-budget.md`](./halo-budget.md)
- Run log: [`halo-run-log.md`](./halo-run-log.md)
- Source: [loop-engineering patterns](https://github.com/cobusgreyling/loop-engineering)
