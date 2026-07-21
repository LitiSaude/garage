# STE Writing Rules for Specs

Adapted from ASD-STE100 Issue 9 (Simplified Technical English). STE has two parts: 53 writing rules and a ~900-word controlled dictionary. For specs we adopt the **rules** in full spirit; the **dictionary** is replaced by the host repo's glossary (e.g. pygeia's `docs/code-standards/ubiquitous-language.md`) plus a plain-English preference — a spec cannot restrict domain vocabulary to 900 words, but it can enforce STE's core dictionary principle: **one word, one meaning, one part of speech**.

Rules are grouped as STE groups them. Each rule has a ✗/✓ pair from real spec situations.

## 1. Words

**R1. One term, one meaning, everywhere.** Check every domain term against the host repo's glossary if one exists. Never alternate synonyms for style.
- ✗ "The customer's offer expires… the patient then sees…" (same person, two terms)
- ✓ "The patient's offer expires… the patient then sees…"

**R2. Use the simplest accurate word.** Prefer the STE-style choice: use (not utilize/leverage), start (not initiate/commence), end (not terminate), send (not transmit/dispatch), show (not display/surface), do (not perform/execute), make sure (not ensure/guarantee).

**R3. Technical names are allowed and must stay verbatim.** API routes, table names, enum values, workflow names keep their exact code spelling (`purchase_offer_eligibility`, `subscription_status = 'active'`). Never paraphrase an identifier.

**R4. Define a new term once, at first use, then reuse it unchanged.** If the spec coins a concept ("refill proof"), give it a one-sentence definition in the Problem or Solution section, then use exactly that term.

## 2. Verbs and voice

**R5. Active voice with a named actor.** Every requirement names who/what acts. Passive voice hides the actor, and the actor is usually the decision.
- ✗ "The offer is retired after 30 days."
- ✓ "The daily cron retires the offer 30 days after `inserted_at`."

**R6. Simple tenses only.** Present for facts and behavior ("the interactor rejects"), future only for genuinely future events, imperative for instructions. No progressive forms.
- ✗ "The worker is going to be polling the queue."
- ✓ "The worker polls the queue every 60 seconds."

**R7. Requirement verbs are a closed set.** *must* = requirement; *can* = capability/permission; present tense = fact of the design. Never *should*, *may*, *might*, *ideally*, *is expected to* in normative text. If you want to write "should", decide: is it a requirement (must) or optional (can / "Later" note)?

**R8. No modal chains.** "should be able to be configured" → "an operator can configure".

## 3. Sentences

**R9. Length caps.** Requirements and instructions: ≤ 20 words. Descriptive sentences: ≤ 25 words. When a sentence exceeds the cap, split it — do not compress it by dropping words.

**R10. One requirement per sentence.** "and" joining two behaviors is two sentences.
- ✗ "The endpoint validates the CPF and enrolls the patient and sends the welcome message."
- ✓ "The endpoint validates the CPF. If the CPF is valid, it enrolls the patient. After enrollment, it sends the welcome message."

**R11. Conditions before commands/effects.** State the condition first, so the reader knows the scope before the action.
- ✗ "Hide the purchase button when the patient has a co-prescription."
- ✓ "If the patient has a co-prescription, hide the purchase button."

**R12. Do not omit words to save space.** Keep articles and verbs; telegraph style creates ambiguity ("cron retires offer patient inactive" — which noun does "inactive" modify?).

**R13. Noun clusters: 3 words maximum.** Break longer clusters with prepositions.
- ✗ "the partner offer eligibility backfill cron failure monitor"
- ✓ "the monitor for failures of the cron that backfills offer eligibility"

**R14. Vertical lists for more than two items.** Sequences, alternatives, and field enumerations go in bullet or numbered lists, not comma chains. Each list item obeys the sentence rules.

## 4. Paragraphs

**R15. One topic per paragraph, ≤ 6 sentences.** Start with the topic sentence. If a paragraph covers two components, split it.

**R16. Constraints and warnings go before the design they constrain.** Mark them visibly (**Constraint:**, **Gotcha:**) and place them where the reader meets the affected design — not in a trailing "notes" section they read after forming the wrong mental model.

## 5. Anti-patterns (instant rewrite triggers)

| You wrote | Problem | Rewrite as |
|---|---|---|
| "should" | requirement or not? | "must" or "can" or delete |
| "etc.", "and so on" | unbounded list = unspecified behavior | enumerate, or state the closed rule |
| "as needed", "appropriately", "properly" | judgment deferred to implementer | state the criterion |
| "handle X" | what does handling mean? | state the exact behavior on X |
| "is retired/updated/sent" (no actor) | who does it, when? | name actor + trigger |
| "robust", "seamless", "simple" | marketing, not spec | delete or state the measurable property |
| "e.g." in a normative sentence | example ≠ rule | state the rule; examples go in a separate sentence |
