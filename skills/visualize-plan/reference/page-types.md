# Page-type contracts (mini-site)

Each canonical sub-page has a known shape. Pick which optional sections to include based on plan content; the page identity, headings, and order are fixed.

For single-page output, the same sections exist but live in one long-scroll HTML with a sticky top TOC instead of the side menu.

---

## `index.html` — overview / menu

**Always present.** This is the entry point and discovery hub for the mini-site.

### Required sections
- `#hero` — title + subtitle + eyebrow + source-doc badges + last-updated stamp
- `#tldr` — synopsis paragraph + KPI grid (3-4 cards with the most concrete numbers from the plan)
- `#sources` — one card per source markdown (filename, line count, audience, contents bullets)
- `#contents` — grid of chapter cards, one per sub-page in this mini-site, with one-line summaries

### Optional sections
- `#journey` — customer / user journey strip (when plan describes one)
- `#highlights` — 2-3 callouts surfacing the most important design decisions

### Side menu special case
The `index.html` breadcrumb shows `<span class="breadcrumb">Spec name</span>` (no link, no arrow) since you're already at the root. Other pages use `<a class="breadcrumb" href="index.html">← Spec name</a>`.

---

## `architecture.html` — system shape

### Required
- `#overview` — the high-level architecture SVG flowchart (with legend showing layer color-coding)

### Optional
- `#subdomains` — subdomain / module layout SVG
- `#extensibility` — comparison cards (today vs future) when the plan claims pluggability

---

## `flows.html` — workflows and async behavior

Pick ≥1, often all three.

### Optional sections (pick relevant ones)
- `#saga` — workflow / saga flowchart with branching outcomes
- `#idempotency` — idempotency / safety layers, rendered as nested concentric layers
- `#webhook-lifecycle` — sequence / lane diagram for webhooks, RPCs, async events

If the plan has only one of these, the page still belongs (don't merge with `architecture.html`). If none apply, drop the page entirely.

---

## `data-model.html` — schema and state

Pick ≥1.

### Optional sections
- `#erd` — entity-relationship diagram, color-coded by subdomain, lock badge on append-only tables
- `#state-machine` — status enum + state machine SVG + 3rd-party-status mapping table when applicable

---

## `api.html` — REST surface

**Mandatory when the plan introduces ≥1 new REST endpoint.**

### Required sections
- `#api-summary` — KPI strip: endpoint count, resource groups, content-type, version
- `#api-toc` — sticky-within-section sub-TOC grouped by resource (Catalog / Orders / Webhooks / etc.) — every endpoint as a jump-link with method pill + path
- One `<article id="api-<slug>">` per endpoint using the API endpoint card snippet

### Per-endpoint card content
- Method pill + path (color by HTTP verb)
- 1-2 sentence description
- Auth / middleware row
- Request body sample (preformatted JSON code block)
- Response body sample (200/201/202 case)
- Status-code table: code · meaning · when it fires
- Optional error-body sample
- Webhook endpoints get same card + signature-verification notes + "what happens after 401 vs 204"

See [`snippets.md`](snippets.md) for the exact HTML pattern.

---

## `deployment.html` — process and infra

### Required when introduced
- `#topology` — deployment topology SVG with shared-infra band

### Optional
- `#cross-domain` — connection-string table when service holds multiple DBs
- `#migrations` — migrations + CI/CD card
- `#cutover` — cutover plan when migrating off existing infra

---

## `roadmap.html` — execution plan

**Always present in mini-site mode.**

### Required sections
- `#prs` — PR / task dependency graph (DAG) SVG with execution-mechanism legend (single agent vs parallel agents vs no agent)
- `#prereqs` — out-of-band prerequisites table (numbered, with "blocks PR X" pills, owner column)

### Optional
- `#open-questions` — pending decisions list (callout style)
- `#verification` — manual verification checklist (when plan calls one out)

---

## Side menu structure

Every sub-page has the same `<aside class="side-menu">`. See [`snippets.md`](snippets.md) for the exact HTML.

Two nav blocks inside:
- **Pages** — full list of sub-pages in this mini-site. The current page's `<a>` carries `class="current"`.
- **On this page** — anchors mirroring the `id` of every `<section>` in the current main column, listed in document order. Use the section's `<h2>` text as the link label.

On mobile (≤ 900px), the side menu collapses to a horizontal top nav (handled by the shell CSS — no per-page work needed).

---

## When NOT to create a page

If a page would have only one section that fits naturally elsewhere, fold it into another page:
- Lone `#extensibility` with no other architecture content → put on `index.html` as a `#highlights` callout.
- Lone `#cross-domain` with no `#topology` → put on `architecture.html` as a callout.
- Lone `#open-questions` with no `#prereqs` → put on `index.html`.

The skill rejects empty pages — every sub-page must have ≥2 substantive sections OR be one of the always-present pages (`index`, `roadmap`).
