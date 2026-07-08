---
name: orchestration
description: Routing doctrine for the architect-as-orchestrator pattern — how a session running the smartest model delegates implementation to cheaper, cross-vendor, or workstream lanes to minimize cost while gating quality with fresh-context judges. USE WHEN delegating implementation work, choosing between implementer/codex-implementer/feature-executor lanes, escalating a subagent to opus, writing a spec for a subagent, deciding whether to consult advisor, running the loop-until-bar posture, or managing session cost on any multi-task build where the session is the architect.
---

<!-- Adapted from fable-advisor v2.1.0 (https://github.com/DannyMac180/fable-advisor) by Dan McAteer, MIT License. Garage adaptations: workstream + adversarial-check lanes, lane boundary vs /parallel-feature, loop-until-bar posture. -->

# Orchestration — the architect's routing doctrine

The session is the architect: it owns requirements, architecture, decomposition, specs, routing, and verification. It should almost never type implementation code. Every implementation task gets routed to the cheapest lane that is adequate for it — escalation is deliberate, per task, never a fixed binding.

The principles behind this doctrine live in [`../brief/reference/principles.md`](../brief/reference/principles.md).

## Cost discipline — the prime directive

The session model is the most expensive lane in the system, on both input and output tokens. The whole economic case for this pattern is keeping its token volume low: spend the top model on judgment, spend cheap models on volume. Three rules follow.

**Emit judgment, not volume.** The architect's output is decomposition, specs, routing decisions, verdicts on diffs, and short reports. It does not type implementation code, test bodies, boilerplate, or config files. A code block longer than an interface signature or a few illustrative lines is a spec that hasn't been delegated yet — stop and delegate it. Fixing an implementer's bug by hand is the same failure in disguise: send a corrected spec back to the cheap lane instead.

**Keep the context lean.** Everything in the architect's context is re-read at architect prices on every turn. Delegate broad exploration, codebase searches, and log-grepping to a cheap read-only agent and keep only the conclusions; read files yourself only when the decision genuinely depends on the exact code. Don't paste long files, full diffs, or verbose command output into the conversation when a path reference or an excerpt will do.

**Reason once, then hand off.** Do the hard thinking — the architecture, the interface design, the debugging hypothesis — in one pass, capture it in the spec, and let the cheap lane carry it from there. Re-deriving decisions across turns burns the premium twice.

What stays with the architect regardless of cost: decomposition, interface design, hypothesis selection when debugging, spec writing, lane routing, and judging verification evidence. Those tokens are what the premium is for — everything else is a candidate for delegation.

## The lanes

| Lane | Producer | Invoke | Route here when |
|---|---|---|---|
| Routine | Sonnet | `implementer` agent (frontmatter default) | The spec fully determines the outcome: boilerplate, wiring, CRUD, mechanical edits, straightforward features. **Default lane.** |
| Subtle | Opus | `implementer` with `model="opus"` | A Sonnet miss is expensive: concurrency, non-trivial algorithms, security-sensitive paths, hard debugging, wide-blast-radius refactors. |
| Cross-vendor | GPT-5.5 | `codex-implementer` agent | Correctness/completeness is critical enough to want a different model family, or you want an independent implementation to compare against a Claude lane. Requires the codex CLI. |
| Workstream | inherit | `feature-executor` agent — usually via `/parallel-feature` | The unit of work needs its own branch, PR, and CodeRabbit-approved Definition of Done. Not a sub-task — a shippable workstream. |
| Judgment | Fable 5 | `advisor` agent | Not an implementation lane. See "Commitment boundaries" below. |
| Adversarial check | inherit | `bar-judge` agent | Deciding whether output meets a written Done Bar. **Never the builder** — always a fresh context pointed at the real output. |

Deciding rule: how much does the outcome depend on judgment the spec can't capture? None → Sonnet. Some, and mistakes are costly → Opus. When two lanes seem equal, take the cheaper one — you will verify anyway.

**Lane boundary vs `/parallel-feature`.** Implementer lanes are for sub-PR-sized tasks in the current working tree — pieces of a workstream the architect is assembling, quick fixes, mechanical changes. Anything that ships as its own PR with the team's Definition of Done is workstream-shaped: route it to `feature-executor`, normally through `/parallel-feature`, which owns Linear issues, worktree isolation, wave ordering, and review gates. This doctrine defers to `/parallel-feature` for that scale; don't rebuild its machinery out of implementer calls.

Opus vs codex is not a capability question — it's a failure-distribution question. Opus buys *more* capability within the same model family; codex buys a *different* family whose blind spots don't overlap Claude's. Route to codex when same-family review is the risk, or when you'll race both lanes and pick the stronger diff.

If the codex lane returns `unavailable` or `timeout`, re-route the same spec to the Opus lane and say so explicitly in your report — never quietly absorb the downgrade, because the caller may have chosen that lane for vendor diversity.

## The spec contract

Implementers share none of your conversation context. Every delegation prompt carries all five parts:

1. **Objective** — what to build or change, one paragraph
2. **Files** — exact paths to create or modify
3. **Interfaces** — signatures, types, or API shapes the code must match
4. **Constraints** — project conventions, things not to touch; include the brief's `## House Rules` verbatim when working from a brief
5. **Verification** — the command(s) that prove it works

A spec you can't finish writing is a signal the decision isn't made yet — that's architect work, not a reason to hand the ambiguity to a cheaper model.

## Parallelism

Independent specs (no shared files, no ordering dependency) launch as parallel agents in a single message. Sequential chains and single-file surgery stay serial. For high-stakes work, a pick-the-stronger-diff race — `implementer` and `codex-implementer` on the same spec, architect judges — buys cross-vendor confidence for one extra lane's cost.

## Commitment boundaries

Consult `advisor` (read-only, verdict in under 300 words) at the moments that decide whether the next hour is wasted:

- Before committing to an architecture, data migration, API shape, or refactor strategy
- Whenever the same problem has resisted two distinct attempts
- Once before declaring a multi-step deliverable done

Pass it the decision, the constraints, and the options considered. Act on the verdict or surface the disagreement — never silently ignore it. (If the session itself already runs on the top model, the advisor still earns its keep as a context-clean skeptic reading the actual code.)

## Loop posture (loop-until-bar)

For briefs marked `Posture: loop` — a single scoped deliverable with a crisp, runnable Done Bar (often creative or foundational work) — run this cycle from the main session:

1. Write the 5-part spec from the brief (House Rules verbatim in Constraints; the Done Bar drives Verification).
2. Route to a lane and verify the lane's evidence per the rules below.
3. Spawn `bar-judge` — fresh context, context-free prompt: the brief's `## Done Bar` plus a pointer to the real output. Never the lane that built it.
4. `BAR VERDICT: MET` → done. `BAR VERDICT: NOT MET` → send a **corrected spec** back to the same lane, quoting the judge's failure evidence as new constraints. Go to 2.
5. Cap at **3 cycles**. Still NOT MET → consult `advisor` with the spec, the failures, and what was tried; act on its verdict or surface to the user.

The builder never decides it's finished — the judge does, or the user does.

## Verification

Reports are claims, not evidence. Before accepting any lane's work: read the diff, and re-run the verification command (or spot-check its quoted output against the working tree). "Should work", "tests should pass", or a report with no command output means the task is not done. An implementer that reports a spec gap gets a corrected spec, not a "use your judgment".
