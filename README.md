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

It detects your tech stack, build system, test runner, deployment platform, and risk areas — then fine-tunes the loop accordingly. Vercel? Netlify? AWS? Railway? Fly.io? No deployment at all? Halo adapts.

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
- Check `progress.txt` for a lightweight narrative log of each cycle
- Promote checkpoints to production when you're satisfied
- Respond to escalations — Halo pauses and tells you exactly what it needs

---

## AI Instantiation Instructions

> This section is written for the AI agent (Devin, Claude Code, etc.) that will
> instantiate Halo into a project. If you are a human, follow the Quick Start above.
> If you are an AI reading this README to understand how to set up Halo, follow
> these instructions precisely.

### How to Instantiate Halo in a Project

When a user asks you to set up Halo in their project, follow these steps **in order**:

#### Step 1: Check if Halo is Already Installed

```
Check if .devin/workflows/halo-build.md exists in the current project.
If it does → Halo is already installed. Ask the user if they want to re-run /halo-init.
If it doesn't → proceed to Step 2.
```

#### Step 2: Locate the Halo Engine

```
Check if ~/code/Halo/templates/workflows/ exists.
  If yes → this is the Halo Engine. Use it as the source.
  If no → check if ~/code/Loop/templates/workflows/ exists.
    If yes → use that path.
    If no → clone the Halo Engine:
      git clone https://github.com/JamesFincher/devin-halo.git /tmp/devin-halo
      Use /tmp/devin-halo/templates/workflows/ as the source.
      Clean up with rm -rf /tmp/devin-halo when done.
```

#### Step 3: Install Workflow Files

```
mkdir -p .devin/workflows
Copy these files from the Halo Engine's templates/workflows/ into .devin/workflows/:
  - halo-build.md
  - halo-verifier.md
  - halo-triage.md
  - halo-ci-sweeper.md
Do NOT copy halo-init.md — it only lives in the Halo Engine.
Verify all 4 files exist after copying.
```

#### Step 4: Read the halo-init Workflow

```
Read the halo-init.md workflow file from the Halo Engine.
This file contains the full procedure for studying the project, grilling the user,
verifying prerequisites, and generating the backlog.
Follow its steps precisely.
```

#### Step 5: Execute the halo-init Procedure

Follow the phases defined in `halo-init.md`:

1. **Phase 1: Deep Project Study** — Read the entire codebase. Detect language, framework, test runner, linter, package manager, CI provider, deployment platform, risk areas, project maturity. Read existing conventions (AGENTS.md, CLAUDE.md, .cursorrules, CONTRIBUTING.md). Read the PRD or design docs.

2. **Phase 2: Grill the User** — Ask specific, targeted questions based on what you found. Not generic questions — questions that prove you studied the project. Record all answers in STATE.md under "User Decisions (from the grill)".

3. **Phase 3: Verify Prerequisites** — Check git, package manager, PRD, deployment platform CLI, env vars, GitHub remote. Generate the human's todo list with exact commands. Write it to STATE.md. If anything is missing, print the todo list and stop — do NOT proceed to build until everything is verified.

4. **Phase 4: Generate Story Backlog** — Parse the PRD into user stories. Each story needs: ID, title, priority, dependencies, 2-6 specific testable acceptance criteria, estimated complexity. Order by dependency + priority. Write to STATE.md.

5. **Phase 5: Generate Configuration Files** — Create HALO.md, STATE.md, halo-budget.md, halo-run-log.md, AGENTS.md. All customized based on what you detected.

6. **Phase 6: Report** — Print the full setup summary with project profile, user decisions, setup status, backlog summary, denylist paths, budget, files generated, and the human's todo list.

#### Step 6: Hand Off to the Human

After completing init:
- Print the human's todo list with exact commands
- Tell them to complete the todo list, then run `/halo-build`
- Do NOT start building until the human confirms their todo list is complete

#### Step 7: Build Loop (when human is ready)

When the human says they're ready and runs `/halo-build`:
- Read the `halo-build.md` workflow file
- Follow its steps precisely
- The loop runs continuously: pick story → TDD → test → verify → build → deploy → repeat
- Respect all human gates, budget caps, cycle caps, and the kill switch
- Log everything to `halo-run-log.md` and `progress.txt`

### Important Rules for the AI

- **Study deeply before asking questions** — the grill should show you understand the project
- **Never proceed if required setup is incomplete** — print the todo list and stop
- **Every story must have specific, testable acceptance criteria**
- **The implementer cannot mark its own work done** — always spawn a separate verifier
- **No production deployments** — preview/staging only
- **No touching denylist paths** without human approval
- **Read the last cycle's critique as an instruction** — not just a log
- **Check for no-progress** — if git state is identical to last cycle, halt immediately
- **Log reasoning traces** — record why you made decisions, not just what you did
- **Track failure patterns** — if a story type fails repeatedly, note the pattern and proactively avoid it
- **Be tech-agnostic** — use whatever build/test/lint/deploy commands the project uses
- **If you can't detect something, ask** — don't assume

---

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
│   ├── halo-init.md              # Installer + deep study + grill + backlog generation
│   ├── halo-build.md             # Main build loop (also in templates/)
│   ├── halo-verifier.md          # Maker/checker verification (also in templates/)
│   ├── halo-triage.md            # Daily health report (also in templates/)
│   └── halo-ci-sweeper.md        # CI + deployment failure scanning (also in templates/)
├── templates/workflows/
│   ├── halo-build.md             # Templates copied into target projects by halo-init
│   ├── halo-verifier.md
│   ├── halo-triage.md
│   └── halo-ci-sweeper.md
├── HALO.md                       # Example loop configuration
├── STATE.md                      # Example state file (backlog, deployments, patterns)
├── halo-budget.md                # Example budget config
├── halo-run-log.md               # Example run log (with reasoning traces)
├── halo-runner.sh                # Ralph Loop wrapper script for persistent execution
├── .gitignore
├── LICENSE
└── README.md                     # This file
```

When `/halo-init` runs in a target project, it copies the 4 workflow templates from `templates/workflows/` into the project's `.devin/workflows/` directory and generates project-specific config files.

## Workflows

| Workflow | Purpose |
|----------|---------|
| `/halo-init` | Install workflows, study project, grill user, verify setup, generate backlog |
| `/halo-build` | Implement stories with TDD, verify, deploy checkpoints |
| `/halo-verifier` | Independent acceptance criteria check (maker/checker split) |
| `/halo-triage` | Daily build health, deployment status, coverage report |
| `/halo-ci-sweeper` | Catch CI/deployment failures between build cycles |

## The Ralph Loop Wrapper

`halo-runner.sh` is a persistent wrapper script that keeps the build loop running until the backlog is complete, paused, or an escalation needs human attention.

```bash
# Run in current directory
./halo-runner.sh

# Run in a specific project
./halo-runner.sh /path/to/project
```

The wrapper:
1. Checks `STATE.md` for `STATUS: ACTIVE`
2. Invokes the build workflow (via Devin CLI or IDE — see below)
3. Waits for completion
4. Repeats until `STATUS` is `PAUSED`, `COMPLETE`, or escalations are unresolved
5. Stops immediately on kill switch or safety cap (50 runs)

### Devin CLI Integration

The runner auto-detects the Devin CLI (`devin`) and, when authenticated, invokes workflows non-interactively — enabling fully unattended build loops in terminal/CI contexts without needing the IDE open.

**Two invocation modes:**

| Mode | When | How |
|------|------|-----|
| **CLI mode** | `devin` in PATH + authenticated | `devin --permission-mode accept-edits -p "<workflow prompt>"` |
| **IDE mode** | CLI missing or not authenticated | Logs instructions; user/IDE runs `/halo-build` manually |

**Configuration (environment variables):**

| Variable | Default | Values | Purpose |
|----------|---------|--------|---------|
| `HALO_CLI_MODE` | `auto` | `auto` \| `always` \| `never` | `auto` = use CLI if available, else IDE. `always` = require CLI, fail if not. `never` = always IDE mode. |
| `DEVIN_PERMISSION_MODE` | `accept-edits` | `auto` \| `accept-edits` \| `smart` \| `dangerous` | Controls which tools the CLI auto-approves. `accept-edits` auto-approves read + file edits. |
| `DEVIN_MODEL` | _(unset)_ | e.g. `claude-sonnet-4`, `opus`, `codex` | Optional model override for the build agent. |

**CLI setup (one-time):**

```bash
# 1. Install the Devin CLI (if not already installed)
curl -fsSL https://storage.googleapis.com/devin-public/install.sh | bash

# 2. Authenticate
devin auth login

# 3. Verify
devin auth status   # should show "Logged in"

# 4. Run the wrapper — it will auto-detect and use CLI mode
./halo-runner.sh
```

**Forced CLI mode (fail if CLI unavailable):**

```bash
HALO_CLI_MODE=always ./halo-runner.sh
```

**CI/CD usage (fully unattended):**

```bash
HALO_CLI_MODE=always \
DEVIN_PERMISSION_MODE=accept-edits \
DEVIN_MODEL=claude-sonnet-4 \
./halo-runner.sh /path/to/project
```

> **Safety:** The wrapper respects all workflow gates (budget caps, denylist paths, human gates, no-progress detection) regardless of CLI/IDE mode. The CLI permission mode controls tool-level auto-approval; the workflow's own gates control story-level and cycle-level safety.

## Memory Architecture

Halo uses a tiered memory system to prevent context rot:

| Layer | File | Purpose | Read When |
|-------|------|---------|-----------|
| **Procedural** | `AGENTS.md` | Build/test/lint/deploy commands, conventions | Every cycle start |
| **State** | `STATE.md` | Story backlog, deployments, escalations, user decisions, failure patterns | Every cycle start |
| **Narrative** | `progress.txt` | 2-3 line summary per cycle — lightweight context bridge | Every cycle start |
| **Audit** | `halo-run-log.md` | Full cycle history with reasoning traces, token costs | Budget checks, debugging |
| **Config** | `HALO.md` | Gates, denylist, budget caps, deployment strategy | Every cycle start |

Each cycle starts fresh by reading state from disk — no reliance on chat history. This prevents context rot on long-running sessions.

## Safety Rails

| Rail | What It Does |
|------|-------------|
| **No-progress detection** | If git state is identical between cycles, halts immediately |
| **Budget caps** | 2M tokens/day, 20 cycles/day — pauses when exceeded |
| **Per-story attempt cap** | 3 verification attempts, then escalate |
| **Consecutive failure halt** | 2 stories in a row fail → pause |
| **Denylist enforcement** | Auth, payments, secrets, infra, migrations → always human review |
| **Preview only** | Never deploys to production without human promotion |
| **Kill switch** | `STATUS: PAUSED` in `STATE.md` stops everything |
| **Ralph Loop safety cap** | Wrapper script stops after 50 runs |
| **Failure pattern tracking** | Accumulates patterns to proactively avoid known pitfalls |
| **Actionable critique** | Each cycle's critique is read as an instruction by the next cycle |

## Readiness Levels

| Level | Description | What's Active |
|-------|-------------|---------------|
| **L0 — Draft** | PRD ingested, backlog generated, nothing built | — |
| **L1 — Report** | Triage only, no building | Triage + CI Sweeper |
| **L2 — Assisted** | Build + test + verify + deploy checkpoints | All loops active |
| **L3 — Unattended** | Full autonomy including PR creation and merge | Future |

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

## Sources

- [Loop Engineering — Cobus Greyling](https://github.com/cobusgreyling/loop-engineering)
- [Loop Engineering Essay — Addy Osmani](https://addyosmani.com/blog/loop-engineering/)
- [Loop Design Checklist](https://github.com/cobusgreyling/loop-engineering/blob/main/docs/loop-design-checklist.md)

## License

MIT
