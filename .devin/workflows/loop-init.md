---
description: Ingest a PRD and auto-generate a customized loop engineering setup tailored to the project's tech stack, risk areas, CI setup, and team workflow. Verifies human prerequisites and generates the story backlog.
---

# Loop Init — PRD Ingest, Setup Verification & Backlog Generation

**Goal**: Read a PRD file from the repo, verify all human prerequisites are met, analyze the project, generate a user story backlog with acceptance criteria, and produce all loop configuration files. After this, the human can run `/loop-build` and walk away.

## When to Use

- Starting a new project that has a PRD
- Onboarding an existing project to loop engineering
- Re-generating loop config after major project changes

## Prerequisites

- A PRD file exists in the repo (e.g. `PRD.md`, `docs/prd.md`, `docs/PRD.md`, `.devin/PRD.md`)

## Inputs

The user provides:
1. **PRD file path** — relative path to the PRD markdown file in the repo

If no path is provided, search for the PRD in this order:
- `PRD.md`
- `docs/prd.md`
- `docs/PRD.md`
- `.devin/PRD.md`
- `README.md` (if it contains PRD-like content)

## The Loop Engine

This workflow system lives at `https://github.com/JamesFincher/loop-engineering` (the "Loop Engine" repo). It contains:
- `templates/workflows/` — workflow templates that get installed into each project
- `.devin/workflows/loop-init.md` — this installer workflow

When you run `/loop-init` in a **new project folder**, it copies the workflow templates from the Loop Engine into your project's `.devin/workflows/` directory. This means every project gets its own copy of the workflows, customized during init.

## Steps

### Phase 0: Install Loop Workflows into Target Project

Before anything else, ensure the target project has the workflow files it needs.

1. **Locate the Loop Engine**
   - Check if the Loop Engine is already cloned locally:
     - Look for `~/code/Loop/templates/workflows/`
     - If found → use that path as the source
   - If not found locally → clone it:
     - Run: `git clone https://github.com/JamesFincher/loop-engineering.git /tmp/loop-engineering`
     - Use `/tmp/loop-engineering/templates/workflows/` as the source
   - If clone fails → abort with message: "Could not clone Loop Engine. Check your network and GitHub access."

2. **Create `.devin/workflows/` in the target project**
   - Run: `mkdir -p .devin/workflows` in the project root

3. **Copy workflow templates into the target project**
   - Copy these files from the Loop Engine's `templates/workflows/` into `.devin/workflows/`:
     - `loop-build.md`
     - `loop-verifier.md`
     - `loop-triage.md`
     - `loop-ci-sweeper.md`
   - Do NOT copy `loop-init.md` — it only needs to exist in the Loop Engine
   - If any workflow file already exists in the target project → ask before overwriting

4. **Verify installation**
   - Check that all 4 workflow files exist in `.devin/workflows/`
   - Print: "Loop workflows installed to .devin/workflows/"

5. **Clean up** (if cloned to /tmp)
   - If the Loop Engine was cloned to `/tmp/loop-engineering`, remove it after copying:
     - Run: `rm -rf /tmp/loop-engineering`

### Phase 1: Verify Human Setup

Before anything else, check that the human has completed all required setup. Report what's missing clearly.

1. **Check Vercel CLI**
   - Run: `which vercel`
   - If not found → add to missing list: "Install Vercel CLI: `npm i -g vercel`"

2. **Check Vercel authentication**
   - Run: `vercel whoami`
   - If not authenticated → add to missing list: "Run `vercel login`"

3. **Check project linked to Vercel**
   - Look for `.vercel/project.json` in repo root
   - If missing → add to missing list: "Run `vercel link` in project root"

4. **Check PRD file exists**
   - Search for PRD file in known locations
   - If missing → add to missing list: "Create a PRD file (PRD.md or docs/prd.md)"

5. **Check git repo initialized**
   - Look for `.git/` directory
   - If missing → add to missing list: "Run `git init`"

6. **Check package manager lockfile**
   - Look for `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`
   - If missing → add to missing list: "Run `npm install` or `pnpm install`"

7. **Report missing requirements**
   - If ANY required items are missing → print:
     ```
     SETUP INCOMPLETE — please complete these before running /loop-build:

     [ ] 1. npm i -g vercel
     [ ] 2. vercel login
     [ ] 3. cd <project> && vercel link
     ...

     Then run /loop-init again to verify.
     ```
   - Update `STATE.md` Human Setup Status checkboxes to reflect what's done vs missing
   - Do NOT proceed to Phase 2 until all required items are met

8. **If all required items pass** → print:
   ```
   SETUP VERIFIED — all required prerequisites are met.
   Proceeding with PRD analysis...
   ```

### Phase 2: Ingest PRD

9. **Read the PRD file**
   - Read the full PRD content
   - Extract these fields (if present, mark as "not specified" if absent):

   ```
   PROJECT_NAME: <project name>
   PROJECT_TYPE: <web app / API / CLI / library / mobile / monorepo / other>
   TECH_STACK:
     - Language: <e.g. TypeScript, Python, Go, Rust>
     - Framework: <e.g. Next.js, FastAPI, Express, React Native>
     - Database: <e.g. PostgreSQL, MongoDB, SQLite, none>
     - Package manager: <e.g. npm, pnpm, yarn, pip, cargo>
   CI_PROVIDER: <e.g. GitHub Actions, GitLab CI, CircleCI, none>
   DEPLOYMENT: <e.g. Vercel, AWS, GCP, self-hosted, none>
   TEAM_SIZE: <e.g. solo, small (2-5), medium (6-15), large (16+)>
   KEY_FEATURES: <bullet list of major features>
   RISK_AREAS: <areas with security, payment, auth, data sensitivity>
   TIMELINE: <e.g. MVP in 2 weeks, production in 3 months>
   INTEGRATIONS: <third-party services, APIs, MCP connectors>
   ENV_VARS_REQUIRED: <list of environment variables the project needs>
   ```

10. **If the PRD is missing fields, infer from codebase** (Phase 3 will fill gaps)

### Phase 3: Analyze Codebase

11. **Detect project structure**
    - List the root directory
    - Identify the package manager from lockfiles:
      - `package-lock.json` → npm
      - `pnpm-lock.yaml` → pnpm
      - `yarn.lock` → yarn
      - `requirements.txt` / `pyproject.toml` / `Pipfile` → pip/poetry
      - `Cargo.toml` → cargo
      - `go.mod` → go modules
    - Identify the framework from config files:
      - `next.config.*` → Next.js
      - `nuxt.config.*` → Nuxt
      - `vite.config.*` → Vite
      - `fastapi` in requirements → FastAPI
      - `express` in package.json → Express
      - `Django` in requirements → Django
      - `Gemfile` with `rails` → Rails
    - Identify the test runner:
      - `vitest` / `jest` / `pytest` / `go test` / `cargo test` / `rspec`
    - Identify the CI provider:
      - `.github/workflows/` → GitHub Actions
      - `.gitlab-ci.yml` → GitLab CI
      - `.circleci/` → CircleCI
      - `Jenkinsfile` → Jenkins

12. **Detect risk areas from directory structure**
    - Scan for directories/files that should be on the denylist:
      - `auth/`, `authentication/`, `**/auth/**`
      - `payment/`, `payments/`, `billing/`, `stripe/`, `**/payment*/**`
      - `secret*/`, `**/*.env*`, `**/credentials/**`
      - `infra/`, `infrastructure/`, `deploy/`, `terraform/`, `**/infra/**`
      - `migration*/`, `db/migrate/`, `**/migration*/**`
      - `security/`, `**/security/**`
    - Record found paths for the denylist

13. **Detect existing conventions**
    - Check for `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.windsurfrules` — read if present
    - Check for existing `CONTRIBUTING.md` — read if present
    - Check for `Makefile` or `package.json` scripts — record build/test/lint commands
    - Check for `.pre-commit-config.yaml` or lint configs (`.eslintrc`, `ruff.toml`, `.rubocop.yml`)

14. **Detect project maturity**
    - Check git log for commit frequency and recency
    - Check for existing tests (count test files)
    - Check for existing CI workflows
    - Classify: `greenfield` (few commits, minimal tests) / `early` (some commits, some tests) / `established` (regular commits, good test coverage) / `legacy` (many commits, inconsistent tests)

### Phase 4: Generate User Story Backlog

15. **Parse PRD into user stories**
    - Read the PRD's feature list, requirements, and user flows
    - Break each feature into one or more user stories
    - Each story must have:
      - **ID**: S001, S002, S003, etc. (ordered by dependency + priority)
      - **Title**: Clear, concise description
      - **Priority**: high / medium / low
      - **Dependencies**: List of story IDs that must be completed first
      - **Acceptance Criteria**: 2–6 specific, testable criteria per story
      - **Estimated complexity**: small / medium / large

16. **Story ordering rules**
    - Foundation/setup stories first (project scaffold, config, database setup)
    - Core domain stories next (main features)
    - Enhancement stories last (polish, edge cases)
    - Stories with dependencies come after their dependencies
    - High-priority stories before low-priority when no dependency constraint

17. **Acceptance criteria rules**
    - Each criterion must be **specific and testable**
    - Each criterion should map to at least one test
    - Avoid vague criteria like "works correctly" — use "renders a form with email and password fields"
    - Include both functional criteria (what it does) and non-functional where relevant (response time, error handling)
    - Bad: "User can register"
    - Good: "User can submit a registration form with email and password, and a new account is created in the database"

18. **Write stories to STATE.md**
    - Populate the Build Backlog section with all stories
    - Update the Story Status Summary table with counts
    - All stories start with `Status: pending`

### Phase 5: Detect Required Environment Variables

19. **Scan PRD for env var requirements**
    - Look for mentions of API keys, database URLs, secrets, third-party services
    - Common patterns:
      - `DATABASE_URL` — if any database is mentioned
      - `AUTH_SECRET` / `JWT_SECRET` — if auth is mentioned
      - `STRIPE_SECRET_KEY` — if Stripe/payments mentioned
      - `OPENAI_API_KEY` — if AI features mentioned
      - `NEXT_PUBLIC_*` — any client-side config
    - List all detected env vars with:
      - Name
      - Description
      - Required vs optional
      - Where to get it (service URL, dashboard link)

20. **Check Vercel env vars**
    - Run: `vercel env ls`
    - Compare detected required vars against what's configured
    - List any missing env vars in the setup report

### Phase 6: Generate Configuration

21. **Generate `LOOP.md`** with:
    - Project name from PRD
    - Purpose statement
    - Human Setup Requirements tables (with project-specific env vars listed)
    - Active loops table (Build + Triage + CI Sweeper + Verifier)
    - Build-Deploy Checkpoint Cycle diagram
    - Readiness level set to L2 (build + test + verify + deploy)
    - Human gates with project-specific denylist paths
    - Budget caps
    - Maker/checker policy

22. **Generate `STATE.md`** with:
    - Project name
    - `STATUS: ACTIVE`
    - Human Setup Status (all checkboxes checked based on Phase 1 results)
    - Build Backlog with all stories from Phase 4
    - Story Status Summary with correct counts
    - Empty Current Story, Deployment History, Escalations sections
    - Project-specific env var checklist

23. **Generate `loop-budget.md`** with:
    - Daily token caps for L2
    - Per-loop budget table
    - Build cycle token breakdown
    - Kill switch instructions
    - Project-specific cost red flags

24. **Generate `loop-run-log.md`** with:
    - Empty build cycle table
    - Empty triage/CI table
    - Empty daily summary table
    - Entry templates

25. **Generate `.devin/workflows/` files** — copy the standard workflow templates but customize:
    - `loop-build.md` — inject project-specific build command, test command, deploy command
    - `loop-triage.md` — inject project-specific scan targets
    - `loop-ci-sweeper.md` — inject CI provider details, test commands
    - `loop-verifier.md` — inject project-specific denylist, test commands, lint commands

26. **Generate `AGENTS.md`** (or update existing) with:
    - Build command (from detected package manager / Makefile)
    - Test command
    - Lint command
    - Project conventions detected from existing files
    - Reference to loop configuration

### Phase 7: Report

27. **Print setup summary**

    ```
    LOOP SETUP COMPLETE — <PROJECT_NAME>
    ====================================

    HUMAN SETUP STATUS:
      [x] Vercel CLI installed
      [x] Vercel authenticated
      [x] Project linked to Vercel
      [x] PRD file exists
      [x] Git repo initialized
      [x] Package manager lockfile exists

      [x] Environment variables: all 5 required vars configured
          - DATABASE_URL (required) — configured
          - AUTH_SECRET (required) — configured
          - STRIPE_SECRET_KEY (optional) — NOT SET
          → Run: vercel env add STRIPE_SECRET_KEY

      [x] GitHub remote connected

    PROJECT PROFILE:
      Type: <type>
      Tech: <language> / <framework>
      Maturity: <greenfield|early|established|legacy>
      Team: <size>
      CI: <provider>
      Deploy: Vercel

    BACKLOG GENERATED:
      Total stories: 15
      High priority: 5
      Medium priority: 7
      Low priority: 3

      Story order:
        S001 — Project scaffold and config (no deps)
        S002 — Database schema and migrations (deps: S001)
        S003 — User model and auth (deps: S002)
        S004 — Landing page (deps: S001)
        ...

    DENYLIST PATHS:
      src/auth/ — authentication
      src/payments/ — billing
      .env.local — environment secrets

    BUDGET:
      Daily cap: 2M tokens
      Max build cycles/day: 20
      Est. tokens per cycle: ~190k
      Est. cycles to complete backlog: ~15

    FILES GENERATED:
      [x] LOOP.md
      [x] STATE.md (with 15 stories)
      [x] loop-budget.md
      [x] loop-run-log.md
      [x] .devin/workflows/loop-build.md
      [x] .devin/workflows/loop-triage.md
      [x] .devin/workflows/loop-ci-sweeper.md
      [x] .devin/workflows/loop-verifier.md
      [x] AGENTS.md

    NEXT STEPS:
      1. Review STATE.md — check story backlog and acceptance criteria
      2. Review LOOP.md — confirm denylist paths and gates
      3. Set any missing env vars: vercel env add <VAR_NAME>
      4. Run /loop-build to start building
      5. Walk away. Check Vercel for deployment previews.
         Each completed story will deploy a new preview.
    ```

28. **Write the summary to `STATE.md`** as the first entry under a `## Setup Notes` section

## Rules

- **Never proceed past Phase 1 if required setup is incomplete** — the loop cannot function without Vercel, git, and a PRD
- **Every story must have specific, testable acceptance criteria** — vague criteria produce vague implementations
- **Stories must be ordered by dependency** — the build loop picks stories in order
- **Only generate workflows for selected loops** — don't create unused workflow files
- **Denylist must include all detected risk paths** — err on the side of caution
- **If PRD conflicts with codebase detection, prefer codebase** — the code is the source of truth
- **Never overwrite existing loop files without confirmation** — if `LOOP.md` already exists, ask before overwriting
- **AGENTS.md must reflect actual commands** — don't guess build/test/lint commands, detect them
- **Budget must match team size and loop count** — don't over-provision for solo devs
- **List ALL required env vars** — the human needs to know exactly what to configure before walking away

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| PRD missing or empty | Search for alternative PRD locations; if none found, abort with clear message |
| Vercel not set up | Phase 1 catches this; print exact commands the human needs to run |
| Env vars not configured | Phase 5 detects missing vars; list them with `vercel env add` commands |
| Codebase empty (true greenfield) | Use PRD-only analysis; first story should be project scaffold |
| Conflicting tech stack signals | Prefer package.json / lockfile evidence over PRD claims |
| Existing loop config found | Ask user before overwriting; offer to merge instead |
| No test runner detected | Note in AGENTS.md "no test runner detected — first story should set up testing" |
| Stories too large | Split stories with >6 acceptance criteria into smaller stories |
| Stories too small | Merge stories with only 1 acceptance criterion into related stories |

## Story Splitting Guidelines

If a story feels too large (more than 6 acceptance criteria or estimated "large" complexity):
- Split along user flow boundaries (e.g. "registration" → "registration form" + "registration API" + "email verification")
- Each split story must be independently deployable
- Each split story must have its own acceptance criteria

If a story feels too small (only 1 acceptance criterion):
- Merge with a related story
- Or expand the criterion into 2-3 more specific criteria
