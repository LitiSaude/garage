# Telemetry Events — Schema (v1)

The `/build` orchestrator emits structured events at every phase boundary, gate verdict, and significant decision point. Events are appended as JSONL to `<repo>/.claude/state/build/.metrics/<task_slug>.jsonl` by `garage/scripts/emit-event.sh`.

This file is the **contract**. The on-disk format is intentionally separate from the eventual transport (Phase B will wrap the JSONL or live-tail it into a shared MCP). Schema changes should be additive when possible; breaking changes bump the schema version below.

**Schema version**: `1`.

## Privacy invariants (non-negotiable)

Every event carries **metadata only**:

| Allowed | Forbidden |
|---------|-----------|
| File paths, line numbers | File contents, diff hunks, raw code |
| Rule citations (e.g., `partner-scope.md§GoldenRule`) | Verbatim rule text or prompt snippets |
| Agent names, phase numbers, attempt counts | Agent reasoning text, model responses |
| Severity counts (HIGH/MEDIUM/LOW totals) | Finding bodies / explanations |
| Durations, timestamps | — |
| Boolean / enum status flags | Any patient / clinical / PII field |
| Hashes of inputs (e.g., scope_spec_hash) | Secrets, tokens, keys, JWTs |

The emitter (`emit-event.sh`) drops any payload with disallowed top-level keys as a backstop. Primary enforcement is by callers respecting the per-event allowlists below.

## Reading the JSONL

```bash
# All events for a task
cat <repo>/.claude/state/build/.metrics/<task>.jsonl | jq

# All HIGH findings
jq 'select(.type == "finding.emitted" and .payload.severity == "HIGH")' file.jsonl

# Verdict summary by agent
jq -r 'select(.type == "gate.verdict") | "\(.payload.agent)\t\(.payload.verdict)"' file.jsonl | sort | uniq -c
```

## Add to your repo's `.gitignore`

```
.claude/state/build/.metrics/
```

These files are local telemetry, not source-of-truth artefacts.

---

## Event types

Every event has the envelope:

```json
{ "type": "<event_type>", "task_slug": "<slug>", "ts": "<ISO8601 UTC>", "payload": { ... } }
```

The tables below describe `payload` fields per event type.

### `build.started`
Emitted in Phase 0 (when starting a new task) or Phase 1 (after fresh).

| Field | Type | Notes |
|-------|------|-------|
| `scope_hash` | string | sha256(scope_spec) — opaque identifier, no contents |
| `expected_artifacts` | string[] | Phase 1 classification: `["entity","interactor","db_model","enum","api","background_job","ai"]` subset |
| `subdomains_touched` | string[] | e.g., `["clinical_notes"]` |
| `domains_touched` | string[] | e.g., `["continuous_care"]` |

### `build.resumed`
Emitted in Phase 0 when resuming an in-progress task.

| Field | Type | Notes |
|-------|------|-------|
| `from_phase` | int | Phase to resume from |
| `prior_attempt_count` | int | Carried over from state |

### `build.completed`
Emitted in Phase 10 on successful handoff.

| Field | Type | Notes |
|-------|------|-------|
| `total_duration_ms` | int | From `build.started` to here |
| `phase_count` | int | Phases actually executed |
| `auto_fix_attempts` | int | Total iterations across Phase 7 |
| `score` | int | 0-100, optional (Tier 2 penalty matrix) |
| `advisories_count` | int | Non-blocking findings surfaced at handoff |

### `build.escalated`
Emitted when auto-fix loop hits the cap or a Phase 8/9 blocker stops progress.

| Field | Type | Notes |
|-------|------|-------|
| `reason` | enum | `auto_fix_cap_exhausted` / `phase_8_high_finding` / `phase_9_migration_unsafe` / `vague_scope` / `pygeia_path_unresolved` |
| `last_phase` | int | Phase where escalation triggered |
| `attempt_count` | int | Auto-fix attempts at the moment of escalation |

### `build.aborted`
Emitted when the user cancels (e.g., `/build cancel`) or the orchestrator halts due to invalid state.

| Field | Type | Notes |
|-------|------|-------|
| `reason` | enum | `user_cancelled` / `state_corruption` / `interrupted` |
| `last_phase` | int | Phase at abort |

### `phase.entered`
| Field | Type | Notes |
|-------|------|-------|
| `phase` | int | 0-10 |
| `attempt` | int | 1 unless re-entering (Phase 7 re-runs) |

### `phase.exited`
| Field | Type | Notes |
|-------|------|-------|
| `phase` | int | |
| `duration_ms` | int | |
| `status` | enum | `passed` / `failed` / `skipped` (e.g., conditional phases) |

### `gate.verdict`
Emitted once per agent run (Phase 3, 7, 8, 9).

| Field | Type | Notes |
|-------|------|-------|
| `phase` | int | |
| `agent` | string | Filename without `.md` (e.g., `partner-scope-auditor`) |
| `verdict` | enum | `pass` / `partial-pass` / `fail` |
| `hi` | int | HIGH finding count |
| `med` | int | MEDIUM finding count |
| `low` | int | LOW finding count |
| `criteria_pass` | int | done_criteria items satisfied (Tier 1 sprint contract) |
| `criteria_fail` | int | done_criteria items unmet |
| `duration_ms` | int | |

### `finding.emitted`
Emitted once per finding from any auditor.

| Field | Type | Notes |
|-------|------|-------|
| `agent` | string | Auditor name |
| `severity` | enum | `HIGH` / `MEDIUM` / `LOW` |
| `rule_cited` | string | e.g., `partner-scope.md§GoldenRule`. Citation only — never the rule body. |
| `file_path` | string | Repo-relative path. Allowed because pygeia is open-source-style internal; we already log paths everywhere. |
| `line` | int | |
| `pillar` | string \| null | The auditor's pillar/category if applicable (e.g., `Pillar 1 — Scope passed forward`) |

### `auto_fix.iteration`
Emitted at the end of each Phase 7 iteration.

| Field | Type | Notes |
|-------|------|-------|
| `attempt` | int | 1..N (cap=3) |
| `violations_carried_in` | int | Findings from the prior iteration |
| `violations_resolved` | int | Findings fixed this iteration |
| `violations_new` | int | New findings introduced this iteration (regression signal) |
| `violations_remaining` | int | Open after this iteration |

### `done_criteria.set`
Emitted in Phase 3 when the planner emits the sprint contract.

| Field | Type | Notes |
|-------|------|-------|
| `auditor` | string | Which auditor the criteria apply to |
| `rules_count` | int | Number of `done_criteria` rows for this auditor |

### `done_criteria.checked`
Emitted by each auditor in Phase 7/8 alongside its verdict.

| Field | Type | Notes |
|-------|------|-------|
| `auditor` | string | |
| `criteria_total` | int | |
| `criteria_pass` | int | |
| `criteria_fail` | int | |

### `delivery.verified`
Emitted at the end of Phase 7 by `delivery-verification-reviewer`.

| Field | Type | Notes |
|-------|------|-------|
| `requirements_total` | int | Acceptance criteria count from Phase 1 |
| `requirements_covered` | int | Mapped to ≥1 delivered artefact |
| `dead_code_count` | int | New functions/classes with no caller |
| `integration_gaps` | int | Wiring points missing (e.g., interactor not in main.py) |

### `migration.split_required`
Emitted in Phase 3 when DB schema change is detected.

| Field | Type | Notes |
|-------|------|-------|
| `pr_a_files_count` | int | Files belonging to migration-only PR |
| `pr_b_files_count` | int | Files belonging to dependent code PR |

### `standards.cache_loaded`
Emitted in Phase 2 once standards are pre-cached.

| Field | Type | Notes |
|-------|------|-------|
| `docs_count` | int | Number of pygeia docs loaded |
| `docs` | string[] | Filenames only, e.g., `["principles.md","partner-scope.md"]` |
| `total_bytes` | int | Sum of doc sizes |

---

## Adding a new event type

1. Add the entry to this file (table of fields, allowlist).
2. If the field shape is non-trivial, add a section above with examples.
3. Bump the schema version at the top if the change is breaking (rarely needed — be additive).
4. Update Phase B (when it lands) to ingest the new event type.

## What this file is NOT

- Not a transport spec. Phase B will wrap or tail this JSONL; it doesn't define network protocol.
- Not a privacy policy for the team-shared MCP. That doc lives with the MCP when Phase B picks a destination.
- Not a verdict / decision schema. Verdict logic lives in each agent's output format; this file only describes the telemetry that mirrors those decisions.
