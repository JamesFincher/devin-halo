# Loop Engineering

> Stop prompting. Design the loop. Build autonomously. Deploy checkpoints.
>
> Based on [cobusgreyling/loop-engineering](https://github.com/cobusgreyling/loop-engineering) — adapted for Devin AI / Windsurf.

## What This Is

A loop engineering system that **builds a project from a PRD autonomously** — implementing user stories with TDD, verifying quality with a maker/checker split, and deploying working checkpoints to Vercel so you can see progress in real time.

You point this engine at any project with a PRD, run `/loop-init`, and the loop installs itself, generates a story backlog, and starts building. You walk away. It deploys.

## Quick Start

### 1. Install the Loop Engine

Clone this repo to your machine:

```bash
git clone https://github.com/JamesFincher/loop-engineering.git ~/code/Loop
```

### 2. Set Up Your Project

In your project folder:

```bash
# Install Vercel CLI and authenticate
npm i -g vercel
vercel login
vercel link

# Initialize git if needed
git init && git add -A && git commit -m "initial"

# Install dependencies (creates lockfile)
npm install
```

### 3. Write Your PRD

Create `PRD.md` in your project root with:
- Project name and description
- Tech stack
- Key features as user stories
- Acceptance criteria for each feature
- Required environment variables
- Risk areas (auth, payments, etc.)

### 4. Run the Loop

Open your project in Windsurf/Devin and run:

```
/loop-init
```

This will:
- **Install** the workflow files into your project's `.devin/workflows/`
- **Verify** all prerequisites (Vercel, git, PRD, env vars)
- **Generate** a user story backlog with testable acceptance criteria
- **Detect** your tech stack, test runner, CI provider, risk areas
- **Create** `LOOP.md`, `STATE.md`, `loop-budget.md`, `loop-run-log.md`
- **Print** a setup summary with next steps

Then start building:

```
/loop-build
```

**Walk away.** Each completed story deploys to Vercel preview. Check `STATE.md` for progress and preview URLs.

## How It Works

### The Build-Deploy Checkpoint Cycle

```
Pick next story from backlog
  → Read acceptance criteria
  → Write tests (TDD — tests must fail first)
  → Implement the minimum code to pass tests
  → Run full test suite (all tests, not just new ones)
  → Verifier sub-agent checks each acceptance criterion independently
  → If REJECTED → revise and retry (max 3 attempts)
  → If APPROVED → build project
  → If build succeeds → deploy to Vercel preview
  → Record preview URL in STATE.md
  → Git commit: "feat: SXXX — story title"
  → Pick next story → repeat until backlog empty
```

### The Five Building Blocks

1. **Scheduling** — Build loop runs continuously, picking stories one at a time
2. **Worktrees** — Isolated working directories for parallel agent work
3. **Skills** — Persistent memory of intent (project conventions, build commands)
4. **Connectors (MCP)** — Let loops read/write tickets, PRs, Slack, databases
5. **Sub-agents (Maker/Checker)** — Separate verifier agent confirms every story before deploy

**Plus Memory/State** — `STATE.md` persists across runs so the loop doesn't have amnesia.

## Repository Structure

```
loop-engineering/
├── .devin/workflows/
│   └── loop-init.md              # Installer + PRD ingest + backlog generation
├── templates/workflows/
│   ├── loop-build.md             # Main build loop (installed into target project)
│   ├── loop-verifier.md          # Maker/checker verification (installed)
│   ├── loop-triage.md            # Daily health report (installed)
│   └── loop-ci-sweeper.md        # CI + Vercel failure scanning (installed)
├── LOOP.md                       # Example loop configuration
├── STATE.md                      # Example state file
├── loop-budget.md                # Example budget config
├── loop-run-log.md               # Example run log
├── .gitignore
└── README.md                     # This file
```

When `/loop-init` runs in a target project, it copies the 4 workflow templates from `templates/workflows/` into the project's `.devin/workflows/` directory and generates project-specific config files.

## Workflows

| Workflow | Purpose | Runs In |
|----------|---------|---------|
| `/loop-init` | Install workflows, verify setup, ingest PRD, generate backlog | Loop Engine (this repo) |
| `/loop-build` | Implement stories with TDD, verify, deploy to Vercel | Target project |
| `/loop-verifier` | Independent acceptance criteria check (maker/checker) | Target project |
| `/loop-triage` | Daily build health, deployment status, coverage report | Target project |
| `/loop-ci-sweeper` | Catch CI/Vercel failures every 15 min | Target project |

## Readiness Levels

| Level | Description | What's Active |
|-------|-------------|---------------|
| **L0 — Draft** | PRD ingested, backlog generated, nothing built | — |
| **L1 — Report** | Triage only, no building | Triage + CI Sweeper |
| **L2 — Assisted** | Build + test + verify + deploy checkpoints | All loops active |
| **L3 — Unattended** | Full autonomy including PR creation and merge | Future |

## Human Gates

- **No auto-merge to production** — loop deploys to Vercel preview, you promote
- **No skipping tests** — every story must pass full test suite before deploy
- **No skipping verification** — every story must pass `/loop-verifier`
- **Denylist paths** (auth, payments, secrets, infra, migrations) → always human review
- **Max 3 attempts per story** → then escalate
- **2 consecutive failures** → loop pauses, human must review
- **Kill switch** → set `STATUS: PAUSED` in `STATE.md`

## Safety

- **Preview only** — loop never deploys to production without human promotion
- **Denylist enforcement** — auth, payments, secrets, infra always escalated to human
- **Token budget caps** — 2M tokens/day, 20 build cycles/day at L2
- **Rollback** — if a deployment breaks something, loop reverts to last known good commit
- **Flaky test handling** — don't "fix" with retries alone, investigate root cause

## What You Need Before Walking Away

| # | Requirement | Command |
|---|-------------|---------|
| 1 | Vercel CLI installed | `npm i -g vercel` |
| 2 | Vercel authenticated | `vercel login` |
| 3 | Project linked to Vercel | `vercel link` |
| 4 | PRD file in repo | Write `PRD.md` |
| 5 | Git initialized | `git init` |
| 6 | Lockfile exists | `npm install` |
| 7 | Env vars configured | `vercel env add <VAR>` |
| 8 | GitHub remote (optional) | `git remote add origin <url>` |

## Sources

- [Loop Engineering — Cobus Greyling](https://github.com/cobusgreyling/loop-engineering)
- [Loop Engineering Essay — Addy Osmani](https://addyosmani.com/blog/loop-engineering/)
- [Loop Design Checklist](https://github.com/cobusgreyling/loop-engineering/blob/main/docs/loop-design-checklist.md)
- [Primitives Reference](https://github.com/cobusgreyling/loop-engineering/blob/main/docs/primitives.md)

## License

MIT
