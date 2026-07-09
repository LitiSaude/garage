---
name: parallel-feature
description: execute a spec/plan across parallel workstreams — worktree-isolated subagents, one PR each, gated on CodeRabbit approval plus the garage review gate.
---

# /parallel-feature — Parallel Workstream Execution

Drive a spec/plan to done by fanning it out into parallel, worktree-isolated `feature-executor` workers — one per workstream, one PR each, gated on CodeRabbit approval and the garage review gate. This is the orchestration procedure; `agents/feature-executor.md` is the worker identity it spawns.

## Usage

- `/parallel-feature <spec path>` — parse the spec at the given path and execute it.
- `/parallel-feature <spec path> --model sonnet` — spawn every `feature-executor` worker with the given model override while you (the orchestrator) keep reviewing at your own model.
- `/parallel-feature <spec path> --garage-review off` — skip the garage review gate (step 5); CodeRabbit remains the only PR gate.

## Procedure

1. **Parse the spec.** Read the workstream table and dependency graph from `<spec path>` (e.g. a "Workstreams & dependency graph" / "Parallel execution plan" section — the exact heading varies by spec, find the table that maps workstreams to repos, branches, and dependencies). Derive the wave structure from the dependency edges: a workstream is Wave 1 if it depends on nothing, Wave N if its dependencies are all in waves < N.

   **Briefs produced by `/brief` are the native input.** Recognize them by their structure: a `## Workstreams & Dependency Graph` table with columns `| ID | Workstream | Repo | Depends on | Linear issue | Checkpoint |`, per-workstream `### WS-<n>:` five-part spec blocks under `## Workstream Specs`, `## House Rules`, `## Merge Checkpoints`, `## Done Bar`, and a `## Review Gate` section. Check the review-gate line: `REVIEW GATE: WAIVED` means the brief shipped with unresolved blocking gaps — warn the user which gaps were waived and get explicit confirmation before executing. No `REVIEW GATE:` line at all means the brief was never gated — point the user at `/brief` before proceeding (they may still choose to run ungated). Generic specs without this structure remain fully supported.

2. **Ensure a Linear issue per workstream.** For every workstream in the table, confirm a Linear issue already exists or create one. Capture each issue's `gitBranchName` — this is what the corresponding `feature-executor` will branch from, not a name you invent.

3. **Spawn Wave 1.** Launch one `feature-executor` agent per Wave-1 workstream, in a single message so they run concurrently. For each:
   - `subagent_type: "feature-executor"`, `isolation: "worktree"` (own worktree — never let two workstreams share a working tree).
   - If the workstreams span more than one repo (e.g. a backend repo and a mobile repo), give each worker its own worktree in its own repo — do not mix repos in one worktree.
   - The prompt is self-contained and carries the five-part spec contract (Objective, Files, Interfaces, Constraints, Verification). From a brief, paste the workstream's `### WS-<n>:` block **verbatim**, plus the brief's `## House Rules` **verbatim** (non-negotiable, additive to the host repo's own docs). From a generic spec, synthesize only the parts the spec actually determines (its own file/module/endpoint names) and label everything else `ASSUMPTION:` in the spawn prompt — the executor's contract treats unlabeled inferences as givens, and silent guesses violate it. If too much is missing to write a credible spec block, stop and suggest running `/brief` first. Always include the Linear issue and `gitBranchName`, the dependencies (already satisfied), and a pointer to the full spec for context. Do not delegate understanding — an executor that has to guess what to build got a broken prompt.
   - If a `--model` override was given, pass it through as the `model` parameter on each spawn.

4. **Each workstream returns only when CodeRabbit-approved.** A `feature-executor` reports done only after its PR reaches CodeRabbit APPROVED (its own Definition of Done, not something this skill re-checks). Do not treat a worker's return as done until you've confirmed the reported approval state.

5. **Garage review gate** (skip only with `--garage-review off`). When a workstream returns CodeRabbit-approved, run the `/review code` procedure from this session against that PR's diff: scope the reviewers to `gh pr diff <pr> --name-only`, fan out the code reviewer fragments as fresh-context `general-purpose` subagents exactly as `skills/review/SKILL.md` specifies, and read the merged verdict line. The gate passes on `VERDICT: CRITICAL=0 HIGH=0` (the verdict is the arithmetic sum of fragment verdicts — never re-judged by you). CRITICAL or HIGH findings bounce to the owning executor per step 7; after its fix lands and CodeRabbit re-approves, re-run this gate. If one workstream fails this gate **twice**, consult the `advisor` agent with the findings and the workstream spec before a third attempt — the spec itself may be wrong. Never spawn reviewer fan-outs from inside an executor; this gate runs only from this session.

6. **Gate each subsequent wave on the prior wave's full approvals.** Do not spawn Wave 2 workers until every Wave 1 workstream they depend on is CodeRabbit-approved **and — when the garage review gate is enabled — has passed that gate** (merged or ready-to-merge, per the spec's own merge-order expectations); with `--garage-review off`, CodeRabbit approval alone advances the wave. Repeat spawn → wait → confirm per wave until the last wave is done. When a brief defines `## Merge Checkpoints`, announce each checkpoint as its workstreams land: tell the user exactly what is now user-testable end-to-end and how to exercise it — a checkpoint nobody can test is a decomposition bug to surface, not to skip past.

7. **Bounce problems back to the owning executor, never forward.** If a PR comes back CHANGES_REQUESTED, fails the garage review gate, or a later wave hits a merge conflict against an earlier wave's landed changes, send it back to the worker (or spawn a follow-up in the same worktree/branch) that owns that workstream. Never patch another workstream's branch to route around it, and never let a downstream wave "absorb" an upstream problem.

8. **After the last wave, run the spec's end-to-end verification, then judge the bar.** Run the spec's "Verification" section (manual smoke test, harness run, cross-repo integration check) once every wave has landed. Then, if the spec has a `## Done Bar`, spawn the `bar-judge` agent — fresh context, prompt containing only the Done Bar and pointers to the real output (repo, branches/PRs, running app). `BAR VERDICT: NOT MET` → bounce each failure to its owning executor **once**; if the re-judge still fails, surface the remaining failures to the user rather than looping.

Maintain a live status table for the whole run:

```text
| Workstream | Repo | Branch | PR | CodeRabbit | Garage review | Bar |
|---|---|---|---|---|---|---|
| WS-1 ...   | ...  | ...    | #… | approved / pending / changes-requested | passed / pending / findings / off | met / not-met / — |
```

## Notes

- **Token cost.** Every parallel worker is a full agent run. Running many workstreams concurrently multiplies token spend roughly linearly with the number of workers — don't over-parallelize a spec that doesn't actually need it. The garage review gate adds 3–4 reviewer subagents per workstream PR; that's what `--garage-review off` is for on low-stakes runs.
- **Merge order matters.** Land waves in dependency order. A later wave built against an unmerged earlier wave's code will conflict or fail to compile; don't let waves race ahead of what's actually merged.
- **The CodeRabbit poll is a gate only you can run.** No hook can read a bot's review verdict — this skill (or the `feature-executor` it spawns) must poll `gh pr view` / equivalent itself. Treat "PR opened" and "PR approved" as two different milestones; only the second unblocks a dependent wave.
- **`/batch` is not the engine here, and workers never call it.** `/batch` auto-decomposes one homogeneous change into N generic worktree workers, each opening a PR — a flat, dependency-free fan-out. This skill's job is the opposite shape: a heterogeneous dependency DAG with waves, possibly spanning multiple repos, gated on CodeRabbit, executed by a specific `feature-executor` identity that `/batch` has no way to express. `/batch` remains available only as a **leaf tactic**: if one workstream is itself a large mechanical multi-file change (e.g. a sweeping rename across hundreds of files), the `feature-executor` handling that single workstream may shell out to `/batch` for that one mechanical step. The orchestrator never invokes `/batch` directly, and a `feature-executor` never fans out into more workers of its own — it owns exactly one workstream.
