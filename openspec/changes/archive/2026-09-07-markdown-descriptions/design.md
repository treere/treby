# Design: Markdown descriptions

## Context

Both editable descriptions are already plain `<textarea>` inputs bound to
unbounded `:string` columns (`career_page.description`,
`jobs.description`), and both are displayed as escaped plaintext
(`whitespace-pre-wrap`). So the change is render-side only: no form changes
(except a hint label), no migrations.

## Decisions

- **D1: MDEx + sanitize-after-render.** `MDEx.to_html!/1` converts
  Markdown to HTML (Earmark was evaluated first but its 1.4.x line is retired
  with a known stored-XSS CVE, which fails the repo's `hex.audit` gate);
  output always passes through an HTML sanitizer with a strict allowlist
  (p, h1–h4, ul/ol/li, strong/em, a[href(http/https only)], blockquote,
  code/pre, hr, br). Sanitizing after render (not relying on the parser's
  HTML handling) is the XSS boundary for public pages.
- **D2: One renderer, one component.** New `TrebyWeb.Markdown.to_safe_html/1`
  (Markdown → sanitized `{:safe, html}`) plus a `<.markdown text={...} />`
  function component, reused in all three display spots: career index
  (company), career job detail (job + company), internal job detail.
- **D3: Hand-written `.md-content` CSS scope, no Typography plugin.** Small
  rule set in `assets/css/app.css` (headings scale, list markers, link color,
  code blocks) following the repo's dark-mode convention (`data-theme`
  attribute with media fallback). No `@apply` per repo rules. Replaces the
  dead `prose` wrapper class on the job detail page.
- **D4: Authoring stays plain textarea.** Only addition is a short hint under
  each textarea ("Supports Markdown: **bold**, *italic*, lists, [links](…)").
  No toolbar, no live preview — per explicit user choice.
- **D5: No migration of old texts.** Single `\n` reflow accepted; no
  backfill. New deps `mdex` + `html_sanitize_ex` added as direct
  dependencies. Note: `mdex` is a Rust NIF (precompiled binaries fetched at
  compile time); it was already in the tree via storybook.

## Risks

- Earmark version API drift (`as_html/2` options) — pin and verify at
  implementation; sanitizer makes output safe regardless.
- Overly strict allowlist could strip content authors expect (e.g. tables).
  Start minimal (no tables/images); extend only on request. Images excluded
  deliberately (logo upload covers branding; no image hosting for body text).
