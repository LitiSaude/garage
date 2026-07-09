---
name: review
description: Composite review — fan out reviewer agents over a plan (requirements checklist) or code changes (violation report), merge into a single report with a machine-parsed VERDICT line.
---

# /review — Composite Code Review

Run the appropriate reviewer agents based on the mode and stack.

## Usage

- `/review plan [<path>]` — Review a plan/feature description before coding. Produces a requirements checklist. With `<path>`, reviewers read that file directly (used by `/brief`'s review gate).
- `/review code` — Review actual code changes. Produces a violation report.
- `/review code backend` — Limit code review to backend reviewers only.
- `/review code frontend` — Limit code review to frontend reviewers only.

## Mode: `plan`

**When**: Before coding starts. The user has a feature description or plan draft.

**What it does**: Launches three agents in parallel — one for engineering standards (`@agents/plan-requirements-reviewer.md`), one for business/product readiness (`@agents/business-readiness-reviewer.md`), and one for security & threat modeling (`@agents/security-threat-modeling-reviewer.md`). Together they produce a comprehensive review covering technical requirements, business blind spots, and design-level security gaps. No code scanning.

**Behavior**:
1. Locate the plan. If a `<path>` argument was given, the plan is that file — do not paste its contents into the reviewer prompts; instead append to each reviewer prompt: "The plan to review is at `<path>` — read it with the Read tool." (Reviewers reading the file themselves stay fresh-context; a pasted summary would carry this session's framing.) If no path was given, read the user's feature description or plan draft from context and include it in the prompts.
2. Launch three Task agents **in parallel** with `subagent_type: "general-purpose"`:
   - One with the prompt from `@agents/plan-requirements-reviewer.md` (engineering standards)
   - One with the prompt from `@agents/business-readiness-reviewer.md` (business/product readiness)
   - One with the prompt from `@agents/security-threat-modeling-reviewer.md` (security & threat modeling)
3. Merge results into a single report ending with the merged `VERDICT:` line (see Verdict lines below).

## Mode: `code`

**When**: After coding. The user has made changes and wants them reviewed.

**What it does**: Launches specialized reviewer agents in parallel to scan actual code for violations.

**Behavior**:
1. **Determine scope**: Look at the files the user wants reviewed. If no files are specified, use recent git changes (`git diff --name-only HEAD~1`).

2. **Detect stack** (if not explicitly provided):
   - Backend indicators: `.py`, `.go`, `.java`, `.rs` files, `models/`, `api/`, `services/`, `domains/`, `background_jobs/`
   - Frontend/mobile indicators: `.tsx`, `.jsx`, `.ts`, `.js`, `.swift`, `.kt`, `.dart` files, `components/`, `screens/`, `pages/`, `hooks/`
   - If mixed, run all relevant reviewers.

3. **Launch reviewers in parallel** using the Task tool with `subagent_type: "general-purpose"`:

   **For backend code**, launch three parallel agents:
   - One with the prompt from `@agents/production-hardening-reviewer.md` scoped to the target files
   - One with the prompt from `@agents/audit-compliance-reviewer.md` scoped to the target files
   - One with the prompt from `@agents/security-controls-reviewer.md` scoped to the target backend files (backend pillars only)

   **For frontend/mobile code**, launch three parallel agents:
   - One with the prompt from `@agents/production-hardening-reviewer.md` scoped to the target frontend files (frontend pillars only — kill switch, client resilience)
   - One with the prompt from `@agents/analytics-coverage-reviewer.md` scoped to the target files
   - One with the prompt from `@agents/security-controls-reviewer.md` scoped to the target frontend files (frontend pillars only)

   **For mixed stack**, launch all four agents — a single `production-hardening` invocation covering both stacks, `audit-compliance`, `analytics-coverage`, and a single `security-controls-reviewer` invocation that covers both backend and frontend pillars across the full file scope.

4. **Merge results**: Combine the outputs from all agents into a single report ending with the merged `VERDICT:` line (see Verdict lines below).

## Verdict lines

Every reviewer agent ends its output with a machine-parsed `FRAGMENT VERDICT:` line. The merged report ends with a `VERDICT:` line that is the **arithmetic sum of the fragment lines — never re-judged, re-graded, or adjusted by the session merging the report**. The session that requested the review (and may have authored the plan or code under review) does not get to soften the numbers; if a fragment's counts look wrong, re-run that reviewer, don't override it.

- Plan mode: each fragment ends with `FRAGMENT VERDICT: BLOCKING=<n> ADVISORY=<m>`; the merged report ends with `VERDICT: BLOCKING=<n> ADVISORY=<m>` (sums).
- Code mode: each fragment ends with `FRAGMENT VERDICT: CRITICAL=<n> HIGH=<n> MEDIUM=<n> LOW=<n>`; the merged report ends with `VERDICT: CRITICAL=<n> HIGH=<n> MEDIUM=<n> LOW=<n>` (sums).

These lines are consumed by `/brief` (review gate: loop until `BLOCKING=0`) and `/parallel-feature` (garage review gate: pass requires `CRITICAL=0 HIGH=0`). The verdict line must be the last line of the report.

## Output Format

### Plan mode

```text
# Plan Review: [Feature Name]

## Stack: [Backend / Frontend / Full Stack]

## Engineering Requirements

### [Category]
- ⚠️ **[Requirement]**: Why it applies and what the plan should specify
- ✅ **[Requirement]**: Already addressed in the plan

## Business & Product Readiness

### [Pillar Name]
- ⚠️ **[Requirement]**: Why it applies and what the plan should specify
- ✅ **[Requirement]**: Already addressed in the plan

## Security & Threat Model

### [Pillar Name]
- ⚠️ **[Requirement]**: Why it applies and what the plan should specify
- ✅ **[Requirement]**: Already addressed in the plan

## Summary
- **Engineering gaps**: N items
- **Business/product gaps**: N items
- **Security gaps**: N items
- **Already covered**: N items

VERDICT: BLOCKING=<n> ADVISORY=<m>
```

### Code mode

```text
# Code Review Report

## Stack: [Backend / Frontend / Full Stack]
## Files reviewed: [list or summary]

---

## Production Hardening
[Output from production-hardening-reviewer]

---

## Audit Compliance
[Output from audit-compliance-reviewer]

---

## Security Controls
[Output from security-controls-reviewer]

---

## Analytics Coverage
[Output from analytics-coverage-reviewer]

---

## Summary
- **Critical**: N findings
- **High**: N findings
- **Medium**: N findings
- **Low**: N findings

VERDICT: CRITICAL=<n> HIGH=<n> MEDIUM=<n> LOW=<n>
```
