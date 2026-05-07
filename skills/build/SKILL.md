# /build — Pygeia-aware Dev Harness

Single entrypoint for any teammate to take a task description through to ready-for-PR code, with pygeia's standards loaded into context **before** code is written. Designed to make non-compliant code impossible to land via late CI/CodeRabbit feedback — every relevant rule is enforced upfront.

## Usage

- `/build "<task description>"` — start a new task (or resume an in-progress one).
- `/build resume` — explicitly resume the most recent in-progress task in this repo.
- `/build fresh` — start a new task even if an in-progress one exists (archives the old one).

## Phase Pipeline (executed in order, each is a hard gate)

### Phase 0 — Resume Check (always)

1. Look in `${WORKING_REPO}/.claude/state/build/` for files named `<task-slug>.json` whose `status` is not `completed`.
2. **If one exists and the user did not pass `fresh`:** print a summary (task description, current phase, last update timestamp) and ask: resume from saved phase, or start fresh? On "fresh", `mv` the old state file to `.claude/state/build/.archived/<task-slug>-<timestamp>.json`.
3. **If none exists:** proceed to Phase 1.

State file shape:
```json
{
  "task_slug": "add-patient-consent-flow",
  "task_description": "...",
  "started_at": "<iso8601>",
  "updated_at": "<iso8601>",
  "phase": 1,
  "status": "in_progress",
  "scope_spec": { ... },
  "standards_loaded": ["principles.md", "..."],
  "plan": { ... },
  "scaffold_dispatched": [],
  "files_changed": [],
  "self_review_attempts": 0,
  "gate_results": {}
}
```

State is rewritten after every phase boundary (and after each self-review attempt).

### Phase 1 — Scope Intake (always)

1. Parse the task description. Extract: **goal**, **acceptance criteria**, **affected domain(s) and subdomain(s)**, **partner-scope implications**, **expected artifacts** (entity? interactor? db model? enum? api?).
2. **Yield-on-vague:** if any of {goal, acceptance criteria, expected artifacts} is missing or unparseable, prompt the user with a structured intake form. Do NOT guess.
3. Persist `scope_spec` to the state file.

### Phase 2 — Standards Load (always)

**Goal:** load every relevant pygeia doc **once** into the orchestrator's context, then re-use the exact same block on every downstream sub-agent dispatch. This serves two purposes: (a) Anthropic's prompt cache hits across the 8 parallel Phase 7 auditors and 11 parallel Phase 8 reviewers when they all share the same prompt prefix, and (b) every reviewer sees identical standards content — eliminating inter-agent drift.

1. **Resolve PYGEIA_ROOT** by running `${GARAGE_ROOT}/scripts/resolve-pygeia.sh` via Bash. If it exits non-zero, halt with the resolver's error message — do not proceed without standards.

2. **Determine docs to load** via `${GARAGE_ROOT}/docs/standards-index.md`:
   - Always-loaded section.
   - Plus every section matching a label in `scope_spec.expected_artifacts`.

3. **Read each doc** with the `Read` tool. Capture: filename, full path, content, content sha256.

4. **Build the `<standards>` block** — this is the canonical artefact that Phases 3–9 reuse. Format:
   ```
   <standards source="pygeia">
   <standard path="docs/code-standards/principles.md" sha256="<hex>">
   <full content of principles.md>
   </standard>
   <standard path="docs/code-standards/partner-scope.md" sha256="<hex>">
   <full content of partner-scope.md>
   </standard>
   <!-- one <standard> element per loaded doc, in deterministic order: alphabetical by path -->
   </standards>
   ```
   Order matters: alphabetical by path so the prefix is byte-identical across runs of the same task. The block is stored in state as `standards_block` (the literal string) and also as `standards_loaded` (list of `{path, sha256, bytes}` objects for telemetry).

5. **Persist to state** and emit telemetry:
   ```bash
   ${GARAGE_ROOT}/scripts/emit-event.sh standards.cache_loaded "$task_slug" \
     "$(jq -nc --argjson docs "$docs_array" --argjson bytes "$total_bytes" \
        '{docs_count:($docs|length), docs:$docs, total_bytes:$bytes}')"
   ```

6. **Injection contract for Phases 3–9.** Every agent dispatch (compliance auditors, security reviewers, implementer, scaffold skills, plan reviewer, delivery-verification reviewer) receives the literal `standards_block` as the **first content** of its prompt, followed by a separator line `---` and then the agent-specific task description. The block must be byte-identical across dispatches in this `/build` run. Do NOT rebuild it per dispatch; reuse the persisted string verbatim.

   Example dispatch shape:
   ```
   <standards source="pygeia">
   ...verbatim from state.standards_block...
   </standards>

   ---

   <task description for this specific agent>
   ```

7. **Failure mode.** If a doc fails to load (missing pygeia checkout — should not happen after step 1), halt with the resolver's error. If a sub-agent reports the `<standards>` block is missing from its prompt (it was dispatched without injection), surface as a harness bug — that means the orchestrator violated the injection contract.

### Phase 3 — Plan (always)

1. Dispatch a planning task (use the Plan agent if available; otherwise the orchestrator writes the plan inline).
2. The plan must:
   - State current state vs target state.
   - List files to touch (cite subdomain naming convention from `subdomain-namespaces.md`).
   - State which `partner_scope` semantics apply (from `partner-scope.md`'s 4 variants).
   - Enumerate the test scenarios (from `testing.md`'s scenario types + the 7-scenario matrix if scoped).
   - Cross-check the entity name against `ubiquitous-language.md`.
   - Identify the trust boundaries the change crosses, the data classification of inputs/outputs, and any new attack surface (endpoints, queues, file uploads, AI agent prompts/tools).
3. Self-review the plan against `principles.md` (low coupling, fail fast, integrity, testability). Fix issues before exit.

4. **Sprint Contract — emit `done_criteria`.** Translate the plan into per-auditor acceptance criteria. This is the contract Phase 7/8 auditors will check verbatim — no interpretation drift, no derived requirements. Persist to state as `done_criteria` (array of objects):

   ```json
   {
     "done_criteria": [
       {
         "id": "dc-001",
         "auditor": "partner-scope-auditor",
         "rule": "partner-scope.md§GoldenRule",
         "evidence_required": "Every repository call in domains/continuous_care/interactors/clinical_notes/archive_template.py forwards contract.partner_scope"
       },
       {
         "id": "dc-002",
         "auditor": "pygeia-test-coverage-validator",
         "rule": "partner-scope.md§7-Scenario-Matrix",
         "evidence_required": "tests/domains/continuous_care/interactors/clinical_notes/archive_template_test.py contains the 7 named scenarios"
       },
       {
         "id": "dc-003",
         "auditor": "subdomain-naming-enforcer",
         "rule": "subdomain-namespaces.md§NamingConventionTable",
         "evidence_required": "main.py exposes clinical_notes_archive_template() with docstring 'Clinical Notes - Archive template.'"
       },
       {
         "id": "dc-004",
         "auditor": "delivery-verification-reviewer",
         "rule": "delivery§Integration",
         "evidence_required": "POST /api/v1/clinical-notes/templates/{id}/archive route is registered in routers/continuous_care/v1/clinical_notes/templates.py"
       }
     ]
   }
   ```

   Rules:
   - Every acceptance criterion in the user's task gets ≥ 1 `done_criteria` row.
   - Every `expected_artifact` from Phase 1 gets ≥ 1 row tied to a delivery rule.
   - `evidence_required` must be **falsifiable** — a sentence that can be evaluated as pass/fail by reading code, not "the implementation is good".

   Emit telemetry for each row:
   ```bash
   ${GARAGE_ROOT}/scripts/emit-event.sh done_criteria.set "$task_slug" \
     "$(jq -nc --arg auditor "$auditor" --argjson n "$rules_count" \
        '{auditor:$auditor, rules_count:$n}')"
   ```

5. **Plan-time security gate.** Dispatch in parallel (single message, two `Agent` tool calls):
   - `@agents/security-threat-modeling-reviewer.md` — white-team STRIDE-style design review (trust boundaries, AuthN/AuthZ design, data classification, supply chain trust, secrets/key management, abuse resistance).
   - `@agents/security-red-team-attacker.md` — red-team adversarial design review (concrete attack scenarios against the plan).

   Block on any HIGH from either. The plan must address them before Phase 4. MEDIUM/LOW findings carry forward to Phase 8 advisories. Add new `done_criteria` rows for any gap surfaced here (so Phase 7 auditors will check the fix landed).

6. **Schema-Split-PR detection.** If `expected_artifacts` contains `db_model` OR the plan references migrations / schema changes, the plan **must** include a `release_sequencing` section that splits work into:

   ```json
   {
     "release_sequencing": {
       "pr_a_migration_only": {
         "files": [
           "<migration file>",
           "domains/<domain>/db_models/<subdomain>_<entity>_model.py"
         ],
         "rationale": "Additive schema change. Ships and deploys before PR-B opens.",
         "deploy_safety": {
           "additive_only": true,
           "default_provided": true,
           "reversible": true,
           "destructive_ops": false
         }
       },
       "pr_b_dependent_code": {
         "files": [
           "domains/<domain>/entities/...",
           "domains/<domain>/interactors/...",
           "domains/<domain>/json_serializers/...",
           "tests/..."
         ],
         "depends_on": "PR-A merged + deployed",
         "rationale": "References the new schema element. Cannot deploy until PR-A's migration is live."
       }
     }
   }
   ```

   Rules:
   - **PR-A is migration + DB model only.** It must be backward-compatible: column added with default; no NOT NULL on populated tables; no destructive ops; reversible `down`.
   - **PR-B is everything else** that references the new schema. Its description includes a `Depends on: <PR-A link>` line.
   - **The current `/build` run produces ONE of the two PRs at a time.** The user (or the orchestrator) chooses which to ship first. If both are needed, run `/build` twice — once with `mode=migration-only`, then again after PR-A is deployed for `mode=code`.
   - For the rare legitimate combined case (a brand-new table that nothing else references yet, or both PRs guaranteed to deploy in the same window), the user must type the literal acknowledge phrase: `"I acknowledge this combined change and have verified deploy ordering"`. Without that exact phrase, Phase 9 (Migration Safety) blocks combined diffs.

   Add a `done_criteria` row to drive Phase 9 and Phase 10:
   ```json
   {
     "id": "dc-split",
     "auditor": "migration-safety-reviewer",
     "rule": "database-migrations.md§ExpandContract",
     "evidence_required": "Diff contains EITHER PR-A files OR PR-B files, not both — unless the acknowledge phrase is present"
   }
   ```

   Emit telemetry:
   ```bash
   ${GARAGE_ROOT}/scripts/emit-event.sh migration.split_required "$task_slug" \
     "$(jq -nc --argjson a "$pr_a_count" --argjson b "$pr_b_count" \
        '{pr_a_files_count:$a, pr_b_files_count:$b}')"
   ```

7. Persist the plan + `done_criteria` + `release_sequencing` (if applicable) + Phase 3 gate results to state.

### Phase 4 — Scaffold (conditional)

1. **Trigger:** the plan declares creation of a standard artifact (`entity` / `db_model` / `enum` / `interactor`).
2. For each artifact, dispatch the matching skill: `/scaffold-entity`, `/scaffold-db-model`, `/scaffold-enum`, `/scaffold-interactor`. Pass the resolved inputs from `scope_spec` so each skill is non-interactive.
3. Skills generate pre-compliant boilerplate (correct base classes, partner_scope hooks, naming, imports, test-file scaffolds).
4. After each skill returns, append the created paths to `files_changed` and persist state.

### Phase 5 — TDD-RED (always)

1. Dispatch the **`python-engineer-pygeia`** agent with: scope spec, loaded standards (in context), and the scaffolded files.
2. The agent must write a failing test for the new behaviour and **run it** to prove it fails. The agent's response includes the failing pytest output.
3. If the test passes immediately or doesn't fail for the right reason, the orchestrator instructs the agent to fix the test until it fails for the right reason. Do not advance to Phase 6 on a green test.
4. Persist the test path(s) to state.

### Phase 6 — Implement (always)

1. Same `python-engineer-pygeia` agent writes production code that satisfies the failing test, using the loaded standards.
2. Agent runs the test suite to confirm green; the orchestrator captures the output.
3. Agent runs the project's linter / formatter / type checker (likely `ruff`, `black`, `mypy`); orchestrator captures the output.

### Phase 7 — Self-review + Auto-fix Loop (cap N=3)

**Sprint Contract injection.** Each auditor receives the subset of `state.done_criteria` whose `auditor` field matches its name. The criteria are passed verbatim in the dispatch prompt under a `## Sprint Contract` heading. The auditor MUST report per-criterion pass/fail in its verdict (see "Output Format" in each agent file). Criteria with no matching auditor (e.g., delivery-verification rules) are routed to the matching specialist agent in the same parallel batch.

1. Run **9 auditors in parallel** (use the `Agent` tool with `general-purpose` subagent type, one tool call per agent in a single message):

   **Compliance (pygeia-specific):**
   - `@agents/pygeia-principles-checker.md`
   - `@agents/partner-scope-auditor.md`
   - `@agents/subdomain-naming-enforcer.md`
   - `@agents/ubiquitous-language-validator.md`
   - `@agents/pygeia-test-coverage-validator.md`

   **Security (defense in depth — white + red team):**
   - `@agents/security-controls-reviewer.md` — white-team code-level controls (OWASP/NIST/CWE pillars).
   - `@agents/security-threat-modeling-reviewer.md` — white-team STRIDE re-check post-implementation (does the code actually realize the plan's trust boundaries?).
   - `@agents/security-red-team-attacker.md` — red-team adversarial code review (working attack chains against the implementation).

   **Delivery (closes "code exists vs feature reachable"):**
   - `@agents/delivery-verification-reviewer.md` — Requirement Coverage Matrix + Dead Code Detection + Integration Verification. Catches the "compiled + tested but never wired into main.py / router / DI" failure mode.

2. Collect verdicts. **If any return `fail` or `partial-pass`:**
   - Increment `self_review_attempts`.
   - **If `self_review_attempts <= 3`:** synthesize a violation prompt — for each finding, include the file:line, the rule cited, and a concrete fix suggestion. Re-dispatch `python-engineer-pygeia` with the violations. After the agent fixes, re-run the auditors. Repeat.
   - **If `self_review_attempts > 3`:** halt the auto-fix loop. Save the full violation history to state. Surface to the human at Phase 10 with: "Could not satisfy compliance after 3 attempts — escalation required."
3. **If all auditors return `pass`:** advance to Phase 8.
4. Persist attempt count and gate results after each iteration.

### Phase 8 — Parallel Review Gate (always)

1. Dispatch **all reviewers in parallel** in a single message (use the `Agent` tool, one call per agent):

   General reviewers (under `@agents/`):
   - `production-hardening-reviewer.md`
   - `audit-compliance-reviewer.md`
   - `analytics-coverage-reviewer.md` (only if frontend/mobile files in diff)
   - `business-readiness-reviewer.md`

   Security — full defense-in-depth (all three, every run):
   - `security-controls-reviewer.md` — white-team code controls.
   - `security-threat-modeling-reviewer.md` — white-team threat-model freeze (final post-impl check).
   - `security-red-team-attacker.md` — red-team final attack chain.

   Compliance auditors (already run in Phase 7 — re-run here as a freeze-frame check after any post-Phase-7 edits):
   - `pygeia-principles-checker.md`
   - `partner-scope-auditor.md`
   - `subdomain-naming-enforcer.md`
   - `ubiquitous-language-validator.md`
   - `pygeia-test-coverage-validator.md`
   - `delivery-verification-reviewer.md`

2. **Block** on any blocking finding (HIGH severity, or any `fail` verdict). Surface findings to the user immediately — do NOT auto-fix at this gate. The auto-fix loop is Phase 7; Phase 8 is a final freeze.
3. Non-blocking findings (MEDIUM / LOW) surface as advisories in the Phase 10 report.
4. Persist gate results.

### Phase 9 — Migration Safety (conditional)

1. **Trigger:** `files_changed` includes anything matching `**/db_models/**` or `**/migrations/**`.
2. Dispatch `@agents/migration-safety-reviewer.md`. The agent checks: timestamps via base class, `partner_scope_path()` defined, no destructive ops on populated tables, migration reversibility, **and the Schema-Split-PR rule** — diff must contain only PR-A files (migration + DB model) OR only PR-B files (code referencing the schema), never both, unless the plan includes the literal acknowledge phrase: `"I acknowledge this combined change and have verified deploy ordering"`.
3. Block on HIGH findings; surface MEDIUM / LOW as advisories.
4. Persist.

### Phase 10 — Human Handoff (always)

1. Print a structured summary:
   - Task: <description>
   - Phases completed: 0–10
   - Files changed: <bulleted list>
   - Gate results: <Phase 7 verdict, Phase 8 verdict, Phase 9 verdict if run>
   - `done_criteria` summary: <pass / fail per row>
   - Advisories (non-blocking): <list with file:line>
   - Suggested commit message (per repo conventions, plain text — never auto-commit).
2. **If `state.release_sequencing` is set** (schema change in scope), emit **two** PR drafts instead of one:

   ```
   === PR-A (ship first) ===
   Title: <title> — schema only
   Body:
     ## What
     Additive schema change for <feature>. Adds <column/table/enum>.

     ## Deploy safety
     - Additive only (new columns nullable with server defaults / new tables).
     - Reversible down migration.
     - No destructive ops.
     - Backward compatible: existing app instances continue to function.

     ## Files
     - <list from release_sequencing.pr_a_migration_only.files>

     ## Sequencing
     This PR must merge AND deploy before PR-B opens.

   === PR-B (ship after PR-A is deployed) ===
   Title: <title> — code
   Body:
     ## What
     Implements <feature> using the schema introduced in #<PR-A>.

     ## Depends on
     - #<PR-A> (must be merged AND deployed in production before this PR is opened)

     ## Files
     - <list from release_sequencing.pr_b_dependent_code.files>

     ## Acceptance criteria
     - <from done_criteria>
   ```

   Tell the user: *"This `/build` run produced both halves. Choose which to ship now (typically PR-A first); re-run `/build resume` after the first is deployed to ship the second half."*

3. Ask the user: "Ready to commit? (review the diff first; I will not auto-commit.)"
4. On user confirmation, optionally run `git status` / `git diff --stat` to help them stage.
5. Emit `build.completed` telemetry with score (Tier 2 — for now, emit with `score: null`).
6. **Mark state `status: completed`** and move it to `.claude/state/build/.completed/<task-slug>-<timestamp>.json`.

## Auto-fix Loop Rules (Phase 7)

- Cap is **N=3** total agent re-dispatches per `/build` run.
- Each retry receives the **full** violation list — never partial. The implementer must satisfy all violations in one pass.
- Retries do NOT include the orchestrator's interpretation; they include verbatim auditor findings (file:line + rule + fix suggestion). Avoid telephone-game distortion.
- After the cap, the orchestrator halts and surfaces. The user can: re-engage `/build` (which resumes from Phase 7 with attempt count reset to 0), or take over manually.

## Anti-patterns the Orchestrator Refuses

- **Skipping Phase 5 (TDD-RED).** Even if the change is "obviously simple". The user's stated goal is correctness from the first character; tests prove the behaviour is understood.
- **Sequential reviewer dispatch in Phase 8.** Always parallel — Ring's rule. Sequential review is slow and produces inconsistent prioritization.
- **Auto-committing.** Phase 10 surfaces a suggested commit message; the human commits.
- **Editing files outside the implementer agent.** The orchestrator does not write production code itself; it dispatches the implementer agent so all writes go through the standards-loaded path.
- **Continuing past Phase 2 without a resolved PYGEIA_ROOT.** No standards = no harness.

## Tools

- **Bash** — running `${GARAGE_ROOT}/scripts/resolve-pygeia.sh`, `git`, project tooling (`pytest`, `ruff`, `mypy`).
- **Read** — loading pygeia standards docs and existing code.
- **Write, Edit** — only for the orchestrator's own state files (`<repo>/.claude/state/build/*.json`). Production code edits go through `python-engineer-pygeia`.
- **Glob, Grep** — exploration during phases.
- **Agent** — dispatching all sub-agents (implementer + reviewers + scaffold skills).

## Resolving the Working Repo & Garage Path

- `${WORKING_REPO}` is the user's current project (`git rev-parse --show-toplevel`).
- `${GARAGE_ROOT}` is the directory containing this skill — resolved via `git rev-parse --show-toplevel` if the skill is invoked from inside the garage repo, otherwise via the plugin's install location. Pass it forward to sub-agents and scripts via Bash environment.

## Failure Modes

- **PYGEIA_ROOT unresolvable:** halt at Phase 2 with the resolver's error.
- **Vague task description:** yield at Phase 1 with a structured intake prompt.
- **Auto-fix loop exhausted:** halt at Phase 7 → Phase 10 with the violation history.
- **Phase 8 HIGH finding:** halt at Phase 8 with the finding; user can re-engage `/build` to fix.
- **State file corruption:** at Phase 0, if a state file fails to parse, archive it and start fresh.
