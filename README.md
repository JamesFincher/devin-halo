# Devin Halo

> A loop engine designed for Devin AI. Language-agnostic, platform-agnostic.
> Point it at any project — design docs, half-built, or production — and Halo
> studies it, grills you, then builds autonomously with deployed checkpoints.

## What This Is

Devin Halo is an autonomous build loop for Devin AI. It doesn't just prompt — it **studies your project deeply, asks you the right questions, and then builds story-by-story with TDD, independent verification, and deployed checkpoints** you can watch in real time.

It works with:
- **Design docs only** — a PRD and an empty folder
- **Half-built projects** — existing code that needs features completed
- **Production codebases** — established projects that need new work

It detects your tech stack, build system, test runner, deployment platform, and risk areas — then fine-tunes the loop accordingly. Vercel? Netlify? AWS? Railway? No deployment at all? Halo adapts.

## Quick Start

### 1. Install Halo

```bash
git clone https://github.com/JamesFincher/devin-halo.git ~/code/Halo
```

### 2. Open Your Project in Devin

Open any project folder in Windsurf/Devin. The project can be:
- Empty with just a `PRD.md` or design docs
- Half-built with existing code
- A mature codebase that needs new features

### 3. Run Halo Init

```
/halo-init
```

Halo will:
1. **Install** workflow files into your project's `.devin/workflows/`
2. **Study** your codebase exhaustively — architecture, conventions, patterns, tech stack
3. **Detect** your deployment platform (Vercel, Netlify, AWS, Railway, Fly.io, none, etc.)
4. **Grill you** — ask targeted questions about requirements, priorities, edge cases, and constraints
5. **Verify** prerequisites — CLI tools, auth, env vars, git, package manager
6. **Generate** a user story backlog with specific, testable acceptance criteria
7. **Fine-tune** the loop configuration based on everything it learned
8. **Print** your todo list — exactly what you need to do before walking away

### 4. Complete Your Todo List

Halo gives you a personalized checklist. Typical items might include:
- `npm i -g vercel` (if Vercel detected)
- `vercel login && vercel link` (if Vercel detected)
- `vercel env add DATABASE_URL` (for each missing env var)
- `pip install -r requirements.txt` (if Python detected)
- `flyctl auth login` (if Fly.io detected)

### 5. Start the Build Loop

```
/halo-build
```

**Walk away.** Halo builds story-by-story:
- Writes tests first (TDD)
- Implements the minimum code to pass
- Runs the full test suite
- Spawns a **separate verifier** to check against acceptance criteria
- Builds and deploys a checkpoint to your platform
- Records the deployment URL in `STATE.md`
- Picks the next story and repeats

### 6. Watch Progress

- Check your deployment platform for preview URLs appearing as stories complete
- Check `STATE.md` for progress, escalations, and deployment history
- Promote checkpoints to production when you're satisfied
- Respond to escalations — Halo pauses and tells you exactly what it needs

## How Halo Studies Your Project

The `/halo-init` workflow is deliberately thorough. It doesn't just skim — it deep-dives:

### Codebase Archaeology
- Reads your entire directory structure
- Identifies language, framework, package manager, test runner, linter
- Reads config files (package.json, pyproject.toml, Cargo.toml, go.mod, etc.)
- Reads existing conventions (AGENTS.md, CLAUDE.md, .cursorrules, CONTRIBUTING.md)
- Examines existing code patterns, naming conventions, file organization
- Checks git history for commit patterns and project maturity

### Deployment Detection
- Scans for Vercel (`.vercel/`, `vercel.json`)
- Scans for Netlify (`netlify.toml`, `.netlify/`)
- Scans for AWS (`.aws/`, `serverless.yml`, `samconfig.toml`)
- Scans for Railway (`railway.json`)
- Scans for Fly.io (`fly.toml`)
- Scans for Docker (`Dockerfile`, `docker-compose.yml`)
- Scans for GitHub Pages, Cloudflare Pages, Render, Heroku
- If none found → asks the user what platform they use (or if they deploy at all)

### Risk Assessment
- Scans for auth, payments, secrets, infrastructure, migrations, security directories
- Builds a denylist that always requires human review
- Detects sensitive file patterns (`.env*`, `*credentials*`, `*secret*`)

### The Grill

Halo asks you questions. Not generic questions — **specific questions based on what it found** in your project:

- "I see you're using Next.js 14 with App Router. Should new features follow the Server Component pattern I see in `app/dashboard/`?"
- "Your PRD mentions user authentication. I see no auth library installed. Should I use NextAuth, Clerk, or something else?"
- "I found `STRIPE_SECRET_KEY` referenced in your code but not in your Vercel env vars. Do you need Stripe for this build?"
- "Your existing tests use Vitest. Should I follow the same pattern for new tests?"
- "I see 3 open issues tagged 'bug'. Should I prioritize fixes over new features?"
- "Your PRD mentions real-time features. Are you using WebSockets, Server-Sent Events, or polling?"

The answers fine-tune the loop. Halo remembers everything you tell it in `STATE.md`.

## Repository Structure

```
devin-halo/
├── .devin/workflows/
│   └── halo-init.md              # Installer + deep study + grill + backlog generation
├── templates/workflows/
│   ├── halo-build.md             # Main build loop (installed into target project)
│   ├── halo-verifier.md          # Maker/checker verification (installed)
│   ├── halo-triage.md            # Daily health report (installed)
│   └── halo-ci-sweeper.md        # CI + deployment failure scanning (installed)
├── HALO.md                       # Example loop configuration
├── STATE.md                      # Example state file
├── halo-budget.md                # Example budget config
├── halo-run-log.md               # Example run log
├── .gitignore
├── LICENSE
└── README.md                     # This file
```

## Workflows

| Workflow | Purpose |
|----------|---------|
| `/halo-init` | Install workflows, study project, grill user, verify setup, generate backlog |
| `/halo-build` | Implement stories with TDD, verify, deploy checkpoints |
| `/halo-verifier` | Independent acceptance criteria check (maker/checker split) |
| `/halo-triage` | Daily build health, deployment status, coverage report |
| `/halo-ci-sweeper` | Catch CI/deployment failures between build cycles |

## Readiness Levels

| Level | Description | What's Active |
|-------|-------------|---------------|
| **L0 — Draft** | PRD ingested, backlog generated, nothing built | — |
| **L1 — Report** | Triage only, no building | Triage + CI Sweeper |
| **L2 — Assisted** | Build + test + verify + deploy checkpoints | All loops active |
| **L3 — Unattended** | Full autonomy including PR creation and merge | Future |

## Human Gates

- **No auto-merge to production** — Halo deploys previews, you promote
- **No skipping tests** — every story must pass full test suite
- **No skipping verification** — every story must pass `/halo-verifier`
- **Denylist paths** (auth, payments, secrets, infra, migrations) → always human review
- **Max 3 attempts per story** → then escalate
- **2 consecutive failures** → loop pauses, human must review
- **Kill switch** → set `STATUS: PAUSED` in `STATE.md`

## Tech Stack Support

Halo is language and platform agnostic. It detects and adapts to:

| Category | Detected From | Examples |
|----------|---------------|----------|
| **Language** | Lockfiles, config files | TypeScript, Python, Go, Rust, Ruby, Java, PHP |
| **Framework** | Config files, dependencies | Next.js, Rails, Django, FastAPI, Express, Remix, Astro |
| **Test runner** | Config files, package scripts | Vitest, Jest, pytest, rspec, cargo test, go test |
| **Package manager** | Lockfiles | npm, pnpm, yarn, pip, poetry, cargo, go modules, bundler |
| **CI provider** | CI config dirs | GitHub Actions, GitLab CI, CircleCI, Jenkins |
| **Deployment** | Platform config files | Vercel, Netlify, AWS, Railway, Fly.io, Docker, Render |
| **Linter** | Config files | ESLint, Ruff, RuboCop, Clippy, golangci-lint |

If Halo can't detect something, it asks you.

## The Build-Deploy Checkpoint Cycle

```
Pick next story from backlog
  → Read acceptance criteria
  → Write tests (TDD)
  → Implement the minimum code to pass
  → Run full test suite
  → Verifier sub-agent checks each acceptance criterion independently
  → If REJECTED → revise and retry (max 3 attempts)
  → If APPROVED → build project
  → If build succeeds → deploy checkpoint
  → Record deployment URL in STATE.md
  → Git commit with story reference
  → Pick next story → repeat until backlog empty
```

## Safety

- **Preview only** — Halo never deploys to production without human promotion
- **Denylist enforcement** — auth, payments, secrets, infra always escalated
- **Token budget caps** — configurable per project
- **Rollback** — if a deployment breaks something, Halo reverts to last known good commit
- **Kill switch** — `STATUS: PAUSED` in `STATE.md` stops all loops immediately

## Sources

- [Loop Engineering — Cobus Greyling](https://github.com/cobusgreyling/loop-engineering)
- [Loop Engineering Essay — Addy Osmani](https://addyosmani.com/blog/loop-engineering/)
- [Loop Design Checklist](https://github.com/cobusgreyling/loop-engineering/blob/main/docs/loop-design-checklist.md)

## License

MIT
