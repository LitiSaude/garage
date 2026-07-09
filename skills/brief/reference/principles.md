# Prompting principles behind the harness

Distilled from the article **"How I Prompt Fable"**. Each principle maps to the garage mechanism that implements it — when writing a brief or orchestrating work, these are the "why" behind the pipeline's shape.

## 1. Give it the goal, not the steps

Dictating steps overrides the model's judgment with yours, and yours is usually worse. Hand big, underspecified goals; make room for the model to find the best path.

**In the harness**: a brief's `## Goal` states the outcome, never the implementation route. Workstream specs constrain the *what* (objective, files, interfaces) and the *bar*, not the how.

## 2. Set house rules so you can trust it

An underspecified goal is safe when fenced by a few rules that must always hold — the things you care about no matter how the goal is reached. Classic example: don't hard-code special cases into an agent; describe the behavior in its prompt and let it reason.

**In the harness**: a brief's `## House Rules` travel **verbatim** into every spawn prompt downstream (`feature-executor`, `implementer` lanes), so no worker ever acts outside them.

## 3. Give it a real bar for "done"

Adjectives ("high quality") let the model stop at its own idea of good enough. Replace them with a bar it can be checked against — measurable, concrete, hard. If you don't know how to measure the thing, make inventing the measuring stick part of the work.

**In the harness**: a brief's `## Done Bar` items must each be checkable by a command or an observable behavior. The `bar-judge` agent treats an unmeasurable item as a failure in itself.

## 4. Loop until it hits the bar

Once there's a bar, iterate against it: build, check, find the biggest gap, close it, go again. The builder never gets to decide it's finished — the loop ends when the bar is met or a human says stop.

**In the harness**: `/brief`'s review-gate loop re-drafts until reviewers report `BLOCKING=0` (≤3 rounds, then the user decides); the orchestration skill's loop posture cycles lane → `bar-judge` until `BAR VERDICT: MET` (≤3 cycles, then advisor, then the user).

## 5. The builder never grades its own work

Whatever built something is biased by its own trajectory — it has a whole history of "why I made these decisions" to justify that it's done. Grading belongs to a fresh context pointed at the real output.

**In the harness**: judge ≠ builder at every stage. Fragment reviewers gate `/brief` in fresh subagent contexts; garage code reviewers gate workstream PRs after CodeRabbit; `bar-judge` gates the Done Bar; `advisor` gates architecture decisions. Merged review verdicts are **arithmetic sums** of fragment verdicts — the session that authored the work never re-judges the numbers.

## 6. Build on what you've already done

Prior work is fuel: point new work at the last great artifact ("here's the code, here's the quality bar, match it and go beyond") instead of re-explaining from zero.

**In the harness**: briefs live in the host repo at `docs/specs/` — the next brief can reference the last one, and executed briefs double as templates. Point a new brief's House Rules or Done Bar at a previous feature's spec when the quality bar already exists.

---

Two article ideas live outside this file: *remove friction* (credentials, budgets, pre-delegated decisions) is the brief's optional `## Access & Authority` section; *spend heavy modes only on foundations* — reserve expensive maximum-effort passes (e.g. ultracode) for systems you'll build on for months, and let a good loop with an ambitious bar cover everything else.
