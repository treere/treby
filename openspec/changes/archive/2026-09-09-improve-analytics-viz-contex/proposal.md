## Why

Current analytics pages (`/app/analytics` and `/app/jobs/:id/analytics`) render all trends and breakdowns as plain horizontal `<div>` bars with inline `width` styles. Time series (daily/monthly views) are shown as vertical lists, traffic sources as bars instead of a proportional chart, and funnels as disconnected boxes. The result is hard to scan, distorts small values, and fails to communicate trends, distributions, and drop-off at a glance. Screenshot regeneration after each feature change also lacks real chart output.

## What Changes

- Replace all bar/div visualizations on both analytics pages with server-side SVG charts generated via **Contex** (no Chart.js, no JS hooks in this change).
- Job analytics (`/app/jobs/:id/analytics`): daily views as Contex `PointPlot`/`LinePlot` with `TimeScale` (7/30/90-day selector triggers server re-render), monthly views as `BarChart` vertical (12 months), traffic sources as `PieChart` with legend.
- Tenant analytics (`/app/analytics`): pipeline overview and time-in-stage as `BarChart` horizontal (preserving stage colors), keep funnel/conversion as structured cards but improve proportion and empty-state handling.
- Empty states occupy the card space: every chart card keeps `min-h-[320px]` and shows a centered dashed placeholder with icon and explanatory text instead of collapsing; charts only render when data has non-zero values.
- Introduce `TrebyWeb.Charts` helper module to build `Contex.Dataset`/`Contex.Plot` objects, map stage colors and design-system palette (`zinc`/`orange-600`), and emit `Plot.to_svg/1` safe HTML.
- Add `{:contex, "~> 0.5.0"}` dependency and override Contex CSS classes (`.exc-*`) in `assets/css/app.css` for light/dark themes.
- Update user docs in `site/features/analytics.md` and `site/features/job-analytics.md` plus screenshots via `node scripts/screenshots.mjs`.

## Capabilities

### New Capabilities
- `analytics-charts`: Server-side SVG charting for analytics (Contex integration, dataset helpers, themed styling, responsive SVG wrapper, and empty-state placeholders). Covers daily/monthly line/bar charts, PieChart for sources, and horizontal BarCharts for pipeline/time-in-stage.

### Modified Capabilities
- `analytics`: Requirement changes for Pipeline overview, Time-to-hire, Stage conversion, Time-in-stage, and Analytics page layout — visualizations move from div bars to SVG charts; empty states keep card height; pipeline filter still drives all metrics.
- `job-view-analytics`: Requirement changes for Daily/monthly breakdowns, Traffic source breakdown, and Per-job analytics page — breakdowns move from div bars to SVG charts (daily line, monthly bar, sources pie); KPI cards unchanged; page keeps period selector and tenant isolation; empty states occupy space.

## Impact

- Dependencies: add `{:contex, "~> 0.5.0"}` to `mix.exs`/`mix.lock`; no npm changes; no DB migration.
- Modules: `lib/treby_web/live/jobs_live/analytics.ex`, `lib/treby_web/live/analytics_live/index.ex`, new `lib/treby_web/components/charts.ex` (or `lib/treby_web/charts.ex`), `assets/css/app.css` (Contex overrides), `site/features/*.md` + screenshots.
- No breaking API changes; all queries remain tenant-scoped; existing `Treby.JobViews` and `Treby.Pipeline.Analytics` remain the data layer.
- Explicitly out of scope: Chart.js, canvas, LiveView JS hooks, funnel/sankey custom SVG beyond current card layout, and client-side interactivity (tooltips, zoom) — deferred to a follow-up change if needed.
