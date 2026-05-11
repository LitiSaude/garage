# Snippet library — copy verbatim

These are the canonical building blocks. Do NOT reinvent per spec. If a new pattern is needed, add it to this file first, then use it.

---

## KPI tile

For TL;DR strips, API summaries, anywhere a big number wants attention.

```html
<div class="kpi">
  <div class="kpi-num">5</div>
  <div class="kpi-label">New tables · two append-only at the DB level</div>
</div>
```

Wrap multiple in `<div class="grid-4">` (or `grid-3` for 3-up).

---

## Callout (3 variants)

```html
<div class="callout">
  <div class="callout-label">Opaque routing principle</div>
  Body text. Use <code>code</code> for symbols.
</div>

<div class="callout success">
  <div class="callout-label">What stays unchanged</div>
  Body text.
</div>

<div class="callout warning">
  <div class="callout-label">Async boundary</div>
  Body text.
</div>
```

---

## Side menu (every mini-site sub-page)

The breadcrumb is the spec name. On `index.html` it's a plain `<span>` (no link, no arrow). On every other page it's `<a class="breadcrumb" href="index.html">← Spec name</a>`.

```html
<aside class="side-menu">
  <div class="side-menu-top">
    <a class="breadcrumb" href="index.html">← Commerce Domain</a>
    <div class="spec-meta">
      <span class="eyebrow">ENG-8165 · v0.2</span>
      <span class="last-updated">Updated 2026-05-09</span>
    </div>
  </div>
  <nav class="side-menu-pages">
    <h4>Pages</h4>
    <ul>
      <li><a href="index.html">Overview</a></li>
      <li><a href="architecture.html">Architecture</a></li>
      <li><a href="flows.html">Flows</a></li>
      <li><a href="data-model.html" class="current">Data model</a></li>
      <li><a href="api.html">API reference</a></li>
      <li><a href="deployment.html">Deployment</a></li>
      <li><a href="roadmap.html">Roadmap</a></li>
    </ul>
  </nav>
  <nav class="side-menu-anchors">
    <h4>On this page</h4>
    <ul>
      <li><a href="#erd">Entity-relationship</a></li>
      <li><a href="#state-machine">State machine</a></li>
    </ul>
  </nav>
</aside>
```

---

## Chapter card (index page only)

For the `#contents` grid linking to each sub-page.

```html
<a href="architecture.html" class="chapter-card">
  <div class="chapter-num">Chapter 01</div>
  <div class="chapter-title">Architecture</div>
  <div class="chapter-desc">High-level system flowchart, three-subdomain layout, and how new channels / pharmacies plug in without API churn.</div>
  <div class="chapter-arrow">architecture.html →</div>
</a>
```

Wrap in `<div class="grid-3">`.

---

## Page header (every page except index)

```html
<header class="page-header">
  <div class="page-eyebrow">Chapter 03 · Data model</div>
  <h1>Data model</h1>
  <p class="lede">Five new tables · two append-only at the DB level. UPDATE/DELETE revoked via Alembic migration on the application role.</p>
</header>
```

---

## Hero (index page or single-page mode)

```html
<header class="hero">
  <div class="hero-grid">
    <div>
      <div style="font-family:var(--ff-mono); font-size:11px; font-weight:500; text-transform:uppercase; letter-spacing:0.12em; color:var(--primary); margin-bottom:var(--s-12)">ENG-8165 · Visual companion · v0.2</div>
      <h1>Spec Name</h1>
      <p class="subtitle">One-sentence scope.</p>
      <div class="hero-badges">
        <span class="badge"><span class="badge-dot"></span>Spec — what / why</span>
        <span class="badge"><span class="badge-dot olive"></span>Implementation plan — how / in what order</span>
        <span class="badge"><span class="badge-dot warning"></span>Live artifact — updates as plans evolve</span>
      </div>
    </div>
    <div class="hero-meta">
      <b>Last updated</b>2026-05-09<br>
      <b style="margin-top:var(--s-12)">Source branches</b>
      branch-1<br>
      branch-2
    </div>
  </div>
</header>
```

---

## API endpoint card

The full pattern. Every endpoint on `api.html` uses this skeleton.

```html
<article id="api-<slug>" class="api-endpoint">
  <div class="api-endpoint-head">
    <span class="api-method post">POST</span>
    <span class="api-path">/v1/cart/quote</span>
    <span class="api-tag">PR 5b</span>
  </div>
  <p class="api-desc">One-sentence purpose.</p>
  <div class="api-meta">
    <span><b>Auth</b>Clerk · customer</span>
    <span><b>Rate</b>quote-tier</span>
    <span><b>Body</b>extra="forbid"</span>
  </div>
  <div class="api-block">
    <h5>Request body</h5>
    <pre class="code">{
  "items": [{ "sku": "...", "quantity": 1 }],
  "postal_code": "01310-100"
}</pre>
  </div>
  <div class="api-block">
    <h5>Response · 200</h5>
    <pre class="code">{
  "items": [...],
  "total_cents": 3580
}</pre>
  </div>
  <div class="api-block">
    <h5>Status codes</h5>
    <table class="api-status-table">
      <tr><td><span class="pill pill-success">200</span></td><td>OK</td><td>quote returned</td></tr>
      <tr><td><span class="pill pill-warning">422</span></td><td>Unprocessable</td><td>unknown sku · empty items</td></tr>
      <tr><td><span class="pill pill-error">503</span></td><td>Upstream</td><td>provider timeout / 5xx</td></tr>
    </table>
  </div>
</article>
```

For syntax-coloring inside `<pre class="code">`, use these spans:
- `<span class="k">{</span>` — punctuation/braces (purple `#B1A3DB`)
- `<span class="s">"key"</span>` — strings (green `#DEEDE4`)
- `<span class="n">123</span>` — numbers / booleans (yellow `#E4CF67`)
- `<span class="c">// comment</span>` — comments (gray italic `#867D90`)

Use sparingly — don't bother coloring every token, just the few that need attention.

---

## Method pill colors

| Verb | Class |
|---|---|
| GET | `<span class="api-method get">GET</span>` |
| POST | `<span class="api-method post">POST</span>` |
| PUT | `<span class="api-method put">PUT</span>` |
| PATCH | `<span class="api-method patch">PATCH</span>` |
| DELETE | `<span class="api-method delete">DELETE</span>` |

Backgrounds and borders defined in shell CSS; just use the right class.

---

## Status-code pill colors (in api-status-table)

- `2xx` → `<span class="pill pill-success">200</span>`
- `3xx` → `<span class="pill pill-muted">302</span>`
- `4xx` → `<span class="pill pill-warning">422</span>`
- `5xx` → `<span class="pill pill-error">503</span>`

---

## API sub-TOC (top of `api.html`)

```html
<div class="api-toc">
  <div class="api-toc-group">
    <h4>Catalog</h4>
    <div class="api-toc-list">
      <a href="#api-list-products"><span class="api-method get">GET</span> /v1/products</a>
      <a href="#api-get-product"><span class="api-method get">GET</span> /v1/products/{sku}</a>
      <a href="#api-cart-quote"><span class="api-method post">POST</span> /v1/cart/quote</a>
    </div>
  </div>
  <div class="api-toc-group">
    <h4>Orders</h4>
    <div class="api-toc-list"> ... </div>
  </div>
</div>
```

---

## SVG arrow markers (per-section defs)

Drop into the `<defs>` of each SVG. Replace `{section}` with the section name (e.g., `arch`, `saga`, `webhook`) so `id`s don't collide across multiple SVGs on the same page.

```xml
<defs>
  <marker id="arrow-{section}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
    <path d="M0,0 L10,5 L0,10 z" fill="#735ABF"/>
  </marker>
  <marker id="arrow-{section}-ok" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
    <path d="M0,0 L10,5 L0,10 z" fill="#59A679"/>
  </marker>
  <marker id="arrow-{section}-err" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
    <path d="M0,0 L10,5 L0,10 z" fill="#DA4167"/>
  </marker>
  <marker id="arrow-{section}-warn" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
    <path d="M0,0 L10,5 L0,10 z" fill="#E4CF67"/>
  </marker>
</defs>
```

Then on lines: `marker-end="url(#arrow-{section})"`.

---

## Lock badge (append-only marker on ERD tables)

```xml
<g transform="translate(X, Y)">
  <rect x="0" y="0" width="40" height="20" rx="10" fill="#100618"/>
  <text x="20" y="14" font-size="9" font-family="JetBrains Mono, monospace" fill="#FFFFFF" text-anchor="middle">LOCK</text>
</g>
```

---

## Table (general)

```html
<table>
  <thead>
    <tr><th>Column</th><th>Column</th><th>Column</th></tr>
  </thead>
  <tbody>
    <tr><td class="mono">value</td><td><span class="pill pill-primary">PILL</span></td><td>description</td></tr>
  </tbody>
</table>
```

`td.mono` for monospace cells; `pill pill-{primary|success|warning|error|muted}` for badges.

---

## Clean bulleted list

```html
<ul class="clean">
  <li>Item with optional <code>code</code></li>
  <li>Another item</li>
</ul>
```

Renders with a small purple dash bullet, not a disc.

---

## Footer (every page)

```html
<footer class="page-footer">
  <div class="footer-grid">
    <div>
      <h4>Source documents</h4>
      <ul>
        <li><a href="../source.md">source.md</a> · spec</li>
        <li><a href="https://linear.app/...">Linear · TICKET-ID</a></li>
      </ul>
    </div>
    <div>
      <h4>About this document</h4>
      <p style="color:var(--text-light); font-size:14px; line-height:1.6">A multi-page mini-site companion. Auto-regeneratable via <code style="background:transparent; color:var(--primary-light)">/visualize-plan</code>.</p>
      <p style="color:var(--text-light); font-size:13px; margin-top:var(--s-12); font-family:var(--ff-mono)">Visual identity · Liti mobile design system<br>Outfit · #735ABF · #59A679</p>
    </div>
  </div>
</footer>
```
