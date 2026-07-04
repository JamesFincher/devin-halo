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

### Step 7: Inspect Collected Evidence
Before the reflection debate, gather and verify the **concrete evidence artifacts** produced by the build cycle. A passing test suite reported by the implementer is a claim; the raw output is the proof.

- **Test output**: read `.halo/evidence/test-output-S<NNN>.txt`. Confirm: (a) the runner reported PASS, (b) the test count matches what the implementer claimed, (c) no warnings were masked as passes, (d) no skipped/pending tests are silently inflating the pass rate. If the file is absent → FAIL: "no raw test output captured — cannot verify claim."
- **Coverage delta**: read `.halo/evidence/coverage-S<NNN>.txt` (if present). Check: (a) total coverage did not drop below the baseline by more than 2 percentage points (a coverage regression is a side effect), (b) per-file coverage for each changed file is >0% (a changed file with 0% coverage means the implementer shipped untested code). If coverage tooling is unavailable, note `coverage: unavailable` and proceed — absence is acceptable, a regression is not.
- **Deploy evidence**: read `.halo/evidence/deploy-S<NNN>.txt`. Confirm the preview URL is recorded and (if a screenshot exists at `.halo/evidence/screenshot-S<NNN>.png`) that a visual smoke check was performed. If the screenshot is marked `unavailable`, note it — do not block.
- **Evidence completeness check**: every acceptance criterion should have at least one corresponding test in the raw output. If a criterion has no test trace → NEEDS_REVISION: "criterion N has no test coverage in captured output."

Record per-evidence-artifact: VERIFIED / REGRESSION / MISSING in the report.

### Step 8: Multi-Agent Reflection Debate
Before issuing a verdict, run a structured adversarial debate with three independent perspectives over the same evidence (diff, tests, acceptance criteria). This catches single-perspective blind spots — a verifier that reasons one way only detects one class of defect. A passing test suite proves the code runs; it does not prove the code is correct.

**Each role is a separate reasoning pass** with a distinct prompt and a distinct failure hypothesis. Run all three before synthesizing the verdict.

#### The Skeptic
Assumes the implementation is **broken**. The burden of proof is on the code.
- Where are the untested code paths? (branch coverage, not line coverage)
- What input crashes, hangs, or silently corrupts data?
- What error is swallowed or logged-but-ignored?
- Which assertion is vacuous? (`expect(true).toBe(true)`, try-catch that returns normally)
- What happy-path test hides a broken edge case?
- What did the implementer assert is "done" that has no test behind it?
- **Verdict**: `BLOCKING_CONCERN` (cite the evidence) or `NO_BLOCKER`

#### The Logician
Verifies **formal correctness** — does the code path logically satisfy each acceptance criterion?
- Trace each criterion through the code to its implementation. Is the chain unbroken end-to-end?
- Are invariants, preconditions, and postconditions documented AND enforced (not just assumed)?
- Any dead code, unreachable branches, or contradictions in control flow?
- Does the type/data contract hold at every boundary (function entry/exit, API edges, module seams)?
- Does the implementation actually fulfill the criterion, or only an adjacent easier one?
- **Verdict**: `PROVEN` or `UNPROVEN` (identify the exact gap)

#### The Creative
Hunts for **what nobody considered** — the unknown unknowns.
- What integration point did no test exercise?
- What happens under load, concurrency, partial failure, or timeout?
- What hidden assumption is the code making about its environment, ordering, or input shape?
- What second-order effect breaks something the story did not touch?
- Is there a simpler design that eliminates this entire class of risk?
- What would a senior engineer reviewing this at 2am flag?
- **Verdict**: `RISK_IDENTIFIED` (with proposed mitigation) or `NO_ADDITIONAL_RISK`

#### Debate Synthesis
Aggregate the three verdicts into a **Reflection Consensus** before producing the report:
1. Collect all findings: `BLOCKING_CONCERN`, `UNPROVEN`, `RISK_IDENTIFIED` entries
2. For each finding, the verifier must **reconcile** it — never dismiss by assertion:
   - **Block** → flow to `NEEDS_REVISION` with the specific debate finding as feedback
   - **Dismiss** → requires a concrete counter-reason (e.g., "path unreachable because guard at line N returns early" — with the line cited), NOT "looks fine"
3. **No rubber-stamping rule**: a concern dismissed without evidence is treated as a failed verification. The dismissal IS the verification — it must be falsifiable.
4. Record the full consensus (each role's verdict + reconciliations) in the report (Step 9)

**Why three roles and not one**: a single verifier's reasoning modality is correlated with its own blind spots (correlated failure — a verification weakness that defeats one line of reasoning defeats all checks sharing that reasoning). The Skeptic catches what the Logician's formalism misses (malicious/edge inputs); the Logician catches what the Skeptic's pessimism skips (clean logical gaps); the Creative catches what both miss (integration and environmental assumptions). Three diverse modalities beat three copies of the same one.

### Step 9: Produce Verification Report
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
Test Output Evidence: .halo/evidence/test-output-S<NNN>.txt — VERIFIED/MISSING
Coverage: <total>% (delta <+/->% vs baseline) — VERIFIED/REGRESSION/UNAVAILABLE
Lint: passing/failing
Type check: passing/failing/N/A

Test Quality: GOOD/POOR — <details>
Side Effects: None/<details>
Code Quality: GOOD/POOR — <details>
Deploy Evidence: .halo/evidence/deploy-S<NNN>.txt — VERIFIED/MISSING | screenshot: VERIFIED/UNAVAILABLE
Denylist: No denylist paths touched / VIOLATION

Reflection Consensus:
  Skeptic:    BLOCKING_CONCERN/NO_BLOCKER — <details>
  Logician:   PROVEN/UNPROVEN — <details>
  Creative:   RISK_IDENTIFIED/NO_ADDITIONAL_RISK — <details>
  Reconciliations: <how each finding was blocked or dismissed-with-evidence>

VERDICT: APPROVED / REJECTED / NEEDS_REVISION
NOTES: <specific feedback>
```

### Step 10: Return Verdict
- **APPROVED** → story can proceed to build and deploy (requires unanimous Reflection Consensus AND evidence artifacts VERIFIED — raw test output present and matched, no coverage regression, deploy evidence captured)
- **NEEDS_REVISION** → implementer can fix and retry (max 3 attempts); include the specific debate findings as feedback
- **REJECTED** → start over or escalate to human

### Step 11: Log Verification
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
- **Run the reflection debate** — the three-role adversarial pass (Step 8) is mandatory before any APPROVED verdict. A verdict without a recorded Reflection Consensus is automatically INVALID and treated as a rubber-stamp.

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
| Single-perspective blind spot | Three diverse roles (Skeptic/Logician/Creative); correlated-failure trap: if two roles share a reasoning modality, redesign one |
| Reflection rubber-stamped | Mandatory Reconciliation clause — dismissals need falsifiable evidence; no-consensus verdict is INVALID |
| Evidence claims without proof | Step 7 inspects raw artifacts (.halo/evidence/) — implementer claims are cross-checked against captured test output, coverage delta, and deploy evidence before APPROVED |
