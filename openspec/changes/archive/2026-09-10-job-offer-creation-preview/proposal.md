## Why

Creating a job today happens inline inside the job listing (`/app/jobs`) via a toggled form with no sense of how candidates will see the posting. Recruiters cannot preview the public rendering and must use separate table actions to control whether the offer is active (open/closed) and where it appears (public/private). A dedicated creation page with live preview and explicit publication controls solves discoverability, reduces errors, and aligns Treby with expected ATS ergonomics.

## What Changes

- Replace the inline "Create Job" form on the job listing with a dedicated creation page at `/app/jobs/new` (and `/:tenant_slug/app/jobs/new`) with its own LiveView.
- Creation page layout is split: form on the left, live preview on the right that renders exactly as the public career page (`/:tenant_slug/careers/:job_id`) will show — title, company block, location/employment/workplace badges, salary, Markdown-rendered description, and posted date — updating on every validated change without persistence.
- Publication controls are first-class on the creation form:
  - **Status** toggle/select: `Open` (active, visible on career pages if public) vs `Closed` (inactive, hidden from all public boards). Defaults to `Open`.
  - **Visibility** toggle/select: `Public` (`visible=true`, appears on `/careers` and `/:tenant_slug/careers` when open) vs `Private` (`visible=false`, only reachable via direct link). Defaults to `Public` and is disabled with a hint when status is `Closed` (enforced by existing `validate_visible_requires_open`).
- Keep all existing fields: title, description (Markdown), salary range, location, employment type, workplace type, pipeline selector (default preselected), and tenant-scoped custom job fields.
- "New Job" button on the listing navigates to the new page (no inline form). After successful creation, redirect to the job detail page with a flash. Cancel navigates back to the listing.
- Existing edit flow on the job detail page remains unchanged; listing table toggles for status/visibility remain.

## Capabilities

### New Capabilities
- `job-creation-preview`: Dedicated job creation page with live public preview and explicit status (open/closed) + visibility (public/private) controls at creation time.

### Modified Capabilities
- `job-management`: Creation requirement moves from inline listing form to dedicated page; "New Job" action becomes navigation rather than toggle; listing no longer hosts the creation form.

## Impact

- **Routing**: New `live "/jobs/new"` in `lib/treby_web/router.ex` under both `:default` and `:legacy_default` live sessions (before `"/jobs/:id"` to avoid param conflict).
- **LiveViews**: New `TrebyWeb.JobsLive.New` (form + preview state, `phx-change="validate"` for live preview, `phx-submit="save"`), removal of inline-form assigns/events (`show_form`, `show_create_form`/`hide_create_form`, `create_job`) from `TrebyWeb.JobsLive.Index`.
- **Components**: Reuse existing public rendering (`.markdown`, badge, header) for preview; reuse `TrebyWeb.DesignSystem` tokens; ensure light/dark contrast for preview card (`data-theme` aware).
- **Domain**: No schema or migration change — `jobs.status` and `jobs.visible` already exist with validation. Creation uses `Treby.Jobs.create_job/1` as before.
- **Tests**: Update `test/treby_web/live/jobs_live_test.exs` (or equivalent) to assert navigation to `/app/jobs/new`, preview rendering, and status/visibility handling.
- **Docs**: Update `site/features/*` job feature page and regenerate screenshots via `node scripts/screenshots.mjs` + `node scripts/screenshots.mjs --axe` for contrast/a11y as per AGENTS.md.
