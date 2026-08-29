# Analytics Dashboard

Track your hiring metrics with a clean analytics dashboard (`/app/analytics`, `lib/treby_web/live/analytics_live/index.ex`).

![Analytics Dashboard](/screenshots/10-analytics.png)

## Metrics

- **Total Candidates** — count of all candidates in the tenant
- **Avg. Time to Hire** — average days from first application to hired (`Pipeline.average_time_to_hire/1`)
- **Active Jobs** — number of open job postings
- **Pipeline Overview** — horizontal bar chart showing candidate counts per stage across all jobs (`pipeline_counts_per_stage/1`)
- **Stage Conversion Rates** — percentage progressing from one stage to the next (`stage_conversion_rates/1`)
- **Time-in-Stage** — average days a candidate spends in each stage, derived from `ActivityLog` stage-change events (`time_in_stage_metrics/2`)
- **Source Breakdown** — count per source (`source_breakdown/1`) — see [Source Tracking](/features/source-tracking)

## Pipeline Selector

A **per-pipeline selector** at the top of the page lets you scope all metrics to a single pipeline:

- "All pipelines" aggregates across the tenant (grouped by stage name)
- Selecting a pipeline filters to `where(pipeline_id == ^id)` and shows that pipeline's stages in order

All queries live in `lib/treby/pipeline/pipeline.ex:924` and are tenant-scoped.

## What you can learn

- Where are candidates getting stuck? (bottleneck stages via time-in-stage)
- Which stages have the highest drop-off? (conversion rates)
- How long does it take to fill each role?
- Are we interviewing enough people?
- Which sources actually hire? (source breakdown)
