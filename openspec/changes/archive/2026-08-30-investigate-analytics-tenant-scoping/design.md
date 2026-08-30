## Context

GET /app/analytics reports Total Candidates 14 on tenant with 2 candidates – cross-tenant leak. Queries pipeline_counts_per_stage(nil), source_breakdown(nil), average_time_to_hire(nil) aggregate globally without tenant filter.

## Goals

- Scope all analytics queries by tenant_id. Even "All pipelines" view aggregates only tenant's pipelines.

## Decisions

- Add tenant_id param to pipeline_counts_per_stage, source_breakdown, average_time_to_hire, stage_conversion_rates, time_in_stage_metrics when pipeline_id == nil – filter via join on pipeline or tenant.
- Update AnalyticsLive.Index.load_analytics to pass tenant_id: `Pipeline.pipeline_counts_per_stage(tenant_id, pipeline_id)` etc.
- Keep overloads for backward compat but internal logic filters.

## Risks

- Existing tests may call pipeline_counts_per_stage(nil) without tenant → update tests to pass tenant_id.
