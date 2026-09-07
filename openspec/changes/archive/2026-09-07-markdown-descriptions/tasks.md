## 1. Dependencies & renderer

- [x] 1.1 Add `earmark` + `html_sanitize_ex` as direct deps (`mix deps.get`)
- [x] 1.2 Add `TrebyWeb.Markdown.to_safe_html/1` (Earmark → strict allowlist sanitize) with unit tests (formatting kept, `<script>`/`javascript:` URLs stripped)
- [x] 1.3 Add `<.markdown text={...} />` component reusing the renderer

## 2. Styling

- [x] 2.1 Add hand-written `.md-content` scope in `assets/css/app.css` (headings, lists, links, code; light + dark), no `@apply`, no Typography plugin
- [x] 2.2 Replace dead `prose` wrapper on job detail with `.md-content`

## 3. Authoring hints

- [x] 3.1 Add "Supports Markdown…" hint under Brand description textarea
- [x] 3.2 Add same hint under job description textarea(s)

## 4. Display swap

- [x] 4.1 Career index top: render company description via `<.markdown>`
- [x] 4.2 Career job detail: render job + company descriptions via `<.markdown>`
- [x] 4.3 Internal job detail: render description via `<.markdown>`

## 5. Verify

- [x] 5.1 `mix precommit` clean, full suite green, translation catalog complete
