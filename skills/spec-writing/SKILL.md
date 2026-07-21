---
name: spec-writing
description: Write or revise any spec, plan, brief, or design doc using ASD-STE100 Simplified Technical English writing rules plus a precision bar ("a sufficiently detailed spec is code"). Produces prose that non-native speakers and LLM implementers parse reliably, and content precise enough that the implementer never has to invent a decision. USE WHEN writing or editing a file under docs/specs/, drafting a /brief, or when a reviewer calls a spec ambiguous. Composes with /brief: the brief template governs structure, this skill governs the prose and the precision bar.
---

# Spec Writing — STE prose + "spec is code" precision

Use this skill whenever you write or revise a spec-like artifact (plan, brief, design doc, RFC). It exists for two reasons:

1. **Readability**: specs are read by non-native English speakers and by LLM implementers. ASD-STE100 (Simplified Technical English) writing rules produce prose both parse reliably. STE is the aerospace standard for maintenance documentation — the highest-stakes "implementer must not misread this" domain there is.
2. **Precision**: a vague spec defers decisions to the implementer, and every deferred decision is a bug waiting to be invented. A sufficiently detailed spec is functionally code — implementation becomes mechanical. This matters double when the implementer is an agent: AI output quality is proportional to spec precision.

The two layers are orthogonal and both required: STE governs *how sentences are written*; the precision bar governs *what content must exist*. STE alone makes a vague spec pleasant to read; precision alone makes a complete spec unreadable.

## Supporting files

1. **[`reference/ste-rules.md`](reference/ste-rules.md)** — 16 STE rules adapted for spec prose, with ✗/✓ examples and an anti-pattern table. Apply to every sentence as you write, not as a cleanup pass.
2. **[`reference/spec-template.md`](reference/spec-template.md)** — section skeleton and the precision bar per section (four-questions rule, contract tables, transition tables, Given/When/Then acceptance criteria, ambiguity audit, spec-complete checklist).

## Workflow

1. **Vocabulary first.** List the domain terms the spec will use. If the host repo has a glossary (e.g. pygeia's `docs/code-standards/ubiquitous-language.md`), check every term against it — the glossary is the STE dictionary: one term, one meaning, one part of speech, everywhere. If there is no glossary, define each new term once at first use and never use a synonym for it.
2. **Skeleton second.** Structure comes from the host context: a `/brief` run uses the brief template; a standalone spec uses the skeleton in `reference/spec-template.md`, adapted to how the host repo already writes specs. Fill Problem and Solution overview before Design — if you cannot state the problem in ≤ 3 STE-compliant paragraphs, you do not understand it yet.
3. **Write in STE.** The rules that pay the most: active voice with a named actor, one requirement per sentence, conditions before effects, "must" (never "should"), sentence caps (20 words for requirements, 25 for description), no parenthetical asides.
4. **Precision pass.** For each behavior in Design, answer the four questions: happy path, error paths, empty/absent input, duplicate/concurrent trigger. Record the answers in the spec — a decision the spec is silent on is a decision delegated to chance.
5. **Ambiguity audit.** List every decision the spec still defers (the template has an "Open decisions" section). Each entry is decided now or explicitly delegated with a named owner. An empty audit written without a hunt is a smell, not an achievement.
6. **Spec-complete gate.** Run the checklist at the bottom of `reference/spec-template.md` before presenting the spec for review (or before the `/brief` review gate).

## Boundaries

- Precision means explicit decisions and contracts — **not code blocks**. Express data models as tables, states as transition tables, behavior as Given/When/Then. Code appears only to settle a critical implementation decision.
- Specs read as **final documents** describing the target system. No iteration deltas or conversational scars ("Removed X", "as discussed", "this now resolves…" belong in the conversation or PR, not the spec).
- Phase 1 is the minimum shippable slice; deferred work is a one-line "Later" note, never a stub or a designed-but-deferred section.
- Host repo conventions win over this skill's defaults (spec location, section names, delivery conventions such as migrations shipping in their own PR).

## Red flags to refuse

Stop and rewrite if you catch yourself:

- Using two words for one concept ("customer" here, "patient" there, same entity).
- Writing "should", "could be", "ideally", "as needed", "handle X", "etc." in a requirement.
- Writing a passive-voice requirement with no actor ("the offer is retired" — by whom? when?).
- Describing only the happy path of a behavior.
- Pasting a code block to avoid writing a precise sentence.
- A sentence you must read twice. If you re-read it, the implementer will misread it.
