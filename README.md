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
| `/review plan` | Review a feature description before coding and produce a requirements checklist |
| `/review code` | Review code changes for violations across quality pillars (auto-detects stack) |
| `/visualize-plan` | Generate a self-contained HTML "visual companion" for one or more PRD/TRD markdown files — flowcharts, ERD, state machines, deployment topology, live-feel API reference. Uses the Liti mobile design system. |
| `/parallel-feature <spec path>` | Execute a spec/plan across parallel workstreams — worktree-isolated `feature-executor` subagents, one PR each, gated on CodeRabbit approval. |

### Review agents

Specialized prompt fragments invoked internally by the skills above (not directly addressable by name).

| Agent | Stack | What it checks |
|---|---|---|
| **Production Hardening** | Backend | Resilience, idempotency, durability |
| **Audit Compliance** | Backend | Soft deletes, change history, actor attribution |
| **Analytics Coverage** | Frontend/Mobile | Funnel coverage, event naming & taxonomy, event properties |
| **Security Controls** | Backend + Frontend/Mobile | OWASP / NIST / API Top 10, AuthN/AuthZ, injection, secrets, crypto, privacy/PII, supply chain |
| **Plan Requirements** | Any | Pre-coding requirements checklist |
| **Business Readiness** | Any | Rollout planning, dependency resilience, multi-tenant impact, data consent, migration |
| **Security Threat Modeling** | Any (plan-time) | Trust boundaries, AuthN/AuthZ design, data classification, supply chain trust, key management, abuse resistance |

### Execution agents

A directly-invokable named subagent (has real frontmatter, unlike the review agents above), meant to be spawned by name — typically by `/parallel-feature`, but usable standalone for a single workstream.

| Agent | Invocation | What it does |
|---|---|---|
| **feature-executor** | `subagent_type: "feature-executor"` | Implements one feature workstream end-to-end to the team Definition of Done: Linear branch, 5-row scenario matrix, 100% test coverage, PR via the host repo's PR skill, CodeRabbit-approved. Language/stack-agnostic — reads the host repo's own standards. |

## Project structure

```
skills/           # Skill definitions (user-facing commands, one SKILL.md per directory)
agents/           # Agent prompts — most are prompt fragments invoked by skills;
                   # feature-executor is a directly-invokable named subagent
.claude-plugin/   # Plugin metadata and marketplace config
```

## Contributing

Add new skills to `skills/` and new agents to `agents/`. Open a PR so the team can review and iterate together.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
