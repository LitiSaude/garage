# /scaffold-enum — Generate a pygeia-compliant enum

Generates a new enum in pygeia following `code_gen_enums.md` rules. Produces the enum file, the test file, and prepares the migration.

## Usage

- `/scaffold-enum` — prompts for the required inputs.
- `/scaffold-enum domain=continuous_care subdomain=clinical_notes name=DiagnosisCertainty values=high,medium,low` — non-interactive.

When dispatched by `/build`, all inputs come from the orchestrator's task spec.

## Behavior

1. **Resolve pygeia.** Run `${GARAGE_ROOT}/scripts/resolve-pygeia.sh` via Bash to obtain `${PYGEIA_ROOT}`. Halt with the resolver's error on failure.
2. **Load the template.** Read `${PYGEIA_ROOT}/code_gen_enums.md`. Use it as the source of truth — never hardcode template content here.
3. **Validate inputs:**
   - `domain`: must exist as `${WORKING_REPO}/domains/<domain>/`.
   - `subdomain`: optional. If provided, the enum lives in the subdomain naming convention (`subdomain-namespaces.md` rules).
   - `name`: PascalCase (per `code_gen_enums.md`). Cross-check against `${PYGEIA_ROOT}/docs/code-standards/ubiquitous-language.md` — flag if not in the glossary.
   - `values`: comma-separated, snake_case. The template requires the value string to equal the constant name in lowercase.
4. **Generate the enum file** at `${WORKING_REPO}/domains/<domain>/enums/<name_in_snake>.py` per the template's "enum example".
5. **Generate the test file** at the mirrored test path `${WORKING_REPO}/tests/domains/<domain>/enums/<name_in_snake>_test.py` per "enum test example".
6. **Generate the migration.** Run `make <domain>.db.gen.migration MESSAGE="<name_in_snake> enum create"` then rewrite the `upgrade()` / `downgrade()` per the template.
7. **Self-review.** Confirm: BaseEnum inheritance, single-line docstrings, snake_case values matching constant names, no extra methods, file in the flat `enums/` folder (no subfolders allowed by the template), test file present.
8. **Report.** List the files created, the migration command output, and any glossary mismatches as advisories.

## Anti-patterns to refuse

- Creating subfolders inside `enums/` — template forbids it.
- Adding methods beyond what BaseEnum provides — template says "avoid".
- Multi-line docstrings on the module or class.
- Skipping the test file or the migration step.
- Inventing a name not in `ubiquitous-language.md` without explicit user confirmation.

## Tools

- **Read** — load the template and any reference files.
- **Write** — create the enum and test files.
- **Bash** — run the resolver, the make migration command, and `git status` to confirm new files.
- **Grep, Glob** — verify the domain exists and the enum doesn't already exist.

If invoked outside `/build`, this skill writes the files and stops. If invoked by `/build`, it returns control to the orchestrator after generation; the orchestrator drives the rest of the phase pipeline.
