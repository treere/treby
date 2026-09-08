## Context

The Brand editor (`SettingsLive.Branding`) edits a `CareerPage` (title,
description, primary_color, logo_url, published) with a static preview that
only mirrors title/description/color. The public career index renders a
colored band (primary_color) with logo, title, and centered description.
Logo/Color turn out to be unused in practice, while the description cannot
carry a real company story. The Markdown renderer (`TrebyWeb.Markdown` +
`<.markdown>` + `.md-content`) from the previous change is reused as-is.

## Goals / Non-Goals

**Goals:**
- Brand form contains only: title, subtitle, about. No logo upload, no
  color picker, no Published toggle (branding is always live).
- Public header is neutral (no color band, no logo): name, centered
  subtitle, left-aligned Markdown about.
- Editor preview matches the public result via an Edit/Preview switch.

**Non-Goals:**
- Removing `logo_url`/`primary_color` columns (kept, unused — avoids a
  destructive migration; may be dropped in a later cleanup).
- Touching the job detail company block beyond dropping logo/color display.
- Logo storage expiry fix (separate problem, separate change).

## Decisions

- **D1: `description` stays the subtitle, new `about` holds the story.**
  `description` keeps its plain-text centered rendering; `about` is the new
  Markdown textarea rendered with `<.markdown>`. Alternative (single long
  field for both roles) was rejected: centered tagline and left-aligned
  story need different layout/emphasis.
- **D2: Additive migration, no data backfill.** `about` defaults to nil and
  renders nothing when empty; existing pages are unchanged until edited.
- **D3: Preview is a tab, live for free.** The form already re-renders on
  every keystroke (`validate_branding`); the Preview tab reads the same
  `@form` assign, so no new events or JS are needed. Tab state is a
  `preview_tab` boolean assign (`:edit | :preview`), default `:edit`.
- **D4: Strip logo/color from public career pages too.** Leaving dead display
  code referencing removed settings would confuse the next reader; the
  neutral header (name + subtitle + about) is the design target. The Apply
  button falls back to the default primary style.
- **D5: Published flag retired, not migrated.** The checkbox goes away and
  the three public LiveViews read the career page via the existing
  `get_career_page_by_tenant/1` (the `get_published_*` variant is deleted).
  The column stays, unused — same rationale as logo/color. Previously
  unpublished pages now show their branding: intended (the flag was
  incomprehensible) and self-evident on save via the preview tab.

## Risks / Trade-offs

- [Risk] Tenants relying on logo/colored band lose that styling → Mitigation:
  per user confirmation these are unused; columns retained so a revert is a
  UI-only change.
- [Risk] `about` empty on existing pages shows a thinner header → Mitigation:
  acceptable; block is conditional (`:if`) exactly like description today.
