# Spec Template and Precision Requirements

Default section skeleton for a standalone spec, with the precision bar each section must clear. When another structure governs (a `/brief` run, a host repo with its own spec convention), keep that structure and apply the precision bar to the matching sections.

The bar comes from one principle: **a decision the spec is silent on is a decision delegated to chance** — the implementer (human or agent) will invent it, and inventions diverge.

Precision means explicit decisions, not code. Express contracts as tables, states as transition tables, behavior as Given/When/Then. Code blocks stay out of specs except to settle a critical implementation decision.

## Skeleton

```
# <Title — the capability, not the task>

## Problem            (business-first: who hurts, how much, why now)
## Solution overview  (the shape of the fix in ≤ 3 paragraphs; what is explicitly out of scope)
## Design
### <one subsection per component/flow>
## Acceptance criteria
## Open decisions     (the ambiguity audit)
## Testing
## Delivery           (slicing into PRs; follow host repo delivery conventions)
## Impact             (what changes for the business; how we measure it)
```

## Precision bar per section

### Problem
Business-first: name who is affected, quantify the pain if data exists, and state why now. No solution vocabulary here — if the Problem section mentions a table or an endpoint, it is describing the solution.

### Solution overview
The whole shape in ≤ 3 paragraphs. Then a **Not in scope** list — every adjacent capability a reader might assume is included and is not. Phase-2 material is one "Later:" line each, never a stub or a designed-but-deferred section.

### Design
For **every behavior**, the spec answers four questions. Silence on any of them is a spec bug:

1. **Happy path** — the normal flow, actor by actor.
2. **Error paths** — for each external call or validation: what fails, who observes it, what the user/caller sees.
3. **Empty/absent** — no rows, null field, first-ever run, entity without the relation.
4. **Duplicate/concurrent** — the same trigger twice; two actors racing. State the idempotency rule or why none is needed.

For **data contracts** (new tables, entity attributes, endpoint payloads) use a table, not code:

| Field | Type | Constraints | Nullable | Notes |
|---|---|---|---|---|

Record constraints where the host repo's architecture puts them (e.g. validation on the use-case contract vs. the entity).

For **lifecycles** (any noun with more than two statuses) give the transition table — every legal transition with actor and trigger. Transitions absent from the table are illegal; say so once above the table.

| From | To | Actor | Trigger |
|---|---|---|---|

For **endpoints**: method, route, auth/scope, request fields (table), response fields (table), each error status with its trigger condition. If the host system is multi-tenant, state the tenant-scoping rule for every read.

### Acceptance criteria
Given/When/Then scenarios, one block per feature slice — the executable face of the spec. Cover happy and unhappy paths; these seed the test scenario matrix and, for agent features, the harness scripts. A criterion that cannot be phrased as Given/When/Then is not yet a decision.

```
Given a patient with an active subscription and no co-prescription
When the daily eligibility cron runs
Then the patient's offer row has status "eligible"
```

### Open decisions (the ambiguity audit)
List every decision the spec still defers. Each row: the question, the options, the owner, and when it blocks. This section exists to be short — but writing "none" without having hunted is a smell. Hunt by re-reading Design against the four questions above.

### Testing
Point to the scenario coverage the implementation must produce, in the host repo's testing convention (e.g. pygeia's 5-row scenario matrix and 7-scenario partner-scope matrix). For agent features, name the harness and its gate.

### Delivery
PR slicing with order and dependencies. Follow host repo conventions (e.g. schema migrations ship in their own PR). Name the tracking issue per PR when known.

## Spec-complete checklist (gate before review)

- [ ] Every domain term checked against the host repo's glossary; new terms defined once at first use.
- [ ] Prose passes `ste-rules.md` — no "should", no actor-less passives, sentence caps respected.
- [ ] Every behavior answers the four questions (happy / error / empty / duplicate).
- [ ] Every new table, attribute, and payload has a contract table.
- [ ] Every multi-status noun has a transition table.
- [ ] Acceptance criteria cover happy and unhappy paths in Given/When/Then.
- [ ] Not-in-scope list present; phase-2 items are one-line "Later" notes.
- [ ] Open decisions section is the product of a hunt, not a placeholder.
- [ ] No code blocks except ones that settle a critical decision.
- [ ] Reads as a final document — no iteration deltas or conversational scars.
