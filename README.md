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

### Agents

| Agent | Stack | What it checks |
|---|---|---|
| **Production Hardening** | Backend | Resilience, idempotency, durability |
| **Audit Compliance** | Backend | Soft deletes, change history, actor attribution |
| **Analytics Coverage** | Frontend/Mobile | Funnel coverage, event naming & taxonomy, event properties |
| **Plan Requirements** | Any | Pre-coding requirements checklist |
| **Business Readiness** | Any | Rollout planning, dependency resilience, multi-tenant impact, data consent, migration |

## Project structure

```
skills/           # Skill definitions (user-facing commands, one SKILL.md per directory)
agents/           # Specialized agent prompts used by skills
.claude-plugin/   # Plugin metadata and marketplace config
```

## Contributing

Add new skills to `skills/` and new agents to `agents/`. Open a PR so the team can review and iterate together.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
