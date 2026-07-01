# Loop Configuration — Devin AI

> Loop engineering replaces you as the person who prompts the agent — you design the system that does it instead.
> Inspired by [cobusgreyling/loop-engineering](https://github.com/cobusgreyling/loop-engineering)
>
> **Setup**: Run `/loop-init` with a PRD file to auto-generate a customized version of this file for your project.

## Purpose

This loop **builds a project from a PRD autonomously** — implementing user stories, writing tests, verifying quality, and deploying working checkpoints to Vercel so the human can see progress in real time. The human sets up prerequisites once, then walks away.

## Human Setup Requirements

Before the loop can run unattended, the human **must** complete these steps. The loop will check for all of them on every run and refuse to proceed if any are missing.

### Required (loop will not start without these)

| # | Requirement | How to Verify | Human Action |
|---|-------------|---------------|--------------|
| 1 | **Vercel CLI installed** | `which vercel` returns a path | `npm i -g vercel` |
| 2 | **Vercel authenticated** | `vercel whoami` returns a username | `vercel login` |
| 3 | **Project linked to Vercel** | `.vercel/project.json` exists in repo root | `vercel link` in project root |
| 4 | **PRD file exists** | `PRD.md` or `docs/prd.md` found | Write your PRD and commit it |
| 5 | **Git repo initialized** | `.git/` directory exists | `git init` if needed |
| 6 | **Package manager lockfile** | `package-lock.json` or `pnpm-lock.yaml` exists | Run `npm install` or `pnpm install` |

### Project-Specific (depends on PRD — loop-init will detect and list these)

| # | Requirement | How to Verify | Human Action |
|---|-------------|---------------|--------------|
| 7 | **Environment variables set in Vercel** | `vercel env ls` shows required vars | `vercel env add VAR_NAME` for each |
| 8 | **Database provisioned** (if PRD requires) | DB connection string in Vercel env | Provision DB, add connection string |
| 9 | **API keys configured** (if PRD requires) | Keys present in Vercel env | Add each third-party API key |
| 10 | **GitHub repo connected** (if using PRs) | `git remote -v` shows origin | `git remote add origin <url>` |

### Optional (enables more loop capabilities)

| # | Requirement | Enables | Human Action |
|---|-------------|---------|--------------|
| 11 | **Linear MCP connected** | Ticket tracking, story sync | Configure Linear MCP server + API key |
| 12 | **Slack/Discord webhook** | Deployment notifications | Add webhook URL to Vercel env |
| 13 | **Analytics key** (Vercel Analytics) | Performance monitoring | Enable in Vercel dashboard |

### Setup Checklist for the Human

```
BEFORE YOU WALK AWAY — complete this checklist:

[ ] 1. npm i -g vercel
[ ] 2. vercel login
[ ] 3. cd <project> && vercel link
[ ] 4. Write PRD.md (or docs/prd.md) with user stories and acceptance criteria
[ ] 5. git init && git add -A && git commit -m "initial"
[ ] 6. npm install (or pnpm install)
[ ] 7. vercel env add <each required env var>  (loop-init will list these)
[ ] 8. git remote add origin <your-github-url>  (if using GitHub)
[ ] 9. Run /loop-init to verify everything is ready
[ ] 10. Run /loop-build to start building

After step 10, you can walk away. Check Vercel for deployment previews.
```

## Active Loops

| Pattern | Cadence | Status | Workflow | Purpose |
|---------|---------|--------|----------|---------|
| Build | Continuous | L2 assisted | `/loop-build` | Implement stories, test, deploy checkpoints |
| Triage | 1d | L1 report-only | `/loop-triage` | Monitor build health, deployment status, coverage |
| CI Sweeper | 15m | L1 report-only | `/loop-ci-sweeper` | Catch build/deploy failures quickly |
| Verifier | On-demand | Active | `/loop-verifier` | Maker/checker for every story before deploy |

## Build-Deploy Checkpoint Cycle

```
Pick next story from backlog
  → Read acceptance criteria
  → Implement feature (TDD: write tests first, then code)
  → Run full test suite
  → Verifier sub-agent checks against acceptance criteria
  → If REJECTED → revise and retry (max 3 attempts)
  → If APPROVED → build project
  → If build succeeds → deploy to Vercel (preview deployment)
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

- **No auto-merge to production** — loop deploys to Vercel preview, human promotes to production
- **No skipping tests** — every story must pass full test suite before deploy
- **No skipping verification** — every story must pass `/loop-verifier` before deploy
- All high-risk paths require human review even in preview:
  - `auth/` — authentication and authorization
  - `payments/` — billing and payment processing
  - `secrets/` — API keys, credentials, env files
  - `infra/` — infrastructure and deployment config
  - `migrations/` — database migrations
- Max 3 implementation attempts per story before escalation
- If 2 stories in a row fail verification → pause and escalate to human

## Deployment Strategy

- **Every completed story** → deploy to Vercel preview deployment
- **Preview URL** recorded in `STATE.md` so human can check progress
- **Production deployment** → human promotes from preview when satisfied
- **Rollback** → if a deployment breaks something, the loop reverts to last known good commit and redeploys

## Budget

- Max sub-agent spawns per build cycle: 2 (implementer + verifier)
- Max tokens/day: 2M (build loop is token-intensive)
- Max build cycles/day: 20 (safety cap to prevent runaway)
- Append each cycle to `loop-run-log.md`
- Check `loop-budget.md` at start and end of each cycle
- **Kill switch**: Set `STATUS: PAUSED` in `STATE.md` or delete workflow files

## Maker / Checker Split

- The agent that writes code **cannot** mark its own work "done"
- A separate verifier sub-agent must confirm:
  - All acceptance criteria from the user story are met
  - All tests pass (unit + integration)
  - No unrelated files were touched
  - Build succeeds
  - No denylist paths touched without human approval
- See `/loop-verifier` workflow

## Links

- State: [`STATE.md`](./STATE.md)
- Budget: [`loop-budget.md`](./loop-budget.md)
- Run log: [`loop-run-log.md`](./loop-run-log.md)
- Source: [loop-engineering patterns](https://github.com/cobusgreyling/loop-engineering)
- Checklist: [loop-design-checklist](https://github.com/cobusgreyling/loop-engineering/blob/main/docs/loop-design-checklist.md)
