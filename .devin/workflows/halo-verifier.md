---
description: Halo Verifier — maker/checker split. A separate agent verifies that a story implementation meets all acceptance criteria, passes tests, and is ready to deploy. The implementer cannot mark its own work done.
---

# Halo Verifier (Maker / Checker Split)

**Goal**: Independently verify that a user story implementation meets all acceptance criteria, passes all tests, and is ready for deployment.

**When to use**: Called by `/halo-build` after implementation and testing, before build and deploy.

**Never skip verification. An unverified story is an unattended mistake.**

## Prerequisites

- A story has been implemented with tests
- The story's acceptance criteria are available (from STATE.md)
- The project has a test suite and lint configuration
- `HALO.md` exists with denylist paths defined

## Inputs

From `/halo-build`:
1. Story ID and title
2. Acceptance criteria
3. List of changed files (`git diff --name-only`)
4. Test results
5. PRD context for the story

## Steps

### Step 1: Read Story Requirements
- Read acceptance criteria from `STATE.md`
- Read relevant PRD section
- Read dependency stories for interface context

### Step 2: Check Each Acceptance Criterion
For EACH criterion:
- Is it implemented? (read the code)
- Is it tested? (read the tests)
- Does the test actually test the criterion? (not just pass)
- Record per-criterion: PASS / FAIL with details

### Step 3: Review the Diff
- `git diff --name-only` — get changed files
- Each file: related to story? minimal change? denylist path?
- Unrelated file → FAIL
- Denylist path → FAIL and escalate
- Excessive changes → WARN

### Step 4: Run Full Test Suite
- Run the detected test command for the ENTIRE suite
- Run linter
- Run type checker if configured
- All must pass

### Step 5: Assess Test Quality
- Are tests testing the RIGHT things?
- Meaningful assertions? (not just `expect(true).toBe(true)`)
- Edge cases covered?
- Error paths tested?
- Would these catch a regression?
- Shallow tests → NEEDS_REVISION with specific feedback

### Step 6: Check Side Effects
- Could this break anything downstream?
- Uncovered integration points?
- Modified shared utilities or components?
- Potential side effects → WARN

### Step 7: Check Code Quality
- Follows existing project conventions?
- Readable and maintainable?
- Obvious bugs or logic errors?
- Security concerns (XSS, injection, etc.)?
- Issues → NEEDS_REVISION with specific feedback

### Step 8: Produce Verification Report
```
VERIFICATION REPORT
===================
Story: SXXX — <title>
Date: <timestamp>

Acceptance Criteria:
  [PASS/FAIL] 1. <criterion>
  [PASS/FAIL] 2. <criterion>

Changed Files:
  - <file> (related/unrelated)
  ...

Test Suite: <N> tests — <N> passing, <N> failing
Lint: passing/failing
Type check: passing/failing/N/A

Test Quality: GOOD/POOR — <details>
Side Effects: None/<details>
Code Quality: GOOD/POOR — <details>
Denylist: No denylist paths touched / VIOLATION

VERDICT: APPROVED / REJECTED / NEEDS_REVISION
NOTES: <specific feedback>
```

### Step 9: Return Verdict
- **APPROVED** → story can proceed to build and deploy
- **NEEDS_REVISION** → implementer can fix and retry (max 3 attempts)
- **REJECTED** → start over or escalate to human

### Step 10: Log Verification
- Append to `halo-run-log.md`: timestamp, story ID, verdict, criteria summary, test results, notes

## Rules

- **Verifier must be a separate agent session** from the implementer
- **Run the full test suite**, not just new tests
- **Check EVERY acceptance criterion** — partial implementation is not acceptable
- **Check test quality** — passing tests that don't test the right thing are useless
- **No denylist paths without human approval**
- **Max 3 attempts per story**, then escalate
- **Verifier does not fix things** — only verifies and provides feedback
- **Be specific** — "criterion 3 not met" is not enough; say exactly what's missing
- **Tech-agnostic** — use whatever test runner and linter the project uses

## Denylist Paths

Default denylist (customize in HALO.md):
- `**/auth/**` — authentication and authorization
- `**/payments/**` — billing and payment processing
- `**/secrets/**` — API keys, credentials, env files
- `**/infra/**` — infrastructure and deployment config
- `**/migrations/**` — database migrations
- `**/*.env*` — environment files
- `**/security/**` — security-related code

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| Verifier rubber-stamps | Separate session; check each criterion individually |
| Tests pass but don't test right thing | Step 5 explicitly checks test quality |
| Infinite revision loop | Max 3 attempts, then escalate |
| Verifier too strict | Track approval rate; if >80% rejection, review with human |
| Denylist bypassed | Hard check — automatic REJECT + escalate |
| Vague acceptance criteria | Flag in report; /halo-init should generate specific criteria |
