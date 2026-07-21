# Liti Garage

A shared repository where the Liti team organizes, shares, and collaboratively improves Claude Code skills and agents. Think of it as the team's garage — a place to build, tinker, and refine the tools we use every day.

## Install

Install the plugin from the Claude Code marketplace:

```text
claude plugin add liti-garage
```

Or clone the repository and register it locally:

```bash
git clone https://github.com/liti/garage.git
claude plugin add ./garage
```

## Development harness

The skills compound into one pipeline. Each stage produces a contract the next stage consumes, and every stage is gated by fresh-context judges — whatever builds something never grades it.

```text
rough ask
  → /brief            draft → advisor consult → review-gate loop (3 plan reviewers, ≤3 rounds)
  → docs/specs/<slug>.md        the brief IS the spec
  → /visualize-plan             optional stakeholder view
  → posture routed-build:  /parallel-feature <brief>
        waves of feature-executor (5-part spec + House Rules verbatim)
        → CodeRabbit APPROVED → garage review gate (code reviewers on the PR diff)
        → user-testable merge checkpoints → final bar-judge vs ## Done Bar
    posture loop:        orchestration lanes ⇄ bar-judge until BAR VERDICT: MET
```

Gates are arithmetic, not judgment — every reviewer ends with a machine-parsed verdict line, and merged verdicts are sums:

| Emitter | Final line |
|---|---|
| Plan-time reviewer fragment | `FRAGMENT VERDICT: BLOCKING=<n> ADVISORY=<m>` |
| `/review plan` merged | `VERDICT: BLOCKING=<n> ADVISORY=<m>` |
| Code-time reviewer fragment | `FRAGMENT VERDICT: CRITICAL=<n> HIGH=<n> MEDIUM=<n> LOW=<n>` |
| `/review code` merged | `VERDICT: CRITICAL=<n> HIGH=<n> MEDIUM=<n> LOW=<n>` |
| bar-judge | `BAR VERDICT: MET` / `BAR VERDICT: NOT MET \| FAILURES=<n>` |
| Brief gate | `REVIEW GATE: PASSED \| round=<n> \| BLOCKING=0 \| ADVISORY=<m>` |

The compounding map: `/brief` reuses `/review plan`'s reviewer fragments as its gate and the `advisor` as its architecture skeptic; `/parallel-feature` reuses `/review code`'s fragments as its PR gate, the `advisor` on repeated failures, and `bar-judge` as its final act; `/visualize-plan` picks briefs up from `docs/specs/` with no arguments; the `orchestration` skill routes everything smaller than a workstream.

## What's inside

### Skills

| Skill | Description |
|---|---|
| `/brief <rough ask>` | Turn a rough ask into a review-gated brief at `docs/specs/<slug>.md` — goal, house rules, measurable Done Bar, workstream specs, user-testable merge checkpoints. The harness's contract artifact. |
| `spec-writing` | Prose + precision standard for any spec/brief/design doc: ASD-STE100 Simplified Technical English rules for the sentences, a "spec is code" precision bar for the content (four-questions rule, contract tables, Given/When/Then acceptance, ambiguity audit). Composes with `/brief`: brief template governs structure, spec-writing governs prose. |
| `/review plan [<path>]` | Review a feature description (or a plan file) before coding and produce a requirements checklist ending in a machine-parsed verdict |
| `/review code` | Review code changes for violations across quality pillars (auto-detects stack), verdict line included |
| `/visualize-plan` | Generate a self-contained HTML "visual companion" for one or more PRD/TRD markdown files — flowcharts, ERD, state machines, deployment topology, live-feel API reference. Uses the Liti mobile design system. |
| `/parallel-feature <spec path>` | Execute a spec/plan across parallel workstreams — worktree-isolated `feature-executor` subagents, one PR each, gated on CodeRabbit approval + the garage review gate, with merge-checkpoint announcements and a final bar-judge pass. |
| `orchestration` | Routing doctrine for architect-as-orchestrator sessions: which lane (implementer / opus / codex / feature-executor) gets which task, the 5-part spec contract, cost discipline, and the loop-until-bar posture. |

### Review agents

Specialized prompt fragments invoked internally by the skills above (not directly addressable by name). Each ends its output with a machine-parsed `FRAGMENT VERDICT:` line.

| Agent | Stack | What it checks |
|---|---|---|
| **Production Hardening** | Backend | Resilience, idempotency, durability |
| **Audit Compliance** | Backend | Soft deletes, change history, actor attribution |
| **Analytics Coverage** | Frontend/Mobile | Funnel coverage, event naming & taxonomy, event properties |
| **Security Controls** | Backend + Frontend/Mobile | OWASP / NIST / API Top 10, AuthN/AuthZ, injection, secrets, crypto, privacy/PII, supply chain |
| **Plan Requirements** | Any | Pre-coding requirements checklist |
| **Business Readiness** | Any | Rollout planning, dependency resilience, multi-tenant impact, data consent, migration |
| **Security Threat Modeling** | Any (plan-time) | Trust boundaries, AuthN/AuthZ design, data classification, supply chain trust, key management, abuse resistance |

### Execution & judgment agents

Directly-invokable named subagents (real frontmatter, spawned by `subagent_type`), used by the harness skills and standalone.

| Agent | Model | What it does |
|---|---|---|
| **feature-executor** | inherit | Implements one feature workstream end-to-end to the team Definition of Done: Linear branch, 5-row scenario matrix, 100% test coverage, PR via the host repo's PR skill, CodeRabbit-approved. Returns an evidence-bearing `EXECUTOR REPORT`. |
| **advisor** | fable | Read-only second-opinion skeptic for commitment boundaries — architecture, migrations, API shapes, problems that resisted two attempts. Verdict in under 300 words; never implements. |
| **implementer** | sonnet | Cheap implementation lane for fully-specified sub-PR tasks; escalate with `model="opus"` for subtle work. Consumes the 5-part spec, returns an `IMPLEMENTER REPORT` with verification evidence. |
| **codex-implementer** | sonnet (drives GPT-5.5) | Cross-vendor lane via the OpenAI Codex CLI — an independent model family for correctness-critical work. Fails loudly if `codex` is missing; never substitutes itself. |
| **bar-judge** | inherit | Fresh-context adversarial judge: takes a written Done Bar and the real output, tries to prove the bar is NOT met, returns `BAR VERDICT:` with evidence. Never fixes anything. |

## Project structure

```text
skills/           # Skill definitions (user-facing commands, one SKILL.md per directory)
agents/           # Agent prompts — 7 reviewer prompt fragments invoked by skills, plus 5
                   # directly-invokable named subagents (feature-executor, advisor,
                   # implementer, codex-implementer, bar-judge)
.claude-plugin/   # Plugin metadata and marketplace config
```

## Contributing

Add new skills to `skills/` and new agents to `agents/`. Open a PR so the team can review and iterate together.

## Credits

The `advisor`, `implementer`, and `codex-implementer` agents and the `orchestration` skill are vendored (with adaptations) from [fable-advisor](https://github.com/DannyMac180/fable-advisor) v2.1.0 by Dan McAteer, MIT License. Avoid installing the upstream fable-advisor plugin alongside this one — the implementer agent names collide. The harness's prompting principles (`skills/brief/reference/principles.md`) are distilled from the article "How I Prompt Fable".

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
