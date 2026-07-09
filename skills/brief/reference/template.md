# Brief template

The exact skeleton `/brief` produces. Heading names and table columns are **parser-load-bearing** — `/parallel-feature`, `/review plan`, and `bar-judge` consume them by name. Use repo-relative paths everywhere inside the document; never absolute or machine-specific paths.

```markdown
# Brief: <feature name>

## Goal

## House Rules

## Done Bar

## Posture

## Access & Authority

## Workstreams & Dependency Graph

| ID | Workstream | Repo | Depends on | Linear issue | Checkpoint |
|---|---|---|---|---|---|

## Workstream Specs

### WS-1: <name>

**Objective**:
**Files**:
**Interfaces**:
**Constraints**:
**Verification**:

## Merge Checkpoints

### CP-1: <name>

## Verification

## Review Gate
```

## Section contracts

**Goal** — the outcome, never the steps. One or two paragraphs a stranger could read and know what "built" means. If the Goal reads like an implementation plan, it's wrong.

**House Rules** — bulleted constraints that must hold no matter how the goal is reached (e.g. "no hard-coded special cases in agent prompts — describe behavior and let the agent reason", "never touch the billing tables"). These are copied **verbatim** into every downstream spawn prompt; write them so they make sense with zero surrounding context.

**Done Bar** — a numbered list where every item is checkable by a command or an observable behavior ("`make test` green with new coverage ≥ …", "a stranger completes flow X on staging without help"). No adjectives. `bar-judge` counts an unmeasurable item as a failure of the bar itself. If measurement is unknown, make inventing the measuring stick a workstream.

**Posture** — one line: `routed-build` or `loop`, plus the rationale. Rule of thumb: more than one workstream, cross-repo, or PR ceremony needed → `routed-build` (executed by `/parallel-feature`); a single scoped deliverable with a crisp runnable bar → `loop` (executed by the orchestration skill's loop posture).

**Access & Authority** *(optional — include when it removes friction)* — where credentials live (names/paths, never values), spend budgets, and decisions pre-delegated to the executors so they don't stop to ask ("pick any test fixture library already in the repo").

**Workstreams & Dependency Graph** — the table `/parallel-feature` parses. Exact columns: `| ID | Workstream | Repo | Depends on | Linear issue | Checkpoint |`. `Depends on` lists WS IDs or `—`; `Linear issue` may be `TBD — created at execution` (parallel-feature owns creation); `Checkpoint` names the CP the workstream lands in.

**Workstream Specs** — one `### WS-<n>: <name>` block per table row, carrying the five-part spec contract with bold labels: **Objective** (one paragraph), **Files** (exact paths to create/modify), **Interfaces** (signatures, types, API shapes), **Constraints** (conventions, things not to touch — House Rules travel separately, don't repeat them), **Verification** (the command(s) that prove it works). Each block must be complete enough for a context-free executor: no "as discussed", no references to conversation.

**Merge Checkpoints** — `### CP-<n>: <name>` blocks. Every checkpoint must be **user-testable end-to-end**: state exactly what a tester can observe working once the checkpoint's workstreams land (even if only with the feature flag on), and how (URL, command, flow script). A checkpoint nobody can exercise is a decomposition error — regroup the workstreams.

**Verification** — the end-to-end script `/parallel-feature` runs after the last wave: commands, flows, expected results.

**Review Gate** — written by `/brief` when the gate closes, never by hand. Contains the final review round's summary and ends with one machine-parsed line:

```text
REVIEW GATE: PASSED | round=<n> | BLOCKING=0 | ADVISORY=<m>
```

or, when the user explicitly waives residual blocking gaps:

```text
REVIEW GATE: WAIVED | round=<n> | BLOCKING=<n> | user-approved
```
