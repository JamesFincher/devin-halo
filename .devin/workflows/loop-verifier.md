---
description: Verifier sub-workflow — maker/checker split. A separate agent verifies that a story implementation meets all acceptance criteria, passes tests, and is ready to deploy. The implementer cannot mark its own work done.
---

# Loop Verifier (Maker / Checker Split)

**Goal**: Provide independent verification that a user story implementation meets all acceptance criteria, passes all tests, and is ready for deployment. The agent that wrote the code cannot judge its own work.

**When to use**: Called by `/loop-build` after implementation and testing, before build and deploy.

## When to Use

This workflow is invoked by `/loop-build` when:
- A story has been implemented with tests
- The implementation needs independent verification before deployment
- The loop is at L2 (Assisted) or L3 (Unattended) readiness

**Never** skip verification. An unverified story is an unattended mistake.

## Prerequisites

- A story has been implemented with tests
- The story's acceptance criteria are available (from STATE.md backlog)
- The project has a test suite and lint configuration
- `LOOP.md` exists with denylist paths defined
- The git diff of changes is available

## Inputs

The verifier receives from `/loop-build`:
1. **Story ID and title**
2. **Acceptance criteria** — the checklist from the story definition
3. **List of changed files** — from `git diff --name-only`
4. **Test results** — which tests pass and fail
5. **PRD context** — the relevant section of the PRD for this story

## Steps

### Step 1: Read the Story Requirements

- Read the story's acceptance criteria from `STATE.md`
- Read the relevant PRD section for full context
- Read any dependency stories to understand expected interfaces
- Understand what "done" means for this story — it's the acceptance criteria, not more, not less

### Step 2: Check Each Acceptance Criterion

For EACH acceptance criterion:
- Can you confirm it's implemented by reading the code?
- Can you confirm it's tested by reading the tests?
- Can you confirm the test actually tests the criterion (not just passes)?

Record per-criterion:
```
Criterion 1: "User can register with email and password"
  - Implemented: YES — RegistrationForm.tsx, /api/auth/register
  - Tested: YES — registration.test.tsx
  - Test quality: GOOD — tests valid registration, duplicate email, invalid email
  - Verdict: PASS

Criterion 2: "Password must be at least 8 characters"
  - Implemented: YES — validation in RegistrationForm.tsx
  - Tested: YES — registration.test.tsx tests short password rejection
  - Test quality: GOOD — tests boundary (7 chars rejected, 8 accepted)
  - Verdict: PASS

Criterion 3: "User sees success message after registration"
  - Implemented: NO — no success message in RegistrationForm.tsx
  - Tested: NO — no test for success message
  - Verdict: FAIL
```

### Step 3: Review the Diff

- Run `git diff --name-only` to get changed files
- Check each changed file:
  - Is this file related to the story? If unrelated file -> **FAIL**
  - Is the change minimal? If excessive changes -> **WARN**
  - Does it touch denylist paths? If yes -> **FAIL** and escalate
- Check for deleted files — were any deleted intentionally?
- Check for config changes — were any made that aren't related to the story?

### Step 4: Run the Full Test Suite

- Run the ENTIRE test suite (not just the new tests)
- Run linter: `npm run lint` or equivalent
- Run type checker: `npm run typecheck` or equivalent (if configured)
- All must pass
- Record:
  ```
  Test suite: 47 tests — 47 passing, 0 failing
  Lint: passing (0 errors, 0 warnings)
  Type check: passing
  ```

### Step 5: Assess Test Quality

- Are the tests testing the RIGHT things?
- Do tests have meaningful assertions (not just "expect(true).toBe(true)")?
- Are edge cases covered?
- Are error paths tested?
- Would these tests catch a regression?
- If tests are shallow or meaningless -> **NEEDS_REVISION** with specific feedback

### Step 6: Check for Side Effects

- Could this change break anything downstream?
- Are there integration points not covered by tests?
- Does the change affect any existing API contracts?
- Does the change modify shared utilities or components?
- If potential side effects found -> **WARN** and note in report

### Step 7: Check Code Quality

- Does the code follow existing project conventions?
- Is the code readable and maintainable?
- Are there obvious bugs or logic errors?
- Are there security concerns (XSS, injection, etc.)?
- If code quality issues found -> **NEEDS_REVISION** with specific feedback

### Step 8: Produce Verification Report

```
VERIFICATION REPORT
===================
Story: S001 — User registration form
Date: 2026-07-01 14:20 UTC

Acceptance Criteria:
  [PASS] 1. User can register with email and password
  [FAIL] 2. Password must be at least 8 characters
  [PASS] 3. User sees error for duplicate email
  [FAIL] 4. User sees success message after registration

Changed Files:
  - src/components/RegistrationForm.tsx (related)
  - src/app/api/auth/register/route.ts (related)
  - src/tests/registration.test.tsx (related)
  - package.json (unrelated — added unused dependency)

Test Suite: 47 tests — 45 passing, 2 failing
Lint: passing
Type check: passing

Test Quality: GOOD — tests cover valid/invalid inputs, edge cases

Side Effects: None identified

Code Quality: GOOD — follows existing patterns, readable

Denylist: No denylist paths touched

VERDICT: NEEDS_REVISION
NOTES:
  - Acceptance criterion 2: password validation not implemented
  - Acceptance criterion 4: success message not implemented
  - package.json: remove unused dependency added in this change
  - 2 tests failing — likely related to missing criteria 2 and 4
```

### Step 9: Return Verdict

- **APPROVED**: All acceptance criteria pass, all tests pass, no denylist issues, code quality is good -> story can proceed to build and deploy
- **NEEDS_REVISION**: Some criteria not met or test quality issues, but the approach is correct -> implementer can fix and retry (up to 3 attempts)
- **REJECTED**: Fundamental approach is wrong, or denylist paths touched -> implementer must start over or escalate to human

### Step 10: Log Verification

- Append to `loop-run-log.md`:
  - Timestamp
  - Story ID
  - Verdict: APPROVED/REJECTED/NEEDS_REVISION
  - Criteria pass/fail summary
  - Test results
  - Notes

## Rules

- **The verifier must be a separate agent session** from the implementer
- **Run the full test suite**, not just the new tests
- **Check EVERY acceptance criterion** — partial implementation is not acceptable
- **Check test quality** — tests that pass but don't test the right thing are useless
- **No denylist paths without human approval** — this is non-negotiable
- **NEEDS_REVISION is limited** — max 3 attempts per story, then escalate
- **The verifier does not fix things** — it only verifies and provides feedback
- **Be specific in feedback** — "criterion 3 not met" is not enough; say exactly what's missing

## Denylist Paths

The following paths require human review regardless of verification outcome:
- `**/auth/**` — authentication and authorization
- `**/payments/**` — billing and payment processing
- `**/secrets/**` — API keys, credentials, env files
- `**/infra/**` — infrastructure and deployment config
- `**/migrations/**` — database migrations
- `**/*.env*` — environment files
- `**/security/**` — security-related code

Projects can customize this list in `LOOP.md`.

## Failure Modes & Mitigations

| Failure | Mitigation |
|---------|------------|
| Verifier rubber-stamps implementations | Verifier must be separate session; must check each criterion individually |
| Tests pass but don't test the right thing | Step 5 explicitly checks test quality, not just pass/fail |
| Infinite revision loop | Max 3 attempts, then escalate to human |
| Verifier too strict, blocks all stories | Track approval rate; if >80% rejection, review criteria with human |
| Denylist bypassed | Hard check — any denylist path = automatic REJECT + escalate |
| Acceptance criteria too vague | /loop-init should generate specific, testable criteria; flag vague criteria in report |
| Verifier adds scope | Verifier only checks against stated criteria — no scope creep |
