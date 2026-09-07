## Why

Company and job descriptions are plain text, so companies cannot structure
their story (headings, lists, links) and job ads look flat. Authors already
think in structured text; letting them write plain Markdown — rendered nicely
by the app — removes the ceiling without adding editor complexity.

## What Changes

- Company description (`career_page.description`, edited in Settings → Brand)
  and job description (`jobs.description`, edited in the job form) accept
  plain Markdown in a regular textarea (no toolbar, no live preview).
- Both are rendered as sanitized HTML on public pages: top of `/:slug/careers`
  (company) and `/:slug/careers/:job_id` (job detail, replacing the
  `whitespace-pre-wrap` plaintext block).
- Renderer: Markdown → HTML via MDEx (CommonMark, maintained), then a strict
  sanitizer allowlist (no raw scripts/iframes/forms) because these pages are
  public.
- Rendered output is styled with a small dedicated CSS scope (no Tailwind
  Typography plugin; the existing dead `prose` class is replaced or wired).
- Existing plaintext descriptions are re-rendered as-is; minor reflow of
  single line breaks is accepted (no migration of old texts).
- Out of scope: logo expiry fix (separate change), WYSIWYG toolbar, live
  preview, new fields (single-field approach: existing `description` columns).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `career-page`: company description rendered from Markdown (sanitized) at the top of the public career page.
- `job-management`: job description authored as plain Markdown.
- `public-job-board`: job description rendered from Markdown (sanitized) on the public job detail page.

## Impact

- New deps: `mdex` (direct), an HTML sanitizer allowlist library.
- Touched: branding settings form, job form, public career index + job detail
  templates, `app.css` (render scope).
- No migrations expected (`:string` columns already unbounded).
