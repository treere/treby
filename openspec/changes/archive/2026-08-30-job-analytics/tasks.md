## 1. Foundation — DB and context

- [x] 1.1 Generate migration `mix ecto.gen.migration add_job_views` with table `job_views` (binary_id, `job_id` FK→jobs on_delete :delete_all, `tenant_id` FK→tenants on_delete :delete_all, `viewed_at` :utc_datetime, `session_hash` :string, `referer` :string nullable, `utm_source` :string nullable, `user_agent` :string nullable, `inserted_at`) + indexes `[:job_id, :viewed_at]` and `[:tenant_id, :viewed_at]` and `[:job_id, :session_hash, :viewed_at]`; run `mix ecto.migrate`
- [x] 1.2 Create schema `Treby.JobViews.JobView` with changeset and validations (tenant_id/job_id required, viewed_at required)
- [x] 1.3 Create context `Treby.JobViews` with `track_view/1` (60m dedup per session_hash+job_id, bot filter via regex, skip when job closed, anonymous IP+UA hash, referer domain + utm_source extraction), `get_summary/2`, `daily_breakdown/3`, `monthly_breakdown/3`, `source_breakdown/2`, `funnel_for_job/2`, `tenant_avg_conversion/1`; multi-tenant isolation on every query
- [x] 1.4 Add helpers `session_hash` (SHA256 hash of `remote_ip + user_agent + daily_salt`) and `bot?/1`, `extract_source/2`; unit tests for helpers

## 2. Tracking — public job board

- [x] 2.1 Modify `TrebyWeb.CareersLive.Show.mount/3` to call `JobViews.track_view` after resolving tenant/job (only when `job.status == "open"` and visitor is not a team member of the tenant and not a bot); extract `referer` from `get_connect_info` / `:x-forwarded-for`, `utm_source` from `connect_params` or query, `user_agent` from header; wrap in `try/rescue` + `Logger.warning` and never block rendering
- [x] 2.2 Ensure visits on `visible == false` (direct link) are still tracked when open; closed jobs are not tracked
- [x] 2.3 Add LiveView tests for tracking: anonymous visit creates row, second within 60m does not, after window does, team member does not, bot does not, tenant isolation on queries

## 3. Aggregations and internal APIs

- [x] 3.1 Implement `get_summary(tenant_id, job_id)` with total, unique, last_7/30/90, avg_daily (handle zero views → zeros/N/A)
- [x] 3.2 Implement `daily_breakdown(tenant_id, job_id, days \\ 30)` with `date_trunc('day', viewed_at)` group_by, fill missing days with 0, ordered asc
- [x] 3.3 Implement `monthly_breakdown(tenant_id, job_id, months \\ 12)` with `date_trunc('month', viewed_at)` group_by, fill missing months with 0, ordered asc
- [x] 3.4 Implement `source_breakdown(tenant_id, job_id)` grouping by `coalesce(utm_source, referer_domain, 'Direct')` with count and percentage
- [x] 3.5 Implement `funnel_for_job(tenant_id, job_id)` with total_views + total_applications (via `Treby.Pipeline`/`Treby.Jobs` or query on `applications`) + conversion_rate and `tenant_avg_conversion`
- [x] 3.6 Unit tests for aggregations (tenant isolation, zero views, daily/monthly fill, Direct sources, 0% funnel)

## 4. UI — Per-job analytics page

- [x] 4.1 Create LiveView `TrebyWeb.JobsLive.Analytics` with mount `get_job(tenant.id, id)` (redirect /404 when nil), assign summary/daily/monthly/source/funnel; route `live "/app/jobs/:id/analytics", JobsLive.Analytics` in `router.ex` under `live_session :authenticated`
- [x] 4.2 Template `Analytics` with `Layouts.app flash={@flash} current_scope={@current_user}`: job title header + back link to `/app/jobs/:id`, KPI cards (total, unique, last_7/30, avg daily, conversion), period filter 7/30/90 for daily chart, daily bar chart (SVG/CSS), monthly table/bar for 12 months, source breakdown (bar + table), view→application funnel with tenant avg
- [x] 4.3 Handle empty state "No views yet" for KPI N/A and empty charts; handle closed job (show history, no new tracking)
- [x] 4.4 LiveView tests for analytics page: render KPIs, tenant authorization (404 for other tenant's job), empty state, closed job still accessible

## 5. UI — Job management integration

- [x] 5.1 Add "Analytics" button/link (hero-chart-bar icon) in header actions of `TrebyWeb.JobsLive.Show` (next to Copy Public Link/Edit/View Pipeline) navigating to `/app/jobs/:id/analytics` with id `job-analytics-link`
- [x] 5.2 Show synthetic badge in `JobsLive.Show` header: total views + last 7d (or "No views yet") with id `job-view-summary`
- [x] 5.3 Show synthetic indicators in `TrebyWeb.JobsLive.Index` for each job row: total views + last 7d (or "No views yet") using `JobViews.get_summary` batch or single query per tenant (avoid N+1: load summaries in mount via single query)
- [x] 5.4 LiveView tests for Analytics link presence on Show, badge values correct, job list shows indicators and respects tenant isolation

## 6. Quality, docs and screenshots

- [x] 6.1 Run `mix precommit` and fix formatter/credo/failing tests
- [x] 6.2 Update `site/features/` with new page `job-analytics.md` (or extend `job-management.md`) as user manual: where to find Analytics, what it shows (KPIs, daily/monthly, sources, funnel), step-by-step; update `site/features/index.md` and sidebar `site/.vitepress/config.ts` when adding a new page
- [x] 6.3 Regenerate screenshots with `node scripts/screenshots.mjs` (job detail with Analytics link, analytics page with data, job list with indicators) and verify `cd site && npm run build`
- [x] 6.4 Manual end-to-end verification: create job, visit public page from anonymous session (incognito) and verify increment; verify dedup on quick refresh; verify analytics page updated
- [x] 6.5 Run `openspec validate --strict` and fix issues; ensure spec at `openspec/specs/job-view-analytics/spec.md` is synced on archive
