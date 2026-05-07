# /scaffold-entity — Generate a pygeia-compliant entity

Generates a new entity in pygeia following `code_gen_entities.md` rules. Produces the entity file in the correct subdomain folder, the entity test file, and verifies subdomain-naming consistency.

## Usage

- `/scaffold-entity` — prompts for the required inputs.
- `/scaffold-entity domain=continuous_care subdomain=clinical_notes name=Template fields=...` — non-interactive.

Dispatched by `/build` with task-spec inputs.

## Behavior

1. **Resolve pygeia** via `${GARAGE_ROOT}/scripts/resolve-pygeia.sh`. Halt on failure.
2. **Load the template.** Read `${PYGEIA_ROOT}/code_gen_entities.md`.
3. **Validate inputs:**
   - `domain`: exists at `${WORKING_REPO}/domains/<domain>/`.
   - `subdomain`: optional. If absent, the entity is treated as a **core entity** of the domain and lives at `domains/<domain>/entities/<entity>.py` per `subdomain-namespaces.md` "Core Domain Entities".
   - `name`: must match the canonical name in `${PYGEIA_ROOT}/docs/code-standards/ubiquitous-language.md`. Halt with a glossary mismatch error if not — only proceed on explicit user override.
   - `fields`: list of field name + type pairs. The template prescribes BaseEntity inheritance, equality, and immutability.
4. **Naming verification.** Apply the convention table from `subdomain-namespaces.md`:
   - File: `entities/<subdomain>/<entity_in_snake>.py`
   - Class: `<Subdomain><Entity>(BaseEntity)` (e.g., `ClinicalNotesTemplate`).
5. **Generate the entity file** per the template (BaseEntity, equality, immutability rules from `entities.md`).
6. **Generate the test file** at the mirrored test path `tests/domains/<domain>/entities/<subdomain>/<entity_in_snake>_test.py`.
7. **Self-review:** verify class naming, file path, BaseEntity inheritance, no business logic in the entity beyond what `entities.md` allows, test file exists.
8. **Report.** Files created + any glossary advisories.

## Anti-patterns to refuse

- Entity name not in the glossary (without explicit override).
- Class name that doesn't follow `<Subdomain><Entity>` (or `<Entity>` for core entities).
- Adding business logic to the entity that belongs in an interactor.
- Using a singular subdomain folder when the existing convention for that domain is plural (or vice versa) — preserve what's already on disk.
- Skipping the test file.

## Tools

- **Read** — template + glossary.
- **Write** — entity + test files.
- **Bash** — resolver, `git status`.
- **Grep, Glob** — verify domain/subdomain folders exist; confirm no name collision.
