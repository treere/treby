## Why

Playwright walkthrough showed the career detail page (`/:tenant_slug/careers/:job_id`) renders only `title`, `salary_range`, and a free-text `description`. Location, employment type, and publishing date are forced into the description blob, making filtering and candidate comprehension poor. Candidates cannot compare positions at a glance and structured data needed for SEO/search is missing. Adding structured fields aligns with standard ATS expectations.

## What Changes

- Extend `jobs` with structured optional fields: `location` (string), `employment_type` (enum: `full_time`, `part_time`, `contract`, `internship`), `workplace_type` (enum: `on_site`, `hybrid`, `remote`), and expose `inserted_at` as published date. All fields optional to avoid breaking existing jobs.
- Update job creation/editing UI (`JobsLive`) to capture these fields with selects and text input.
- Update public career list (`CareersLive.Index` + `GlobalIndex`) to show location + badge pills for type/remote alongside title/salary.
- Update public job detail (`CareersLive.Show`) to render structured meta row (location, employment type, workplace, salary, published date) separate from description, with translated labels.
- Add search/filter support by location/type on public boards (optional stretch, not required for v1 — keep `search_visible_jobs` ilike extension if cheap).

## Capabilities

### New Capabilities
- _none_ (reuse existing capabilities, no new folder).

### Modified Capabilities
- `job-management`: job schema and internal CRUD now include structured fields.
- `career-page`: detail rendering shows structured meta.
- `public-job-board`: listings show location/badges and support richer display.

## Impact

- Migration: `mix ecto.gen.migration add_structured_fields_to_jobs` adding `location` (text), `employment_type` (string), `workplace_type` (string) nullable columns.
- `lib/treby/jobs/job.ex` — changeset + validations for enums.
- `lib/treby/jobs/jobs.ex` — list/search helpers updated if filtering added.
- `lib/treby_web/live/jobs_live/*` — forms for new fields.
- `lib/treby_web/live/careers_live/*` — list + show templates.
- `priv/gettext` — new msgids for employment/workplace types.
- No breaking API; null defaults keep existing jobs valid.
- Docs: `site/` career-page / job-management pages updated; screenshots regenerated.
