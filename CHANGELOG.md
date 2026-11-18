# Changelog

Manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`) stay at the last released version until a release ships; unreleased work accumulates here.

## 2.0.0 (unreleased)

Breaking: two agents are removed. Anything that spawns `implementer` or `codex-implementer` by name stops working.

- **Removed `implementer` and `codex-implementer` agents.** They were vendored from fable-advisor v2.1.0 and had fallen five major versions behind upstream. Claude Code's Agent tool now takes model and effort per call, so the session delegates through the built-in general-purpose subagent instead. For a second model family, use the OpenAI Codex plugin (`codex@openai-codex`: `/codex:adversarial-review`, `/codex:rescue`).
- **`orchestration` skill rewritten.** The standing rules to delegate ("should almost never type implementation code", the lanes table) are replaced with what delegation costs and when it pays, following upstream's v7.3.0 rewrite and its measurements. The five-part spec, the evidence checks, the `advisor` consult points, and the loop posture stay. The loop posture now reads build ⇄ `bar-judge`: the session builds or delegates as it judges best, and the judge still decides when the bar is met.
- **Migration:** replace `subagent_type: "implementer"` with a general-purpose subagent call that passes `model` (for example `sonnet`) and carries the five-part spec. `/brief`, `/parallel-feature`, `feature-executor`, `advisor`, and `bar-judge` are unchanged.
- **Docs** — README, `skills/brief/SKILL.md`, and `skills/brief/reference/principles.md` no longer reference implementer lanes.

## 1.7.0 — 2026-07-21

The development harness: garage's skills now compound into one pipeline — each stage produces a contract the next consumes, gated by fresh-context judges.

- **`spec-writing` skill** — STE prose + "spec is code" precision for any spec/brief/design doc: 16 ASD-STE100 rules adapted for specs (`reference/ste-rules.md`), a precision bar per section (four-questions rule, contract/transition tables, Given/When/Then acceptance, ambiguity audit, spec-complete checklist in `reference/spec-template.md`). Composes with `/brief`: brief template governs structure, spec-writing governs prose and precision.
- **`/brief` skill** — rough ask → review-gated brief at `docs/specs/<slug>.md` (goal, house rules, measurable Done Bar, 5-part workstream specs, user-testable merge checkpoints). Advisor consult before the gate; loops the plan reviewers until `BLOCKING=0` (≤3 rounds, then the user resolves or waives).
- **`orchestration` skill** — architect-as-orchestrator routing doctrine: implementer/opus/codex/feature-executor lanes, 5-part spec contract, cost discipline, loop-until-bar posture. Adapted from fable-advisor v2.1.0 (MIT, Dan McAteer).
- **New agents** — `advisor` (Fable-pinned commitment-boundary skeptic), `implementer` (Sonnet lane, Opus escalation), `codex-implementer` (GPT-5.5 via Codex CLI, loud failure), all vendored from fable-advisor v2.1.0; `bar-judge` (fresh-context adversarial Done Bar judge, new).
- **`/review`** — plan mode accepts an optional path argument; all seven reviewer fragments end with machine-parsed `FRAGMENT VERDICT:` lines; merged reports end with a `VERDICT:` line computed by arithmetic sum, never re-judged; code-time severity scale gains CRITICAL.
- **`/parallel-feature`** — recognizes `/brief` output natively (warns on `REVIEW GATE: WAIVED` or a missing gate); spawn prompts carry the workstream's 5-part spec block and the brief's House Rules verbatim; new garage review gate after CodeRabbit approval (`VERDICT: CRITICAL=0 HIGH=0`, advisor consult after two failures, `--garage-review off` opt-out); waves gate on both approvals; merge checkpoints announced as user-testable; final `bar-judge` pass against the brief's Done Bar.
- **`feature-executor`** — explicit input contract (5-part spec + House Rules) and an evidence-bearing `EXECUTOR REPORT` (matrix path, verification output, blockers).
- **Docs** — README development-harness section with the pipeline, verdict grammar, and compounding map; `/visualize-plan` slots between `/brief` and `/parallel-feature`.
