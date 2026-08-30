## Why

Recruiters currently have no visibility into how many people view a job posting published on career pages. Without view metrics it is impossible to tell whether an underperforming posting suffers from low visibility or low conversion (view → application), and therefore to optimize title, description, distribution channels, or publishing timing. Tracking views per job position, with daily/monthly granularity and a dedicated page reachable from the job management area, closes this gap and provides actionable data for promoting and prioritizing positions.

## What Changes

- View tracking on the public job detail page (`/:tenant_slug/careers/:job_id`) on every visit by an unauthenticated visitor or a visitor authenticated as candidate/guest; visits by the tenant owner and authenticated team members are not counted.
- Lightweight anti-spam deduplication: same session/IP + job counts as at most one view per configurable window (default 1 hour) to avoid inflation from refreshes.
- View event persistence with `job_id`, `tenant_id`, `viewed_at`, `session_hash` (anonymous), `referer`/`utm_source` when present, truncated `user_agent`; no visitor PII.
- Per-job aggregations: total views, unique views (by session_hash), views in last 7/30/90 days, daily breakdown (last 30 days), monthly breakdown (last 12 months), sparkline trend, daily average.
- View → application funnel: total applications for the job, conversion rate (applications / views), comparison against tenant average.
- Traffic source: breakdown by `utm_source` / `referer` domain (e.g., LinkedIn, Indeed, Direct) when available.
- Per-job analytics page: `GET /app/jobs/:id/analytics` (LiveView) with KPI cards, daily/monthly chart, source table, funnel; accessible from job detail via an "Analytics" button/link.
- Synthetic badge/counter on the job list (`/app/jobs`) and on the job detail header: total views and views in last 7 days.
- Multi-tenancy and GDPR/privacy compliance: no cross-site tracking cookie, no raw IP stored (hash only), implicit opt-out for internal visits; optional bot exclusion via User-Agent filter.
- Migration via `mix ecto.gen.migration add_job_views` with table `job_views`.

## Capabilities

### New Capabilities
- `job-view-analytics`: tracking and analytics for a single job position — view counting, deduplication, daily/monthly aggregations, view→application funnel, traffic source breakdown, dedicated per-job analytics page, and synthetic indicators in list/detail views.

### Modified Capabilities
- `public-job-board`: the public job detail page records a trackable view on page load.
- `job-management`: the job management/detail page exposes navigation to the new analytics page and shows synthetic view indicators.
- `analytics`: the global analytics page may show a per-job views summary as an optional additional section — if not included in v1, it remains unchanged at the requirements level.

## Impact

- **DB/Migrations**: new table `job_views` (`id` binary_id, `job_id` FK→jobs, `tenant_id` FK→tenants, `viewed_at` utc_datetime, `session_hash` string, `referer` string nullable, `utm_source` string nullable, `user_agent` string nullable) with indexes on `(job_id, viewed_at)` and `(tenant_id, viewed_at)`; migration generated with `mix ecto.gen.migration`.
- **Elixir modules**: new context `Treby.JobViews` (or extension of `Treby.Jobs`) for `track_view/1`, `counts_for_job/2`, `daily_breakdown/2`, `monthly_breakdown/2`, `source_breakdown/2`, `funnel_for_job/1`; new LiveView `TrebyWeb.JobsLive.Analytics` and hook in `TrebyWeb.CareersLive.Show`.
- **Router/LiveView**: new route `live "/app/jobs/:id/analytics", JobsLive.Analytics` under the authenticated scope; tracking hook in the public `mount`/`handle_params`.
- **Dependencies**: no new dependencies; use `:req` if referer fetching is needed, otherwise only Ecto/PostgreSQL; charts with SVG/CSS or an existing component (no mandatory external JS library).
- **Docs/Site**: update `site/features/` with a new page `job-analytics` (or extend the jobs page), add screenshots via `node scripts/screenshots.mjs`, update `site/features/index.md` and sidebar `site/.vitepress/config.ts`.
- **Incidental fix (out-of-scope but required for `mix precommit` on Sundays)**: normalize `Availability` day-of-week handling — `Date.day_of_week/1` returns `1..7` while `availability_rules` validates `0..6` (Sunday `7 → 0`). Added `normalize_dow/1` in `lib/treby/availability/availability.ex`, plus test helpers in `booking_flow`/`scheduling_live` to map `7→0`. No behavioral change except Sunday availability now correctly resolves; prevents flaky failures when `mix precommit` runs on a Sunday.
- **Breaking changes**: none; additive and backward-compatible.
