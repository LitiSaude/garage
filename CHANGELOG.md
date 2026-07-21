# Changelog

Manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`) stay at the last released version until a release ships; unreleased work accumulates here.

## 1.7.0 (unreleased)

The development harness: garage's skills now compound into one pipeline — each stage produces a contract the next consumes, gated by fresh-context judges.

- **`spec-writing` skill** — STE prose + "spec is code" precision for any spec/brief/design doc: 16 ASD-STE100 rules adapted for specs (`reference/ste-rules.md`), a precision bar per section (four-questions rule, contract/transition tables, Given/When/Then acceptance, ambiguity audit, spec-complete checklist in `reference/spec-template.md`), and a real before/after example. Composes with `/brief`: brief template governs structure, spec-writing governs prose and precision.
- **`/brief` skill** — rough ask → review-gated brief at `docs/specs/<slug>.md` (goal, house rules, measurable Done Bar, 5-part workstream specs, user-testable merge checkpoints). Advisor consult before the gate; loops the plan reviewers until `BLOCKING=0` (≤3 rounds, then the user resolves or waives).
- **`orchestration` skill** — architect-as-orchestrator routing doctrine: implementer/opus/codex/feature-executor lanes, 5-part spec contract, cost discipline, loop-until-bar posture. Adapted from fable-advisor v2.1.0 (MIT, Dan McAteer).
- **New agents** — `advisor` (Fable-pinned commitment-boundary skeptic), `implementer` (Sonnet lane, Opus escalation), `codex-implementer` (GPT-5.5 via Codex CLI, loud failure), all vendored from fable-advisor v2.1.0; `bar-judge` (fresh-context adversarial Done Bar judge, new).
- **`/review`** — plan mode accepts an optional path argument; all seven reviewer fragments end with machine-parsed `FRAGMENT VERDICT:` lines; merged reports end with a `VERDICT:` line computed by arithmetic sum, never re-judged; code-time severity scale gains CRITICAL.
- **`/parallel-feature`** — recognizes `/brief` output natively (warns on `REVIEW GATE: WAIVED` or a missing gate); spawn prompts carry the workstream's 5-part spec block and the brief's House Rules verbatim; new garage review gate after CodeRabbit approval (`VERDICT: CRITICAL=0 HIGH=0`, advisor consult after two failures, `--garage-review off` opt-out); waves gate on both approvals; merge checkpoints announced as user-testable; final `bar-judge` pass against the brief's Done Bar.
- **`feature-executor`** — explicit input contract (5-part spec + House Rules) and an evidence-bearing `EXECUTOR REPORT` (matrix path, verification output, blockers).
- **Docs** — README development-harness section with the pipeline, verdict grammar, and compounding map; `/visualize-plan` slots between `/brief` and `/parallel-feature`.
