# Liti Garage

A shared repository where the Liti team organizes, shares, and collaboratively improves Claude Code skills and agents. Think of it as the team's garage — a place to build, tinker, and refine the tools we use every day.

## Install

Install the plugin from the Claude Code marketplace:

```
claude plugin add liti-garage
```

Or clone the repository and register it locally:

```bash
git clone https://github.com/liti/garage.git
claude plugin add ./garage
```

## What's inside

### Skills

| Skill | Description |
|---|---|
| `/build "<task>"` | **The harness.** Single entrypoint that walks a task through 11 phases (scope → standards load → plan → scaffold → TDD-RED → implement → self-review → parallel review → migration safety → handoff) with pygeia's standards loaded into context before code is written. Auto-fix loop (cap=3) before involving a human. |
| `/scaffold-entity` | Generate a pygeia-compliant entity (file + test) following `code_gen_entities.md`. |
| `/scaffold-db-model` | Generate a pygeia-compliant DB model + migration scaffold. Enforces flat `db_models/` layout, base-class timestamps, mandatory `partner_scope_path()`. |
| `/scaffold-enum` | Generate a pygeia-compliant enum (file + test + migration) following `code_gen_enums.md`. |
| `/scaffold-interactor` | Generate a pygeia-compliant interactor with the partner-scope 7-scenario test matrix scaffolded. |
| `/install-precommit` | Install the Liti compliance pre-commit hook into the working repo. Catches partner-scope violations and high-confidence hardcoded-secret patterns (AWS keys, JWTs, private-key blocks, Stripe live keys, GitHub PATs, etc.) on every commit, even if `/build` is skipped. |
| `/review plan` | Review a feature description before coding and produce a requirements checklist. |
| `/review code` | Review code changes for violations across quality pillars (auto-detects stack). |

### Agents

#### Pre-write & implementer

| Agent | Role |
|---|---|
| **Python Engineer (Pygeia)** | Standards-first implementer dispatched by `/build`. Writes failing test before implementation, cites loaded standards in every section, ships an anti-rationalization table. |

#### Compliance auditors (run in `/build` Phase 7 + Phase 8, available standalone)

| Agent | What it checks | Source of truth |
|---|---|---|
| **Pygeia Principles Checker** | Six non-negotiable principles (readability, low coupling, fail fast, integrity, testability, global complexity) | `principles.md` |
| **Partner Scope Auditor** | Multi-tenancy boundary — every repo call passes scope; `partner_scope_path()` mandatory; 7-scenario tests | `partner-scope.md` |
| **Subdomain Naming Enforcer** | Cross-layer name match per the convention table | `subdomain-namespaces.md` |
| **Ubiquitous Language Validator** | Entity / route / column names match the canonical glossary | `ubiquitous-language.md` |
| **Pygeia Test Coverage Validator** | Scenario coverage + 7-scenario matrix + no mocked repos in scope tests | `testing.md` |
| **Migration Safety Reviewer** | Reversible, no destructive ops on populated tables, FK cascade hygiene, `partner_scope_path()` correct | `database-migrations.md` + `db-models.md` |

#### Post-write reviewers (used by `/review code` and `/build` Phase 8)

| Agent | Stack | What it checks |
|---|---|---|
| **Production Hardening** | Backend | Resilience, idempotency, durability |
| **Audit Compliance** | Backend | Soft deletes, change history, actor attribution |
| **Analytics Coverage** | Frontend/Mobile | Funnel coverage, event naming & taxonomy, event properties |
| **Plan Requirements** | Any | Pre-coding requirements checklist |
| **Business Readiness** | Any | Rollout planning, dependency resilience, multi-tenant impact, data consent, migration |

#### Security — defense in depth (white team + red team)

All three run in `/build` Phase 3 (plan-time, where applicable), Phase 7 (auto-fix loop), and Phase 8 (final freeze). They also run on demand via `/review code`.

| Agent | Team | Coverage |
|---|---|---|
| **Security Controls Reviewer** | White (auditor) | Code-level pillars — OWASP Top 10, OWASP API Top 10, NIST 800-53, CWE: AuthN/AuthZ, injection, secrets, crypto/TLS, PII, supply chain, error disclosure, frontend XSS/CSRF/mobile. |
| **Security Threat Modeling Reviewer** | White (architect) | Design-level — STRIDE coverage, trust boundaries, attack surface enumeration, data classification, secrets / key management strategy, third-party / supply chain trust, abuse resistance. |
| **Security Red-Team Attacker** | **Red (adversary)** | Working attack chains against the design and implementation — auth bypass, horizontal/vertical authz escalation (incl. cross-partner leaks), real injection payloads, races/TOCTOU, business logic abuse, exfiltration paths, multi-tenant boundary attacks, AI prompt injection, denial-of-wallet. |

**What the red team adds.** White-team agents work checklists. The red team builds **exploit chains** — concrete prerequisites, request sequences, payload examples, and the smallest mitigation that breaks the chain. Findings include `attack chain` blocks (steps 1..N) so reviewers see how a single missing layer compounds across the system. Defense in depth becomes verifiable, not theoretical.

## Pygeia Path Resolution

Several skills and agents reference pygeia's code-standards docs at runtime. The path is resolved per-machine — never hardcoded — by `scripts/resolve-pygeia.sh` in this order:

1. `$LITI_PYGEIA_PATH` (env var)
2. Sibling `pygeia/` directory by walking up from `$(pwd)`
3. `~/.claude/liti-garage.json` (key: `pygeia_path`)
4. Interactive prompt + persist

Set `LITI_PYGEIA_PATH` in your shell to skip the search:

```bash
export LITI_PYGEIA_PATH="$HOME/code/liti/pygeia"
```

## Project structure

```
skills/           # Skill definitions (user-facing commands, one SKILL.md per directory)
agents/           # Specialized agent prompts dispatched by skills
scripts/          # Shared shell scripts (path resolver, pre-commit hook, telemetry emitter)
hooks/            # Claude Code hook scripts + hooks.json (PreToolUse gate-progression)
docs/             # Index docs (standards-index.md, telemetry-events.md)
.claude-plugin/   # Plugin metadata and marketplace config
```

## How `/build` enforces phases

Three layered defenses turn the phase pipeline from prose into hard contracts:

1. **PreToolUse hook** (`hooks/validate-gate-progression.sh`) — denies any state-file write that jumps phases by more than +1. Forward gate-skips are blocked at the harness level, not just guideline level.
2. **Sprint Contract `done_criteria`** — Phase 3 emits per-auditor falsifiable evidence requirements. Phase 7/8 auditors check them verbatim and report pass/fail per row, eliminating interpretation drift.
3. **Standards pre-cache** — Phase 2 loads pygeia docs once and injects an identical `<standards>` block into every sub-agent dispatch. Anthropic's prompt cache hits across 9 parallel auditors; reviewers see byte-identical content.

## Telemetry (local, Phase B → MCP)

`/build` emits structured events to `<repo>/.claude/state/build/.metrics/<task_slug>.jsonl`. Schema documented in [docs/telemetry-events.md](docs/telemetry-events.md). Privacy: metadata only — file paths, rule citations, timing, counts. Never file contents, never PII. Phase B will route this stream to a team-shared Liti MCP for cross-engineer analytics.

## Contributing

Add new skills to `skills/`, new agents to `agents/`, and shared scripts to `scripts/`. Open a PR so the team can review and iterate together.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
