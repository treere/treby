## Context

Today Treby tracks applications and their pipeline progression, with aggregated analytics (pipeline overview, time-to-hire, stage conversions, source breakdown) on the `Analytics` page. There is no metric for how many visitors view a public job posting (`/:tenant_slug/careers/:job_id`). Recruiters cannot distinguish low visibility from low attractiveness of a posting, nor compare performance across positions or channels.

Public pages are LiveViews (`CareersLive.Show`) served without team authentication; internal pages (jobs list/detail) are under an authenticated `live_session` with `tenant_id` in session. Each job is scoped to its tenant and has status `open/closed` plus flag `visible`. Applications are linked via `job_id`. Capabilities `public-job-board` (global board + detail) and `job-management` (list/detail/edit) already exist.

Stakeholders: recruiters and hiring managers (team users), tenant admins. Anonymous visitors (candidate/guest) are the data source. Constraints: strict multi-tenancy, privacy (no PII, no cross-site tracking, IP/session hash only), no new external service, backward compatibility, performance on high-volume tables.

## Goals / Non-Goals

**Goals:**
- Track every genuine view of the public job detail page with hourly deduplication per session/job to limit simple refresh/bot inflation.
- Provide per job: total views, unique views, views in last 7/30/90 days, daily breakdown (last 30 days) and monthly breakdown (last 12 months), view→application conversion rate, source breakdown (utm_source/referer domain), daily average and trend.
- Expose a dedicated per-job analytics page (`/app/jobs/:id/analytics`) reachable from the job detail, with KPIs, charts, and source table.
- Show synthetic indicators in the job list and detail header (total views, last 7 days).
- Enforce correct multi-tenancy, isolation, and authorization (only members of the tenant see analytics for their jobs).
- Filter simple bots via User-Agent and skip visits by authenticated team users on the public domain.

**Non-Goals:**
- Complex cross-job global funnel (beyond a per-job views summary in global analytics — v1 is limited to the per-job page).
- Geolocation, heatmaps, session replay, advanced fingerprinting.
- Integration with external providers (Google Analytics, Plausible) — Treby stays self-hosted and privacy-preserving.
- Push/email notifications on view thresholds.
- A/B testing of postings.

## Decisions

**1. Data model: dedicated `job_views` table vs counter on `jobs`**
- Decision: `job_views` table with one row per deduplicated event (`job_id`, `tenant_id`, `viewed_at`, `session_hash`, `referer`, `utm_source`, `user_agent`). Aggregations computed via queries with `date_trunc` and `group by`.
- Alternative discarded: `view_count` column on `jobs` incremented on every hit — loses temporal granularity, source, deduplication, and history; would still require a separate table for daily/monthly breakdowns.
- Rationale: flexibility for daily/monthly queries, funnel, and sources; storage cost acceptable (one row per deduplicated view, not per refresh within window); indexable.

**2. Deduplication: 1-hour window per `session_hash + job_id`**
- Decision: before inserting, check whether a view exists for the same `job_id` and `session_hash` with `viewed_at > now - 1 hour`; if yes, skip. `session_hash` = anonymous hash of `IP + User-Agent + daily salt` or `plug session id` when present (without persisting raw IP). TTL configurable via env `JOB_VIEW_DEDUP_MINUTES`.
- Alternative discarded: no dedup (inflates metrics); daily dedup (too aggressive, undercounts legitimate repeat visits).
- Rationale: balances accuracy and resilience to quick refreshes; simple to implement with an existing query without jobs/bloom filters.

**3. Where to track: `CareersLive.Show.mount/3` (server) vs JS beacon**
- Decision: server-side tracking in the public LiveView `mount` after resolving `tenant` and `job` (only when `job.status == "open"`). Extract `referer` from header, `utm_source` from query params, `user_agent` from header; compute `session_hash`; call `Treby.JobViews.track_view/1` fire-and-forget via `Task.Supervisor` or directly synchronously but wrapped in `try/rescue` so rendering is never blocked.
- Alternative discarded: JS beacon (`fetch` to a dedicated endpoint) — requires an extra endpoint, CORS, retry handling, and misses visits with JS disabled; only useful if scroll depth were to be tracked.
- Rationale: zero additional JS, reliable, SSR-friendly, consistent with existing authentication; LiveView mount is already tenant-scoped.

**4. Internal visits and bot filtering**
- Decision: if `session["user_id"]` is present and `user.tenant_id == job.tenant_id`, skip (do not count visits by tenant owners/members testing the listing). Additionally filter User-Agents matching known bot patterns (`bot|crawl|spider|slurp|mediapartners` case-insensitive); if matched, skip. No opt-out cookie required in v1.
- Alternative discarded: track everything and filter afterward — pollutes primary metrics.
- Rationale: clean metrics for promotion decisions; simple filter without an external list.

**5. Aggregations: direct queries vs materialized view**
- Decision: direct Ecto queries with `fragment("date_trunc('day', viewed_at)")` and `group_by` for breakdowns; totals for last 7/30/90 days with `where viewed_at >= ^cutoff`; funnel via join with `applications` filtered by job; sources via `group_by utm_source/coalesce(referer_domain, 'Direct')`. Optional caching in LiveView assigns (no global cache in v1).
- Alternative discarded: materialized view / rollup job — premature optimization for initial volumes; adds refresh complexity.
- Rationale: expected volumes are modest (hundreds/thousands of views per job); queries indexed on `(job_id, viewed_at)` are sufficient; parallel aggregation unnecessary.

**6. UI: new LiveView `JobsLive.Analytics` vs extending `JobsLive.Show`**
- Decision: dedicated LiveView `JobsLive.Analytics` mounted at `/app/jobs/:id/analytics` with layout `Layouts.app`, KPI cards, period controls (7/30/90 days), daily bar chart (SVG/CSS), monthly table/bar for last 12 months, source breakdown, funnel. Link from `JobsLive.Show` header ("Analytics" with chart icon) and badge in `JobsLive.Index` job row.
- Alternative discarded: tab inside `Show` — would bloat an already rich page (candidates, pipeline editor); a dedicated page scales better for charts.
- Rationale: separation of concerns, bookmarkable URL, easier screenshots/docs.

**7. Contracts and multi-tenant isolation**
- `Treby.JobViews` exposes: `track_view(attrs) :: {:ok, JobView} | {:skip, reason}`, `get_summary(tenant_id, job_id)`, `daily_breakdown(tenant_id, job_id, days)`, `monthly_breakdown(tenant_id, job_id, months)`, `source_breakdown(tenant_id, job_id)`, `funnel_for_job(tenant_id, job_id)`. Every read verifies `job.tenant_id == tenant_id` (fail-closed: on mismatch return `{:error, :not_found}`).
- Authorization: `JobsLive.Analytics` mount verifies `Jobs.get_job(tenant.id, id)` — if nil → redirect 404; `track_view` is public but validated against `job.status == "open"` otherwise skipped.

**8. Caching and error handling**
- Caching: no external cache in v1; LiveView recomputes on mount and on period change; optional `assign` memoization to avoid duplicate queries within the same mount.
- Error handling: `track_view` must never raise a visible exception to the visitor; wrap in `try/rescue` and log `warning` on DB failure; aggregations for jobs without views return zeros and empty charts with message "No views yet" (fail-closed for missing data).

## Risks / Trade-offs

- **Volume of `job_views` for viral jobs** → Mitigation: hourly dedup reduces rows; index on `(job_id, viewed_at)`; consider future partitioning or daily rollup if >1M rows/tenant.
- **Sophisticated bots not caught by simple regex** → Mitigation: base filter covers majority; accept slight overcounting in v1; consider integrating an external bot list in a follow-up iteration.
- **Session hash with IP behind proxy/CDN** → Mitigation: use first value of `x-forwarded-for` when present (Bandit/Plug already normalizes it), otherwise `remote_ip`; document limitation for deployments behind multiple proxies.
- **Race on dedup window** → Mitigation: `exists?` + insert is not atomic; accept rare double counting within window; alternative unique index on `(job_id, session_hash, date_trunc('hour', viewed_at))` is evaluable but not required in v1.
- **Performance of daily breakdown over 30 days** → Mitigation: single query `group by date_trunc('day', viewed_at)`; if slow, add a functional index or ETS cache.
- **Privacy/GDPR: tracking perception** → Mitigation: no raw IP, only anonymous hash; `user_agent` truncated to 255 chars; `referer` only domain+source; document in site privacy note.

## Migration Plan

1. Generate migration `mix ecto.gen.migration add_job_views` with table `job_views` and indexes; run `mix ecto.migrate` in dev/test/prod.
2. Create schema `Treby.JobViews.JobView` and context `Treby.JobViews` with tracking/aggregation functions.
3. Modify `TrebyWeb.CareersLive.Show` to call `track_view` on mount (open job, non-team, non-bot).
4. Add route `live "/app/jobs/:id/analytics", JobsLive.Analytics` in `router.ex` under `live_session :authenticated`.
5. Implement `JobsLive.Analytics` LiveView + template with KPIs/charts.
6. Add link/badge in `JobsLive.Index` and `JobsLive.Show`.
7. Update tests: unit tests for `JobViews`, LiveView tests for tracking and analytics page, multi-tenancy filtering.
8. Run `mix precommit`, regenerate screenshots with `node scripts/screenshots.mjs`, update `site/features/*` and sidebar.
9. Deploy: automatic migration on boot (existing release migrator); rollback via `mix ecto.rollback` (drop table) — no critical data lost beyond views.

## Open Questions

- Optimal dedup window: is 1 hour correct or should it be 30 min / 24h? v1 decision: 1h configurable via env.
- Should `session_hash` also include `accept-language` to better distinguish shared sessions behind NAT? v1: IP+UA is sufficient.
- Show views for closed jobs (history) or only open? v1: track only open, but analytics remains visible after closing (immutable history).
- Include views summary in the global analytics page (`AnalyticsLive.Index`)? v1: no, per-job page only; evaluate in follow-up whether a "Top jobs by views" table is useful.
