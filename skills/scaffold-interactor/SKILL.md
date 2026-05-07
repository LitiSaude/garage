# /scaffold-interactor — Generate a pygeia-compliant interactor (use case)

Generates an interactor following `code_gen_use_cases.md`. Produces the interactor file with correct contract, scope passing, the test file with the partner-scope 7-scenario matrix scaffold, and the main.py entry.

## Usage

- `/scaffold-interactor` — prompts for inputs.
- `/scaffold-interactor domain=continuous_care subdomain=clinical_notes operation=list_templates entity=template kind=list` — non-interactive.

`kind` is one of: `get`, `list`, `create`, `update`, `delete`, `upsert`. The kind drives the contract shape and which 7-scenario adaptations apply.

## Behavior

1. **Resolve pygeia** via `${GARAGE_ROOT}/scripts/resolve-pygeia.sh`.
2. **Load the template:** `${PYGEIA_ROOT}/code_gen_use_cases.md`.
3. **Load supporting standards:**
   - `${PYGEIA_ROOT}/docs/code-standards/interactors.md`
   - `${PYGEIA_ROOT}/docs/code-standards/partner-scope.md`
   - `${PYGEIA_ROOT}/docs/code-standards/testing.md`
4. **Validate inputs:** entity exists, subdomain naming is consistent, operation verb is canonical (cross-check `ubiquitous-language.md` glossary).
5. **Naming verification** per `subdomain-namespaces.md`:
   - File: `domains/<domain>/interactors/<subdomain>/<operation>.py` (e.g., `list_templates.py`).
   - main.py function: `<subdomain>_<operation>()` (e.g., `clinical_notes_list_templates()`).
   - Operation file does NOT repeat the subdomain (no `list_clinical_notes_templates.py`).
   - Entity references inside use the FULL entity name — no abbreviations.
6. **Generate the interactor:**
   - Contract dataclass with `partner_scope: PartnerScope` field.
   - Body forwards `contract.partner_scope` to every repository call.
   - For upsert kind: parent lookup uses `contract.partner_scope`; child lookup uses `PartnerScope.unscoped` (this is the documented exception).
   - For list kind: response includes `data`, `meta.total`.
   - Errors raised, never None-returned, per principles.md "Fail fast".
7. **Generate main.py entry** with the function signature `<subdomain>_<operation>()` and docstring `"""<Subdomain> - <description>."""`.
8. **Generate the test file** at the mirrored test path with the 7-scenario matrix scaffolded:
   - All 7 named scenarios per `partner-scope.md` Testing section.
   - For permissive scopes (6, 7), scaffold both `partner_id=None` AND `partner_id=uuid.uuid4()` cases.
   - For mutating kinds (`create`, `update`, `delete`, `upsert`): denial scenarios (2, 4, 5) include the post-failure reload-and-assert-unchanged check.
   - For `delete` kind: post-condition asserts via `repository.get(id)` raising `RecordNotfoundError`.
   - Plus the standard happy/error/unusual/edge/invalid scenarios per Principle 4.
   - **Tests must NOT mock the repository.** The scaffold uses real DB fixtures.
9. **Self-review:** contract has `partner_scope`, every repo call forwards it, main.py function name follows convention, test file has all 7 named scenarios, no mocked repositories in scope tests.
10. **Report.** Files created + the 7 test method names so the human can confirm coverage.

## Anti-patterns to refuse

- Interactor that omits `partner_scope` from the contract.
- Hardcoded `PartnerScope.unscoped` outside the upsert exception.
- Operation filename that repeats the subdomain.
- Entity name abbreviations (`archive_clinical_note.py` when the entity is `patient_clinical_note.py`).
- Test file with fewer than 7 scope scenarios.
- Mocked repository calls in the scope tests.
- `data_owner` / `unscoped` tests that exercise only one `partner_id` value.

## Tools

- **Read** — template + standards.
- **Write** — interactor file, main.py entry, test file.
- **Edit** — update main.py to register the new function.
- **Bash** — resolver, `git status`.
- **Grep, Glob** — verify entity exists, operation doesn't already exist.
