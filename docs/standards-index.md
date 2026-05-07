# Standards Index — Phase 2 Loading Map

Used by `/build` Phase 2 (Standards Load) to decide which pygeia code-standards docs to pull into context based on the work classification produced in Phase 1.

All paths are **relative to the resolved pygeia root** (`${PYGEIA_ROOT}`), obtained via `garage/scripts/resolve-pygeia.sh`. Never bake absolute paths.

## Always loaded (every `/build` run)

| Path | Purpose |
|------|---------|
| `docs/code-standards/principles.md` | Six non-negotiable principles (readability, low coupling/high cohesion, fail fast, integrity, testability, global complexity). Has explicit "Common invalid arguments" — feeds anti-rationalization. |
| `docs/code-standards/subdomain-namespaces.md` | Naming convention table — entity folder name IS the subdomain name; every layer must use it identically. |
| `docs/code-standards/ubiquitous-language.md` | Domain glossary; entity names must match canonical vocabulary. |
| `docs/code-standards/architecture.md` | Clean Architecture layers, domain isolation. |
| `docs/code-standards/good-practices.md` | Do/Don't examples for each domain concept. Reference for fixes. |

## Loaded when creating an Entity

| Path | Purpose |
|------|---------|
| `docs/code-standards/entities.md` | Entity structure, equality, immutability rules. |
| `code_gen_entities.md` | Scaffolding template (used by `/scaffold-entity`). |

## Loaded when creating an Interactor / Use Case

| Path | Purpose |
|------|---------|
| `docs/code-standards/interactors.md` | Use case contracts, error handling, scope passing. |
| `docs/code-standards/partner-scope.md` | **Critical.** Multi-tenancy rules; `partner_scope` must be passed forward; 7-scenario test matrix. |
| `code_gen_use_cases.md` | Scaffolding template. |

## Loaded when creating a DB Model

| Path | Purpose |
|------|---------|
| `docs/code-standards/db-models.md` | BaseModel inheritance, timestamp columns, no duplicate definitions. |
| `docs/code-standards/partner-scope.md` | `partner_scope_path()` is mandatory; how to define direct/join/None. |
| `docs/code-standards/database-migrations.md` | Migration safety, reversibility, base-class timestamps. |
| `code_gen_db_models.md` | Scaffolding template. |

## Loaded when creating an Enum

| Path | Purpose |
|------|---------|
| `docs/code-standards/enums.md` | BaseEnum inheritance, naming (PascalCase class + UPPERCASE attrs), docstring format. |
| `code_gen_enums.md` | Scaffolding template. |

## Loaded before any test work

| Path | Purpose |
|------|---------|
| `docs/code-standards/testing.md` | Test scenario analysis, branch coverage, deterministic assertions, scope tests. |
| `docs/code-standards/partner-scope.md` (testing section) | The 7-scenario matrix every scoped interactor must implement. |

## Loaded when touching the API layer (router/serializer/pubsub)

| Path | Purpose |
|------|---------|
| `docs/code-standards/web-api/` (folder) | HTTP/API conventions. |
| `docs/code-standards/routing.md` | Router structure. |
| `docs/code-standards/pubsub.md` | Pub/Sub event design. |

## Loaded when touching background jobs / workflows

| Path | Purpose |
|------|---------|
| `docs/code-standards/background-jobs.md` | Temporal workflows, activity idempotency. |
| `docs/code-standards/routines.md` | Routine structure (if applicable). |

## Loaded when touching AI agents / tools

| Path | Purpose |
|------|---------|
| `docs/code-standards/ai-agents.md` | Agent architecture, tools, memory. |
| `docs/code-standards/ai-tools.md` | Tool definitions and conventions. |

---

## How `/build` uses this index

1. Phase 1 (Scope Intake) classifies the task into one or more of: `entity`, `interactor`, `db_model`, `enum`, `api`, `background_job`, `ai`. Multiple labels are possible (e.g., adding a new use case typically touches `interactor` + `entity` + sometimes `db_model`).
2. Phase 2 (Standards Load) reads the "Always loaded" section plus every section matching a Phase-1 label.
3. Each doc is loaded into the orchestrator's context with a clear header so the implementer agent can cite specific rules in its plan and self-review.
4. If a doc fails to load (path resolution failure), `/build` halts in Phase 2 with the resolver's error message.
