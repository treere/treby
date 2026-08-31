## 1. Migration + Schema

- [x] 1.1 Generate migration `mix ecto.gen.migration add_structured_fields_to_jobs` adding nullable `location` (text), `employment_type` (varchar), `workplace_type` (varchar) to `jobs` — run `mix ecto.migrate`.
- [x] 1.2 Update `Treby.Jobs.Job` schema and `changeset/2` to cast and `validate_inclusion` for `employment_type` (`full_time`, `part_time`, `contract`, `internship`) and `workplace_type` (`on_site`, `hybrid`, `remote`) — verify with `mix test test/treby/jobs_test.exs`.

## 2. Context + LiveView / UI

- [x] 2.1 Update `Treby.Jobs` context helpers (search/list) to optionally include `location` in `search_visible_jobs` ilike clause.
- [x] 2.2 Update internal job form (`JobsLive.Index/Show` channel) to render inputs for `location` (text), `employment_type` and `workplace_type` (selects with prompt) with unique DOM ids.
- [x] 2.3 Update `CareersLive.Index` and `GlobalIndex` list cards to show location + badge pills (conditional rendering, no placeholder when nil).
- [x] 2.4 Update `CareersLive.Show` detail to render meta row (location, employment type, workplace type, salary, published date via `inserted_at`) with hero icons and gettext labels.

## 3. Tests

- [x] 3.1 Add/extend tests for job changeset validation (enum rejection) and public board rendering includes new meta when set and hides when nil.
- [x] 3.2 Run `mix test test/treby/jobs_test.exs test/treby_web/live/careers_live_test.exs` and fix.

## 4. Specs + Docs

- [x] 4.1 Update main specs at `openspec/specs/job-management/spec.md`, `openspec/specs/career-page/spec.md`, `openspec/specs/public-job-board/spec.md` (delta already captured — sync on archive).
- [x] 4.2 Sync `site/` user manual (career page + job management feature pages) and regenerate screenshots with `node scripts/screenshots.mjs`.
- [x] 4.3 Run `mix precommit` and `openspec validate --strict` and fix issues.
