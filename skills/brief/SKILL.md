---
name: brief
description: Turn a rough ask into a review-gated brief — the contract artifact the rest of the garage harness executes. Produces docs/specs/<slug>.md with a goal, house rules, a measurable Done Bar, workstream specs, and user-testable merge checkpoints; consults the advisor before the gate and loops the plan reviewers until zero blocking gaps. USE WHEN starting any feature bigger than a quick fix, when the user says "write a brief", "spec this out", "let's plan this feature", or hands you a rough idea to turn into executable work.
---

# /brief — from rough ask to review-gated contract

`/brief <rough ask | path-to-notes>`

The brief is the harness's contract artifact: everything downstream — `/visualize-plan`, `/parallel-feature`, `feature-executor`, `bar-judge` — consumes it by section name. Your job is to draft it, subject it to adversarial review by fresh-context judges, and hand it off. The principles behind every section are in [`reference/principles.md`](reference/principles.md).

## Procedure

1. **Gather.** Read the rough ask (or the notes file). Explore the host repo enough to name real files, modules, and conventions in the workstream specs. Ask the user questions **only** if the Goal or the Done Bar is genuinely indeterminable from what you have — everything else is your job to propose, their job to correct.

2. **Draft.** Read [`reference/template.md`](reference/template.md) and produce the brief at `docs/specs/<kebab-slug>.md` in the host repo (create the directory if missing; if the repo already keeps specs elsewhere by convention, follow the repo). Every section honors its contract paragraph in the template — most importantly: Goal is an outcome, House Rules are context-free, every Done Bar item is checkable, every Merge Checkpoint is user-testable end-to-end.

3. **Advisor consult — before the review gate.** Spawn the `advisor` agent (`subagent_type: "advisor"`) with the architecture decisions the brief commits to, the constraints, and the options you considered. Act on the verdict or surface the disagreement to the user — never silently ignore it. This happens *before* the review loop so a restructure can't invalidate a passed gate.

4. **Review-gate loop.** Run `/review plan docs/specs/<slug>.md` — the review skill's plan mode with the path argument, which fans out the three plan reviewers as fresh-context subagents that read the file themselves. Then:
   - The gate passes when the merged `VERDICT:` line shows `BLOCKING=0`. The verdict is the **arithmetic sum of the fragments' `FRAGMENT VERDICT:` lines** — you drafted this brief, so you don't get to re-judge the numbers.
   - `BLOCKING>0` → fix the draft (address or explicitly incorporate each blocking item) and re-run the review. **Maximum 3 rounds.**
   - Still blocking after round 3 → present the residual items to the user: they resolve them with you, or explicitly waive them.

5. **Close the gate.** Append the final round's summary to `## Review Gate`, ending with the machine-parsed line per the template: `REVIEW GATE: PASSED | round=<n> | BLOCKING=0 | ADVISORY=<m>`, or `REVIEW GATE: WAIVED | round=<n> | BLOCKING=<n> | user-approved` only after the user's explicit waiver.

6. **Re-consult the advisor only if** a review round restructured the workstream graph (added/removed/re-wired workstreams) — once, max. Two advisor calls per `/brief` run is the ceiling.

7. **Hand off.** Tell the user the brief is gated and offer the next stage:
   - `/visualize-plan docs/specs/<slug>.md` — optional stakeholder-readable companion (the no-arg mode also picks briefs up from `docs/specs/`).
   - Posture `routed-build` → `/parallel-feature docs/specs/<slug>.md`.
   - Posture `loop` → the orchestration skill's loop posture (`skills/orchestration/SKILL.md`), driving lanes against the Done Bar with `bar-judge`.

## Rules

- **Never instruct a subagent to run `/review`** or to spawn other agents — subagents can't nest. All fan-out happens from this session, exactly as the review skill does it.
- The gate is arithmetic. If a fragment's counts look wrong, re-run that reviewer; don't override the number.
- Goal over steps: if you catch yourself writing implementation sequence into the Goal or the Objectives, move the *what* into the spec fields and delete the *how*.
- Repo-relative paths only inside the brief — it's a shared artifact; absolute or machine-specific paths break it for everyone else.
- The brief is durable: correct it as decisions change (and re-gate if the change is structural), rather than letting it drift from reality.
