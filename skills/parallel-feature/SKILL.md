---
name: parallel-feature
description: execute a spec/plan across parallel workstreams — worktree-isolated subagents, one PR each, gated on CodeRabbit.
---

# /parallel-feature — Parallel Workstream Execution

Drive a spec/plan to done by fanning it out into parallel, worktree-isolated `feature-executor` workers — one per workstream, one PR each, gated on CodeRabbit approval. This is the orchestration procedure; `agents/feature-executor.md` is the worker identity it spawns.

## Usage

- `/parallel-feature <spec path>` — parse the spec at the given path and execute it.
- `/parallel-feature <spec path> --model sonnet` — spawn every `feature-executor` worker with the given model override while you (the orchestrator) keep reviewing at your own model.

## Procedure

1. **Parse the spec.** Read the workstream table and dependency graph from `<spec path>` (e.g. a "Workstreams & dependency graph" / "Parallel execution plan" section — the exact heading varies by spec, find the table that maps workstreams to repos, branches, and dependencies). Derive the wave structure from the dependency edges: a workstream is Wave 1 if it depends on nothing, Wave N if its dependencies are all in waves < N.

2. **Ensure a Linear issue per workstream.** For every workstream in the table, confirm a Linear issue already exists or create one. Capture each issue's `gitBranchName` — this is what the corresponding `feature-executor` will branch from, not a name you invent.

3. **Spawn Wave 1.** Launch one `feature-executor` agent per Wave-1 workstream, in a single message so they run concurrently. For each:
   - `subagent_type: "feature-executor"`, `isolation: "worktree"` (own worktree — never let two workstreams share a working tree).
   - If the workstreams span more than one repo (e.g. a backend repo and a mobile repo), give each worker its own worktree in its own repo — do not mix repos in one worktree.
   - The prompt is self-contained: the workstream's scope, its Linear issue and `gitBranchName`, its dependencies (already satisfied), and a pointer to the full spec for context. Do not delegate understanding — state explicitly what this workstream must build, referencing the spec's own file/module/endpoint names.
   - If a `--model` override was given, pass it through as the `model` parameter on each spawn.

4. **Each workstream returns only when CodeRabbit-approved.** A `feature-executor` reports done only after its PR reaches CodeRabbit APPROVED (its own Definition of Done, not something this skill re-checks). Do not treat a worker's return as done until you've confirmed the reported approval state.

5. **Gate each subsequent wave on the prior wave's approvals.** Do not spawn Wave 2 workers until every Wave 1 workstream they depend on is CodeRabbit-approved (merged or ready-to-merge, per the spec's own merge-order expectations). Repeat spawn → wait → confirm per wave until the last wave is done.

6. **Bounce problems back to the owning executor, never forward.** If a PR comes back CHANGES_REQUESTED, or a later wave hits a merge conflict against an earlier wave's landed changes, send it back to the worker (or spawn a follow-up in the same worktree/branch) that owns that workstream. Never patch another workstream's branch to route around it, and never let a downstream wave "absorb" an upstream problem.

7. **After the last wave, run the spec's end-to-end verification.** Specs that define this kind of parallel execution plan typically also define a "Verification" section (manual smoke test, harness run, cross-repo integration check) — run it once every wave has landed.

Maintain a live status table for the whole run:

```
| Workstream | Repo | Branch | PR | CodeRabbit |
|---|---|---|---|---|
| PR-A ...   | ...  | ...    | #… | approved / pending / changes-requested |
```

## Notes

- **Token cost.** Every parallel worker is a full agent run. Running many workstreams concurrently multiplies token spend roughly linearly with the number of workers — don't over-parallelize a spec that doesn't actually need it.
- **Merge order matters.** Land waves in dependency order. A later wave built against an unmerged earlier wave's code will conflict or fail to compile; don't let waves race ahead of what's actually merged.
- **The CodeRabbit poll is a gate only you can run.** No hook can read a bot's review verdict — this skill (or the `feature-executor` it spawns) must poll `gh pr view` / equivalent itself. Treat "PR opened" and "PR approved" as two different milestones; only the second unblocks a dependent wave.
- **`/batch` is not the engine here, and workers never call it.** `/batch` auto-decomposes one homogeneous change into N generic worktree workers, each opening a PR — a flat, dependency-free fan-out. This skill's job is the opposite shape: a heterogeneous dependency DAG with waves, possibly spanning multiple repos, gated on CodeRabbit, executed by a specific `feature-executor` identity that `/batch` has no way to express. `/batch` remains available only as a **leaf tactic**: if one workstream is itself a large mechanical multi-file change (e.g. a sweeping rename across hundreds of files), the `feature-executor` handling that single workstream may shell out to `/batch` for that one mechanical step. The orchestrator never invokes `/batch` directly, and a `feature-executor` never fans out into more workers of its own — it owns exactly one workstream.
