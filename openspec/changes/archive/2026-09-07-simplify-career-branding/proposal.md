## Why

The Brand settings page offers a logo upload and a primary color that are not
used on the company page, confusing admins ("what is this file for?"). At the
same time, the single centered description cannot hold a real company story.
Splitting the header into a short centered subtitle plus a full left-aligned
Markdown story — with a working preview next to the editor — makes the page
self-explanatory on both sides.

## What Changes

- Remove the logo file upload and the primary color picker from Brand
  settings (and their display on the public career pages, which become
  neutral: company name + subtitle, no colored band or logo).
- Remove the Published toggle: branding is always live. Public pages read
  the career page unconditionally instead of filtering on the flag.
- Keep the existing short description as a centered subtitle under the
  company name (plain text, as today).
- Add a new long-form `about` text (plain Markdown textarea, same renderer
  and styles as job descriptions) displayed as a left-aligned paragraph
  block below the header on the public career page.
- Add an Edit/Preview tab switcher to the Brand settings editor; the Preview
  tab renders title, subtitle, and about exactly as the public page does
  (live, reusing the existing form assign — no extra events needed).
- DB columns `logo_url`/`primary_color`/`published` stay untouched (no migration
  for the removals); the new `about` column requires a migration.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `branding`: settings form drops logo upload + color + Published toggle, gains about textarea and Edit/Preview tabs.
- `career-page`: public header shows name + centered subtitle + left-aligned Markdown about block, without logo or color band.

## Impact

- Migration: add `about` column to `career_pages` (via mix ecto.gen.migration).
- Modules under lib/treby: career page context/changeset (permit `about`).
- LiveViews: Brand settings (form + tabs + preview), public career index
  (header layout). Job detail company block keeps name + subtitle.
- Docs: user manual career/branding pages updated + screenshots regenerated.
