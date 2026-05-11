# Design system — Liti mobile

Locked tokens, typography rules, and SVG drawing conventions. Don't introduce new colors; if a section needs a new accent, derive it from these.

---

## Tokens — paste into `:root`

The full block lives at the top of [`templates/shell.html`](../templates/shell.html). For copy-paste:

```css
:root {
  /* brand */
  --primary:        #735ABF;
  --primary-dark:   #453281;
  --primary-light:  #B1A3DB;
  --primary-tint:   #ECE7F7;

  /* semantic */
  --success:        #59A679;
  --success-light:  #DEEDE4;
  --error:          #DA4167;
  --error-light:    #F7D4DD;
  --warning:        #E4CF67;
  --warning-light:  #FBF8E9;

  /* surface */
  --bg:             #F5F6FA;
  --surface:        #FFFFFF;
  --surface-alt:    #FAFAFC;

  /* text */
  --text-dark:      #100618;
  --text-strong:    #867D90;
  --text-light:     #BDB7C5;
  --text-on-brand:  #FFFFFF;

  /* stroke */
  --stroke:         #E6E3E8;
  --stroke-soft:    #BDB7C5;

  /* spacing scale (Liti) */
  --s-2:2px; --s-4:4px; --s-6:6px; --s-8:8px; --s-10:10px;
  --s-12:12px; --s-16:16px; --s-20:20px; --s-24:24px; --s-32:32px;
  --s-40:40px; --s-48:48px; --s-64:64px;

  /* radius scale (Liti) */
  --r-4:4px; --r-8:8px; --r-12:12px; --r-16:16px; --r-24:24px; --r-32:32px; --r-full:999px;

  /* typography */
  --ff-sans:'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --ff-mono:'JetBrains Mono', 'SF Mono', Consolas, monospace;

  /* layout */
  --side-menu-w:280px;
}
```

---

## Color semantics (when to use which)

| Color | Use for |
|---|---|
| Primary purple `#735ABF` | Main flow, current emphasis, links, primary buttons, active nav |
| Success green `#59A679` | Happy path, completed states, healthy, GET method |
| Warning yellow `#E4CF67` | Pending, audit, cron, decision-pending, async boundaries |
| Error red `#DA4167` | Failures, terminal failures, security risks, DELETE method |
| Slate `#100618` | Terminal nodes, external systems, code blocks (background), headers |
| Body `#F5F6FA` | Page background |
| Surface `#FFFFFF` | Card backgrounds, surface above body |

Avoid `#000000` and `#FFFFFF` for foreground/background combos that aren't `--text-on-brand`. Use the tokens.

---

## Typography rules

| Element | Family | Size | Weight | Notes |
|---|---|---|---|---|
| h1 | Outfit | 40px | 600 | letter-spacing -0.025em |
| h2 | Outfit | 28px | 600 | letter-spacing -0.02em |
| h3 | Outfit | 18px | 600 | letter-spacing -0.01em |
| h4 | Outfit | 13px | 600 | uppercase, letter-spacing 0.02em |
| h5 | Outfit | 11px | 600 | uppercase, letter-spacing 0.05em, used for `<pre>`/section labels |
| Body p | Outfit | 16px | 400 | line-height 1.5 |
| Lede p | Outfit | 18px | 400 | color `--text-strong`, max-width 780px |
| Eyebrow | JetBrains Mono | 11px | 500 | uppercase, letter-spacing 0.12em, color `--primary` |
| KPI number | JetBrains Mono | 36px | 600 | color `--primary`, line-height 1 |
| Code inline | JetBrains Mono | 0.9em | 400 | bg `--bg`, padding 1px 5px, radius `--r-4` |
| Code block | JetBrains Mono | 12px | 400 | bg `#100618`, color `#F5F6FA`, line-height 1.55 |
| SVG box label | JetBrains Mono | 11px | 500-600 | inside boxes |
| SVG annotation | Outfit | 12px | 400 | color `#867D90`, outside boxes |

Load via Google Fonts at the top of the `<style>` block:

```css
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
```

---

## SVG drawing conventions

### General rules
- All SVG inline. No external `<image>` tags pulling in PNG/JPG.
- Use `viewBox` (no fixed `width`/`height` attributes); CSS forces `width:100%; height:auto; display:block` so SVGs scale.
- No drop shadows. No gradients (except the hero's `linear-gradient` background).
- Define arrow markers per-SVG in a `<defs>` block, namespaced by section (`arrow-saga`, `arrow-arch`) to avoid collisions when multiple SVGs share a page.

### Stroke widths
- `1.5` — neutral elements, default
- `2` — emphasis (current section, primary flow, active boundary)
- `1` — auxiliary annotations, faint connections

### Rectangles and rounded corners
- `rx="10"` — default for boxes
- `rx="8"` — small chips and pills inside SVGs
- `rx="12"` — large container cards
- `rx="14"` or `rx="16"` — outer envelopes only

### Hand-drawn aesthetic
- No anti-aliased perfection; keep it clean but not industrial.
- Prefer single-color fills with stroked borders over filled gradients.
- Use semantic color via tokens (purple = primary, green = OK, yellow = warning, red = error, slate = external).

### Common patterns

**Process box** (rect + label):
```xml
<rect x="X" y="Y" width="W" height="H" rx="10" fill="#FFFFFF" stroke="#735ABF" stroke-width="1.5"/>
<text x="cx" y="cy" font-size="11" font-weight="600" fill="#100618" text-anchor="middle">label</text>
```

**Decision diamond** (path):
```xml
<path d="M cx Y_top L X_right cy L cx Y_bot L X_left cy Z" fill="#FFFFFF" stroke="#735ABF" stroke-width="1.5"/>
```

**Database cylinder**:
```xml
<ellipse cx="cx" cy="top" rx="rx" ry="12" fill="#FFFFFF" stroke="#735ABF" stroke-width="1.5"/>
<rect x="left" y="top" width="W" height="H" fill="#FFFFFF" stroke="#735ABF" stroke-width="1.5"/>
<ellipse cx="cx" cy="bot" rx="rx" ry="12" fill="#FFFFFF" stroke="#735ABF" stroke-width="1.5"/>
<line x1="left" y1="top" x2="left" y2="bot" stroke="#735ABF" stroke-width="1.5"/>
<line x1="right" y1="top" x2="right" y2="bot" stroke="#735ABF" stroke-width="1.5"/>
```

**Terminal node** (filled slate):
```xml
<rect x="X" y="Y" width="W" height="H" rx="10" fill="#100618"/>
<text x="cx" y="cy" font-size="14" font-weight="600" fill="#FFFFFF" text-anchor="middle">label</text>
```

---

## Spacing & radius scales (Liti)

Use the CSS variables, never hardcode pixel values:

- Spacing: `--s-2` through `--s-64` (2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 64)
- Radius: `--r-4` through `--r-32` plus `--r-full` (4, 8, 12, 16, 24, 32, 999)

Common combinations:
- Card padding: `var(--s-24)`
- Section padding y: `var(--s-32)` to `var(--s-48)`
- Grid gap: `var(--s-12)` for tight, `var(--s-16)` default, `var(--s-20)` for cards
- Card radius: `var(--r-16)` for content cards, `var(--r-12)` for KPIs, `var(--r-8)` for chips, `var(--r-full)` for pills/badges

---

## Responsive breakpoints

Single breakpoint at **900px**. Below this:
- `.shell` flex direction switches to `column` — side menu becomes top nav
- Grid cards collapse to single column
- Hero meta moves below content
- h1 shrinks to 32px, h2 to 22px

The shell CSS handles all of this; per-page work is unnecessary.

---

## Accessibility floor

- Body text must hit ≥ 4.5:1 contrast on its background. Token combinations in this file pass.
- Links have a visible underline (`border-bottom`) — don't remove.
- All interactive elements get `:hover` feedback (background-color or opacity transition).
- SVG-only diagrams need a `<div class="svg-caption">` describing what they show, for screen readers / when SVG fails to render.
