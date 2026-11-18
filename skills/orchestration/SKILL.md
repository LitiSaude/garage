---
name: orchestration
description: How the session decides whether to delegate a piece of implementation to a subagent or do it itself, how to brief a worker that shares none of the conversation (the five-part spec), how to check what comes back, when to consult `advisor`, and how to run the loop-until-bar posture. USE WHEN deciding whether to delegate implementation, picking a model or effort for a worker, writing a prompt for a worker subagent, checking a subagent's report, deciding whether to consult advisor, or executing a brief marked `Posture: loop`.
---

<!-- Adapted from fable-advisor (https://github.com/DannyMac180/fable-advisor) by Dan McAteer, MIT License. Originally vendored from v2.1.0; the delegation guidance follows the v7.3.0 rewrite. Garage adaptations: no dedicated implementer agents, workstream boundary vs /parallel-feature, loop-until-bar posture with bar-judge. -->

# Orchestration — delegating, briefing, and judging work

The session owns the requirements, the design, the specs, and the judgment of evidence. Whether it also writes a given piece of code, or hands that piece to a subagent, is a call it makes from the costs below. Neither is the default.

Garage ships no implementer agent. When you delegate implementation, use Claude Code's built-in general-purpose subagent through the Agent tool, and choose the model and effort on the call.

The principles behind the harness are in `${CLAUDE_PLUGIN_ROOT}/skills/brief/reference/principles.md`. Garage's agents are registered under the plugin namespace: spawn them as `liti-garage:advisor`, `liti-garage:bar-judge`, and `liti-garage:feature-executor`.

## What delegation costs, and when it pays

- **A worker starts from nothing.** It re-reads the files it needs. You pay session-model prices to write its brief and to read its report and diff.
- **Delegation does not make the answer better.** A subagent runs the same model as the session or a smaller one. A fresh context helps for review, because the reviewer has not seen your reasoning. It does not help for building.
- **Judge by cost per finished, verified task.** A cheap call that comes back wrong and needs a second round can cost more than doing the work yourself.
- **Measured upstream.** fable-advisor compared a session that delegated to cheaper workers against the same session working alone (v7.3.0, 2026-11-15, two runs per task). Delegating cost about 2.8× more on small tasks and about 12% more on one larger task, with the same pass rate. Most of the spend was the session's own overhead for specs, merges, and review, not the workers. No saving was measured at either size.

Delegation pays when:

- the work is large next to its brief: a feature or test suite that would take you well beyond a few minutes, or the same mechanical edit across many files;
- independent pieces can run at the same time;
- a search would read many files whose contents you do not need afterwards. Give it to a read-only agent such as Explore and keep only the conclusion;
- you want a judge that has not seen the work (`bar-judge`, `advisor`, a reviewer).

It does not pay when:

- you can see the change and make it in fewer tokens than the brief would take: a one-line fix, a rename in a file you have already read, a small correction to a worker's diff;
- the hard part is a judgment you would have to write out in full in the brief anyway;
- you would read the same two or three files to write the brief as to make the change.

If you keep patching one worker's output, the brief was missing a decision or the worker was the wrong model. Fix that, not the diff.

**Workstream-sized work goes to `/liti-garage:parallel-feature`.** Anything that ships as its own PR with the team's Definition of Done belongs to `feature-executor`, normally through `/liti-garage:parallel-feature`, which owns Linear issues, worktree isolation, wave ordering, and review gates. Do not rebuild that machinery out of ad-hoc subagent calls. This skill covers pieces smaller than a workstream, in the current working tree.

**Write decisions down once.** Put the architecture, the interface choices, and the debugging hypothesis into the brief, so the worker does not have to re-derive them. Revisit a decision when a report, a test, or a review contradicts it, or when you see it was wrong.

## Choosing the model and effort

Pass `model` on every implementation call, and `effort` where the Agent tool accepts it. A subagent started without a model usually inherits the session's model, so an unpinned worker on a top-model session runs at top-model prices.

- **The brief fully determines the outcome** (wiring, CRUD, mechanical edits, straightforward features): a smaller model such as `sonnet`, at low or medium effort.
- **The outcome depends on judgment the brief cannot carry, and a miss is expensive** (concurrency, non-trivial algorithms, security-sensitive paths, hard debugging, wide refactors): a stronger model at high effort, or keep the piece yourself.
- **A worker that fails once** gets a corrected brief. If it fails twice, move it to a stronger model or do it yourself.

**A second model family.** Garage no longer ships its own Codex lane. If the OpenAI Codex plugin (`codex@openai-codex`) is installed, use it when a deliverable touches security-sensitive code, a migration, or an API shape and you want a check from outside the Claude family: `/codex:adversarial-review` on the diff, or `/codex:rescue` for an independent attempt at a problem. If the plugin is missing, say so instead of substituting a Claude subagent, because the point of asking was the different model family.

## Briefing a worker: the five-part spec

A worker shares none of your conversation. Every implementation prompt carries all five parts. This is the same contract `/liti-garage:brief` writes for each workstream and `feature-executor` consumes.

1. **Objective** — what to build or change, in one paragraph.
2. **Files** — the exact paths to create or modify.
3. **Interfaces** — the signatures, types, or API shapes the code must match.
4. **Constraints** — project conventions and what not to touch. When working from a brief, include its `## House Rules` verbatim.
5. **Verification** — the command or commands that prove it works.

Also say what you want back, because the worker's final message is all you will see: the files it changed with a one-line summary each, the verification command it ran with the actual output, and every decision it made that the spec did not.

If you cannot finish writing the spec, the decision is not made yet. Make it before you delegate.

## Parallel work

Independent specs (no shared files, no ordering dependency) can go out as parallel Agent calls in one message. Specs that touch the same files run one after another.

## Checking what comes back

A report is a claim, not evidence. Before you accept a worker's result:

- read the diff. An empty diff means nothing was done, whatever the report says;
- re-run the verification command, or check the quoted output against the working tree;
- treat a report with no command output as not done;
- answer a reported spec gap with a corrected spec, not with "use your judgment". The gap is a decision that belongs to you.

## Commitment boundaries

Consult `advisor` (read-only, verdict in under 300 words) when a wrong call would waste the next stretch of work:

- before committing to an architecture, data migration, API shape, or refactor strategy;
- when the same problem has resisted two distinct attempts;
- once before declaring a multi-step deliverable done.

Give it the decision, the constraints, and the options you considered. Act on the verdict, or tell the user where you disagree and why. When the session already runs on the top model, the advisor is the same model with a clean context: it still catches what the conversation's assumptions hid, but it is not a second model's opinion.

## Loop posture (loop-until-bar)

For briefs marked `Posture: loop` — a single scoped deliverable with a crisp, runnable Done Bar — run this cycle from the main session:

1. **Build toward the Done Bar.** Do the work yourself or delegate pieces of it, as the costs above suggest. Any spec you hand to a worker carries the brief's House Rules verbatim, and its Verification comes from the Done Bar.
2. **Check the evidence** as described above, for delegated pieces and for your own.
3. **Spawn `bar-judge`** in a fresh context, with a prompt that contains only the brief's `## Done Bar` and a pointer to the real output.
4. **`BAR VERDICT: MET`** → done. **`BAR VERDICT: NOT MET`** → fix what the judge's evidence shows failed, then go to 2.
5. **Stop after 3 cycles.** If the bar is still not met, consult `advisor` with the bar, the failures, and what was tried. Act on its verdict or bring the decision to the user.

Whoever built the output does not decide that it is finished. The judge does, or the user does.
