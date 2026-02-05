# /review — Composite Code Review

Run the appropriate reviewer agents based on the mode and stack.

## Usage

- `/review plan` — Review a plan/feature description before coding. Produces a requirements checklist.
- `/review code` — Review actual code changes. Produces a violation report.
- `/review code backend` — Limit code review to backend reviewers only.
- `/review code frontend` — Limit code review to frontend reviewers only.

## Mode: `plan`

**When**: Before coding starts. The user has a feature description or plan draft.

**What it does**: Launches a single agent using `@agents/plan-requirements-reviewer.md`. This agent reads the feature description / plan, detects the stack, and produces a requirements checklist — things the plan must address before implementation begins. No code scanning.

**Behavior**:
1. Read the user's feature description or plan draft from context.
2. Launch one Task agent with `subagent_type: "general-purpose"` using the prompt from `@agents/plan-requirements-reviewer.md`, passing the feature description and any plan content.
3. Return the checklist directly.

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

   **For backend code**, launch two parallel agents:
   - One with the prompt from `@agents/production-hardening-reviewer.md` scoped to the target files
   - One with the prompt from `@agents/audit-compliance-reviewer.md` scoped to the target files

   **For frontend/mobile code**, launch one agent:
   - With the prompt from `@agents/analytics-coverage-reviewer.md` scoped to the target files

4. **Merge results**: Combine the outputs from all agents into a single report.

## Output Format

### Plan mode

```
# Plan Review: [Feature Name]

## Stack: [Backend / Frontend / Full Stack]

## Requirements to Address

### [Category]
- ⚠️ **[Requirement]**: Why it applies and what the plan should specify
- ✅ **[Requirement]**: Already addressed in the plan

## Summary
- **Missing from plan**: N items
- **Already covered**: N items
```

### Code mode

```
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

## Analytics Coverage
[Output from analytics-coverage-reviewer]

---

## Summary
- **Critical**: N findings
- **High**: N findings
- **Medium**: N findings
- **Low**: N findings
```
