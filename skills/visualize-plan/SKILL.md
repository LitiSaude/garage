---
name: visualize-plan
description: Generate a "visual companion" for one or more PRD/TRD markdown files. Long specs become a multi-page mini-site with a sticky side menu (folder of self-contained HTML files); short specs become a single-page HTML. Both follow the Liti mobile design system and a fixed page-shell template so visuals stay consistent across the team.
---

# /visualize-plan — Visual Companion for PRD/TRD Markdown

Turn a markdown plan into a focused review surface — a multi-page mini-site for long specs, a single page for short ones. Both share the same page shell, design tokens, and snippet library so every spec the team produces looks like a sibling of the others.

## Usage

- `/visualize-plan <path-to-md> [<path-to-md> ...]` — explicit input(s).
- `/visualize-plan` — no args: scan `docs/specs/**/*.md` from the current branch's diff against `main` and ask the user which to include.

## When to use vs. NOT

**Use when:** PRD/TRD has architecture, workflows, state machines, deployment topology, or REST APIs that read better as diagrams than ASCII; or a long markdown is hard to scan; or paired spec + impl-plan need joint navigation.

**Don't use for:** bug-fix tickets, pure SQL migrations, code reviews (use `/review code`).

## Output mode — pick by content

| Mode | When |
|---|---|
| **Mini-site** (folder) | md > 300 combined lines · OR ≥1 new REST endpoint · OR plan covers ≥3 of {architecture, workflows, data model, deployment, API} |
| **Single page** (one file) | Everything else |

- **Mini-site folder name**: `<source-md-basename>-visual-companion/`
- **Single page filename**: `<source-md-basename>-visual-companion.html`
- Both live next to the source markdown.
- Both are idempotent: re-running overwrites in place.
- Files ending `-visual-companion.html` or folders ending `-visual-companion/` are auto-regeneratable — never hand-edit.

## Required building blocks (always present)

1. **Hero** — title, subtitle, eyebrow, source-doc badges, last-updated stamp.
2. **TL;DR + 3-4 KPI cards** with the most concrete numbers from the plan.
3. **Source-documents card** linking back to every input markdown.
4. **High-level architecture diagram** somewhere.
5. **Out-of-band prerequisites or open-questions** somewhere.
6. **Footer** with source links + "live artifact" note.

In a mini-site, (1)–(3) live on `index.html`, (4) on `architecture.html`, (5) on `roadmap.html`, (6) on every page.

## Behavior steps

1. **Read every input markdown end-to-end** with the Read tool. Don't summarize from headings.
2. **Decide output mode** using the table above.
3. **Decide which sub-pages / sections to include**. For mini-site: read [`reference/page-types.md`](reference/page-types.md) to see each page's contract. `index.html` and `roadmap.html` are mandatory; `api.html` is mandatory if the plan introduces ≥1 new REST endpoint.
4. **Read [`templates/shell.html`](templates/shell.html)** for the consistent page frame (CSS, side-menu structure, footer). Every page in a mini-site uses this verbatim.
5. **Read [`reference/snippets.md`](reference/snippets.md)** for the canonical building blocks (KPI tile, callout, API endpoint card, SVG arrow markers, lock badge, side menu) — copy verbatim, do not reinvent.
6. **Read [`reference/design-system.md`](reference/design-system.md)** for the design tokens, typography, SVG conventions, and color semantics.
7. **Read the canonical example** at [`examples/commerce-domain/`](examples/commerce-domain/) when you need a concrete pattern to copy. Treat its CSS / SVG / snippet patterns as the canon — when in doubt, match it.
8. **Write each file in one Write call**. Verify by counting `<section>` open vs close tags; if mini-site, check every cross-link in the side menu resolves to a sibling file.
9. **Report back** in 4-6 lines: where the output lives (file or folder), file count + total size, which optional sections were included with one-word rationale.

## Supporting files

- [`templates/shell.html`](templates/shell.html) — the consistent page frame with all CSS, side-menu skeleton, footer. Slot comments mark substitution points.
- [`reference/page-types.md`](reference/page-types.md) — per-page contracts (what `index`, `architecture`, `flows`, `data-model`, `api`, `deployment`, `roadmap` must contain + which sections are optional).
- [`reference/snippets.md`](reference/snippets.md) — copy-verbatim HTML/SVG patterns: KPI tile, callout, API endpoint card, method pills, status pills, SVG arrow markers, lock badge, side menu structure.
- [`reference/design-system.md`](reference/design-system.md) — Liti mobile design tokens (`:root` CSS), typography rules, SVG drawing conventions, color semantics, responsive breakpoints.
- [`examples/commerce-domain/`](examples/commerce-domain/) — canonical mini-site for ENG-8165 (~1340 combined md lines across spec + impl plan). Demonstrates all 7 page types. The visual canon — open with Read when unsure.

## Live artifact contract

The generated output is meant to be **re-generated** from the plan, not hand-edited. Re-running on the same input overwrites in place. Persistent custom tweaks belong in a sibling file, not inside the auto-regenerated output.
