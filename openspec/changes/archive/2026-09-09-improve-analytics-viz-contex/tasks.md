## 1. Setup and Dependency

- [x] 1.1 Add `{:contex, "~> 0.5.0"}` to `mix.exs` and run `mix deps.get` (commit `mix.lock`)
- [x] 1.2 Create `lib/treby_web/charts.ex` (`TrebyWeb.Charts`) with helpers: `daily_plot/2`, `monthly_plot/1`, `sources_plot/1`, `pipeline_plot/1`, `time_in_stage_plot/1` returning `Contex.Plot.t()` and `to_svg/1` wrapper

## 2. Styling and Shared UI

- [x] 2.1 Add Contex CSS overrides (`.exc-tick`, `.exc-grid`, `.exc-domain`, `.exc-legend`, `.exc-title`) to `assets/css/app.css` for light (`zinc`) and `data-theme=dark` variants using design-system tokens (`zinc-50`/`zinc-900`, `orange-600`)
- [x] 2.2 Add responsive SVG wrapper class and verify no horizontal overflow at 375/768/1280px
- [x] 2.3 Create empty-state placeholder component/partial for chart cards (`min-h-[320px] flex flex-col`, inner `flex-1 flex items-center justify-center` with dashed border, `hero-chart-bar` icon, title and descriptive text)

## 3. Job Analytics Page (`/app/jobs/:id/analytics`)

- [x] 3.1 Replace Daily Views div-bars with Contex `PointPlot`/`LinePlot` + `TimeScale` in `lib/treby_web/live/jobs_live/analytics.ex` (respect `selected_period` 7/30/90, server re-render on `phx-change`, `axis_label_rotation: 45` when `days > 30`, `data_labels` where readable)
- [x] 3.2 Replace Monthly Views div-bars with Contex `BarChart` vertical (12 months, `data_labels: true`) in same LiveView
- [x] 3.3 Replace Traffic Sources div-bars with Contex `PieChart` (`legend_setting: :legend_right`, `colour_palette` mapped from design system) in same LiveView
- [x] 3.4 Apply empty-state placeholders to daily/monthly/sources cards (keep `min-h-[320px]`, show centered placeholder when all counts are `0` or breakdown is empty)
- [x] 3.5 Keep funnel as structured cards (no Chart.js) but verify conversion badge and tenant average line remain correct

## 4. Tenant Analytics Page (`/app/analytics`)

- [x] 4.1 Replace Pipeline Overview div-bars with Contex `BarChart` horizontal (`orientation: :horizontal`, stage colors via `colour_palette` in stage order) in `lib/treby_web/live/analytics_live/index.ex`
- [x] 4.2 Replace Time-in-Stage div-bars with Contex `BarChart` horizontal (horizontal, `avg_days` value axis, bottleneck highlight) in same LiveView
- [x] 4.3 Apply empty-state placeholders to pipeline overview and time-in-stage cards (`min-h-[320px]`, placeholder when `pipeline_counts == []` or `time_in_stage == []`)
- [x] 4.4 Ensure pipeline selector (`All pipelines` vs single) re-renders all Contex charts server-side and remains tenant-scoped

## 5. Tests

- [x] 5.1 Extend `test/treby_web/live/jobs_analytics_live_test.exs` and `test/treby_web/live/analytics_live_test.exs` to assert SVG output is present when data exists and placeholder is shown when data is empty (all counts `0`), and that tenant isolation still holds
- [x] 5.2 Add unit tests for `TrebyWeb.Charts` helpers (dataset building, empty input handling, SVG is safe HTML)

## 6. Specs and Docs

- [x] 6.1 Sync specs: copy delta specs from `openspec/changes/improve-analytics-viz-contex/specs/analytics/spec.md` → `openspec/specs/analytics/spec.md`, `.../job-view-analytics/spec.md` → `openspec/specs/job-view-analytics/spec.md`, and create `openspec/specs/analytics-charts/spec.md` from `.../analytics-charts/spec.md`
- [x] 6.2 Update `site/features/analytics.md` and `site/features/job-analytics.md` in English (no file paths/module names), describe new charts and empty states, regenerate screenshots with `node scripts/screenshots.mjs` and verify `node scripts/screenshots.mjs --axe` passes
- [x] 6.3 Update `site/.vitepress/config.ts` sidebar and `site/features/index.md` if a new feature page is added (not needed if only updating existing pages)

## 7. Final Verification

- [x] 7.1 Run `mix precommit` and `openspec validate --strict` and fix all issues
