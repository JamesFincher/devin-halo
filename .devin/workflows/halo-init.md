---
description: Halo Init — Deep project study, grill the user, detect deployment platform, verify prerequisites, generate story backlog. The installer that makes Halo work with any project.
---

# Halo Init — Study, Grill, Verify & Generate

**Goal**: Study the project exhaustively, ask the user targeted questions, detect the deployment platform, verify all prerequisites, generate a user story backlog with acceptance criteria, and produce all Halo config files. After this, the human completes their todo list and runs `/halo-build`.

## The Halo Engine

This workflow system lives at `https://github.com/JamesFincher/devin-halo`. It contains:
- `templates/workflows/` — workflow templates installed into each project
- `.devin/workflows/halo-init.md` — this installer workflow

When you run `/halo-init` in a project, it copies the workflow templates into your project's `.devin/workflows/` directory, then studies your project and generates a customized configuration.

## When to Use

- Starting a new project with design docs or a PRD
- Onboarding an existing (half-built or mature) project to Halo
- Re-generating Halo config after major project changes

## Prerequisites

- A PRD or design doc exists in the repo (`PRD.md`, `docs/prd.md`, `docs/PRD.md`, `.devin/PRD.md`, or `README.md` with PRD-like content)
- If no PRD exists, Halo will ask the user to describe the project goals before proceeding

## Steps

### Phase 0: Install Halo Workflows

1. **Locate the Halo Engine**
   - Check if Halo is already cloned locally: look for `~/code/Halo/templates/workflows/` or `~/code/Loop/templates/workflows/`
   - If found → use that path as the source
   - If not found → clone: `git clone https://github.com/JamesFincher/devin-halo.git /tmp/devin-halo`
   - Use `/tmp/devin-halo/templates/workflows/` as the source
   - If clone fails → abort: "Could not clone Halo Engine. Check network and GitHub access."

2. **Create `.devin/workflows/` in the target project**
   - `mkdir -p .devin/workflows`

3. **Copy workflow templates**
   - Copy from Halo Engine `templates/workflows/` into `.devin/workflows/`:
     - `halo-build.md`
     - `halo-verifier.md`
     - `halo-triage.md`
     - `halo-ci-sweeper.md`
   - Do NOT copy `halo-init.md` — it only lives in the Halo Engine
   - If any file already exists → ask before overwriting

4. **Verify installation** — check all 4 files exist

5. **Clean up** — if cloned to `/tmp`, remove it: `rm -rf /tmp/devin-halo`

### Phase 1: Deep Project Study

Spend significant time understanding the project. This is not a quick scan — be thorough.

6. **Directory archaeology**
   - List the full directory tree (respecting .gitignore)
   - Identify the project structure: monorepo? single app? library? workspace?
   - Note key directories: src/, app/, lib/, tests/, docs/, config/, etc.

7. **Detect language and framework**
   - Check for lockfiles and config files:
     - `package.json` / `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` → Node.js ecosystem
     - `next.config.*` → Next.js
     - `nuxt.config.*` → Nuxt
     - `vite.config.*` → Vite
     - `remix.config.*` → Remix
     - `astro.config.*` → Astro
     - `svelte.config.*` → SvelteKit
     - `requirements.txt` / `pyproject.toml` / `Pipfile` → Python
     - `Cargo.toml` → Rust
     - `go.mod` → Go
     - `Gemfile` → Ruby
     - `pom.xml` / `build.gradle` → Java
     - `composer.json` → PHP
   - Read the main config file to determine framework version and plugins

8. **Detect test runner**
   - `vitest` in package.json → Vitest
   - `jest` in package.json → Jest
   - `pytest` in requirements/pyproject → pytest
   - `rspec` in Gemfile → RSpec
   - `cargo test` → cargo test
   - `go test` → go test
   - If no test runner found → note "no test runner detected — first story should set up testing"

9. **Detect linter and type checker**
   - `.eslintrc*` / `eslint.config.*` → ESLint
   - `ruff.toml` / `ruff` in pyproject → Ruff
   - `.rubocop.yml` → RuboCop
   - `clippy` in Cargo.toml → Clippy
   - `.golangci.yml` → golangci-lint
   - `tsconfig.json` → TypeScript type checking
   - `mypy.ini` / `mypy` in pyproject → mypy

10. **Detect package manager and record commands**
    - npm → `npm run build`, `npm test`, `npm run lint`
    - pnpm → `pnpm build`, `pnpm test`, `pnpm lint`
    - yarn → `yarn build`, `yarn test`, `yarn lint`
    - pip/poetry → `python -m pytest`, `ruff check .`
    - cargo → `cargo build`, `cargo test`, `cargo clippy`
    - go → `go build ./...`, `go test ./...`
    - bundler → `bundle exec rails test`, `rubocop`

11. **Read existing conventions**
    - Read `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.windsurfrules` if present
    - Read `CONTRIBUTING.md` if present
    - Read `Makefile` or package.json scripts
    - Examine 3-5 existing source files to understand code patterns, naming, structure

12. **Detect CI provider**
    - `.github/workflows/` → GitHub Actions
    - `.gitlab-ci.yml` → GitLab CI
    - `.circleci/` → CircleCI
    - `Jenkinsfile` → Jenkins

13. **Detect deployment platform**
    - `.vercel/` or `vercel.json` → Vercel
    - `netlify.toml` or `.netlify/` → Netlify
    - `fly.toml` → Fly.io
    - `railway.json` or `railway.toml` → Railway
    - `serverless.yml` or `samconfig.toml` → AWS
    - `Dockerfile` or `docker-compose.yml` → Docker (check for registry config)
    - `render.yaml` → Render
    - `Procfile` → Heroku-style
    - `wrangler.toml` → Cloudflare Workers/Pages
    - If none detected → ask the user: "I couldn't detect a deployment platform. Do you use one (Vercel, Netlify, Fly.io, AWS, etc.) or should I skip deployment?"

14. **Detect risk areas**
    - Scan for denylist-worthy directories:
      - `auth/`, `authentication/`, `**/auth/**`
      - `payment/`, `payments/`, `billing/`, `stripe/`
      - `secret*/`, `**/*.env*`, `**/credentials/**`
      - `infra/`, `infrastructure/`, `deploy/`, `terraform/`
      - `migration*/`, `db/migrate/`
      - `security/`, `**/security/**`
    - Record all found paths

15. **Detect project maturity**
    - Check git log: commit count, frequency, recency
    - Check test file count
    - Classify: greenfield / early / established / legacy

16. **Read the PRD / design docs**
    - Read the full PRD or design documents
    - Extract: project name, features, user flows, requirements, constraints
    - If no PRD found → ask the user to describe the project goals

### Phase 2: Grill the User

Ask targeted, specific questions based on what you found. Not generic questions — questions that show you studied the project.

17. **Architecture questions** (ask 2-4):
    - "I see you're using [framework] with [pattern]. Should new features follow the same [pattern] I see in [specific file/dir]?"
    - "Your project structure has [X]. Should I organize new features the same way?"
    - "I see [library X] in your dependencies. Is this your preferred [auth/UI/state] solution, or are you open to alternatives?"

18. **Requirements questions** (ask 2-4):
    - "Your PRD mentions [feature X]. Should this support [edge case Y]?"
    - "I see [feature X] referenced but no [component Y]. Is [component Y] in scope for this build?"
    - "Your PRD lists [X features]. Which are must-haves for the first checkpoint vs nice-to-haves?"

19. **Priority questions** (ask 1-3):
    - "I found [N] open issues/TODOs in the codebase. Should I prioritize fixing these over new features?"
    - "Which feature should be built first — the one users see first, or the one with the most technical risk?"
    - "Is there a deadline or order of operations I should follow?"

20. **Deployment questions** (ask 1-2, if platform detected):
    - "I detected [platform]. Should I deploy every completed story as a preview, or batch them?"
    - "Are there environment variables or secrets I should know about that aren't in the PRD?"

21. **Risk questions** (ask 1-2, if risk areas detected):
    - "I found [auth/payments/secrets] code in [path]. Should I treat this as a denylist path (human review required) or can the loop work on it?"
    - "Are there any areas of the codebase I should never touch without explicit approval?"

22. **Record all answers**
    - Write every Q&A pair to `STATE.md` under "User Decisions (from the grill)"
    - These answers fine-tune the loop's behavior

### Phase 3: Verify Prerequisites

Check that the human has completed all required setup. Report what's missing with exact commands.

23. **Check git**: `.git/` exists? If not → "Run `git init`"
24. **Check package manager**: lockfile exists? If not → "Run `<install command>`"
25. **Check PRD/design docs**: exists? If not → "Create a PRD or design doc"
26. **Check deployment platform CLI** (if platform detected):
    - Vercel: `which vercel` → if missing: "Run `npm i -g vercel`"
    - Vercel auth: `vercel whoami` → if not authed: "Run `vercel login`"
    - Vercel link: `.vercel/project.json` → if missing: "Run `vercel link`"
    - Netlify: `which netlify` → if missing: "Run `npm i -g netlify-cli`"
    - Fly.io: `which flyctl` → if missing: "Install flyctl"
    - Docker: `docker info` → if not running: "Start Docker daemon"
    - (adapt for each platform)
27. **Check environment variables** (if platform detected):
    - List required env vars from PRD analysis
    - Check platform env var list (e.g. `vercel env ls`)
    - Report any missing: "Run `<platform> env add <VAR_NAME>`"
28. **Check GitHub remote** (optional): `git remote -v` → if empty: "Run `git remote add origin <url>`"

29. **Generate the human's todo list**
    - Compile all missing items into a checklist
    - Print it clearly with exact commands
    - Write it to `STATE.md` under "Human Setup Status"
    - If ALL items are complete → print "SETUP VERIFIED — ready to build"

### Phase 4: Generate Story Backlog

30. **Parse PRD into user stories**
    - Break each feature into one or more user stories
    - Each story must have:
      - **ID**: S001, S002, etc. (ordered by dependency + priority)
      - **Title**: Clear, concise
      - **Priority**: high / medium / low (informed by user's grill answers)
      - **Dependencies**: List of story IDs
      - **Acceptance Criteria**: 2-6 specific, testable criteria
      - **Estimated complexity**: small / medium / large

31. **Story ordering rules**
    - Foundation/setup stories first (project scaffold, config, test setup)
    - Core domain stories next
    - Enhancement stories last
    - Stories with dependencies after their dependencies
    - High-priority before low-priority when no dependency constraint
    - Respect user's priority answers from the grill

32. **Acceptance criteria rules**
    - Each criterion must be specific and testable
    - Each criterion should map to at least one test
    - Avoid vague criteria — use concrete, verifiable statements
    - Bad: "User can register"
    - Good: "User can submit a registration form with email and password, and a new account is created in the database"

33. **Write stories to STATE.md**
    - Populate Build Backlog section
    - Update Story Status Summary table

### Phase 5: Generate Configuration Files

34. **Generate `HALO.md`** with:
    - Project name and profile from study
    - Human Setup Requirements (platform-specific)
    - Active loops table
    - Build-Deploy Checkpoint Cycle
    - Readiness level (L2)
    - Human gates with project-specific denylist
    - Budget caps
    - Maker/checker policy

35. **Generate `STATE.md`** with:
    - Project Profile (all detected tech stack info)
    - User Decisions (all grill Q&A)
    - Human Setup Status (todo list)
    - Build Backlog (all stories)
    - Empty Current Story, Deployment History, Escalations sections

36. **Generate `halo-budget.md`** with:
    - Daily token caps for L2
    - Per-loop budget table
    - Build cycle token breakdown
    - Kill switch instructions

37. **Generate `halo-run-log.md`** with:
    - Empty tables with entry templates

38. **Generate `AGENTS.md`** (or update existing) with:
    - Build command (detected)
    - Test command (detected)
    - Lint command (detected)
    - Type check command (if applicable)
    - Deploy command (detected)
    - Project conventions (from study)
    - Reference to Halo config

### Phase 6: Report

39. **Print setup summary**:

```
HALO SETUP COMPLETE — <PROJECT_NAME>
====================================

PROJECT PROFILE:
  Language: <language>
  Framework: <framework>
  Test runner: <test runner>
  Linter: <linter>
  Package manager: <package manager>
  CI: <CI provider or "none">
  Deployment: <platform or "none">
  Maturity: <greenfield|early|established|legacy>

  Build command: <command>
  Test command: <command>
  Lint command: <command>
  Deploy command: <command>

USER DECISIONS (from grill):
  - <Q1>: <A1>
  - <Q2>: <A2>
  ...

HUMAN SETUP STATUS:
  [x] <completed item>
  [ ] <missing item> → Run: <exact command>
  ...

BACKLOG GENERATED:
  Total stories: <N>
  High priority: <N>
  Medium priority: <N>
  Low priority: <N>

  Story order:
    S001 — <title> (no deps)
    S002 — <title> (deps: S001)
    ...

DENYLIST PATHS:
  <list of detected risk paths>

BUDGET:
  Daily cap: 2M tokens
  Max build cycles/day: 20
  Est. tokens per cycle: ~190k

FILES GENERATED:
  [x] HALO.md
  [x] STATE.md (with <N> stories)
  [x] halo-budget.md
  [x] halo-run-log.md
  [x] .devin/workflows/halo-build.md
  [x] .devin/workflows/halo-verifier.md
  [x] .devin/workflows/halo-triage.md
  [x] .devin/workflows/halo-ci-sweeper.md
  [x] AGENTS.md

YOUR TODO LIST:
  [ ] <item 1 with exact command>
  [ ] <item 2 with exact command>
  ...

NEXT STEPS:
  1. Complete your todo list above
  2. Review STATE.md — check story backlog and acceptance criteria
  3. Review HALO.md — confirm denylist paths and gates
  4. Run /halo-build to start building
  5. Walk away. Check <platform> for checkpoint deployments.
```

40. **Write summary to STATE.md** under "Setup Notes"

## Rules

- **Study deeply before asking questions** — the grill should show you understand the project
- **Never proceed if required setup is incomplete** — print the todo list and stop
- **Every story must have specific, testable acceptance criteria**
- **Stories must be ordered by dependency and priority**
- **Denylist must include all detected risk paths**
- **If PRD conflicts with codebase, prefer codebase** — code is truth
- **Never overwrite existing files without confirmation**
- **AGENTS.md must reflect actual detected commands** — never guess
- **List ALL required env vars** — the human needs to know exactly what to configure
- **Be tech-agnostic** — adapt to whatever language/framework/platform the project uses
- **If you can't detect something, ask** — don't assume

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| Halo Engine not found locally | Clone from GitHub to /tmp |
| PRD missing | Ask user to describe project goals; generate PRD from answers |
| No deployment platform detected | Ask user; support "no deployment" mode (build + test only) |
| No test runner detected | First story should set up testing infrastructure |
| Codebase empty (true greenfield) | Use PRD-only; first story is project scaffold |
| Stories too large | Split stories with >6 acceptance criteria |
| User doesn't answer grill questions | Use sensible defaults from codebase analysis; note assumptions in STATE.md |
