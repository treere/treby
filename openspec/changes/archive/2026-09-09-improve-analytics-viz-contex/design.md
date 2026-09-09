## Context

Both analytics surfaces (`/app/analytics` for tenant-wide pipeline metrics and `/app/jobs/:id/analytics` for per-job view analytics) currently visualize data with plain Tailwind `<div>` bars sized by inline `width` percentages. Daily and monthly trends are rendered as vertical lists with horizontal bars, traffic sources as bars with percentages, and funnels as two disconnected stat boxes. This is hard to scan, distorts small values via arbitrary `max(..., 8%)` clamping, and does not convey time-series shape, proportional distribution, or bottleneck at a glance. No chart library is present (`assets/js/app.js` only imports `phoenix`, `topbar`, `sortablejs`; `mix.exs` has no chart dep). Data is already correct and tenant-scoped via `Treby.JobViews` and `Treby.Pipeline.Analytics`; only presentation is lacking. The user wants to fix empty states (keep card height, show explanatory placeholder), move incrementally to Contex, and defer Chart.js/canvas until real interactivity is needed.

## Goals / Non-Goals

**Goals:**
- Replace div-bars on both pages with server-side SVG charts via Contex 0.5.0, keeping LiveView server-rendered flow and design-system tokens (`zinc` palette, `orange-600` CTA, `rounded-xl`/`shadow-sm`).
- Daily views: `PointPlot`/`LinePlot` + `TimeScale` (7/30/90 selector re-renders server-side); Monthly views: `BarChart` vertical (12 months); Traffic sources: `PieChart` with legend; Pipeline overview / time-in-stage: `BarChart` horizontal with stage colors.
- Empty states occupy space: every chart card keeps `min-h-[320px]` and shows a centered dashed placeholder with icon and copy instead of collapsing.
- Introduce `TrebyWeb.Charts` helper to build `Contex.Dataset`/`Contex.Plot` and emit `Plot.to_svg/1` safe HTML, with themed overrides for Contex CSS classes.
- Update docs and screenshots to reflect real charts.

**Non-Goals:**
- No Chart.js, no canvas, no npm dependencies, no LiveView JS hooks or `ColocatedHook` in this change.
- No funnel/sankey/gauge custom SVG beyond current card layout (funnel stays as two stat boxes with conversion badge; can be enhanced later).
- No client-side interactivity (hover tooltips, zoom, brush, area gradient).
- No data-layer changes, no migrations, no new query logic.

## Decisions

**Decision: Contex 0.5.0 as the only chart dep (over Chart.js / ECharts / Vega / custom SVG)**
- Rationale: Pure Elixir, SVG output via `Contex.Plot.to_svg/1`, no JS bundle, fits Phoenix LiveView server-render model, `phx-change` on period selector just re-renders SVG. Matches AGENTS guidance to keep `assets/js/app.js` minimal. `{:contex, "~> 0.5.0"}` is MIT, last release 2023-05-31, stable for bar/line/pie needs.
- Alternatives: Chart.js (180–200 kB, canvas, needs hook, tooltip/area for free but overkill now), ECharts (300 kB, funnel native but heavier), Contex vs pure custom SVG (custom SVG gives full control but reimplements scales/axes). Contex wins for incremental, zero-JS step.

**Decision: Chart-to-data mapping**
- Daily (7/30/90): `Contex.PointPlot` with `TimeScale` on `date` column, single `y_col` `count`. Chosen over `BarChart` with categories because time series semantics (gaps, ordering) are explicit via `TimeScale`; `BarChart` with ordinal categories would lose temporal spacing.
- Monthly (12): `Contex.BarChart` vertical, `category_col` formatted `"%b %Y"`, `value_cols: [:count]`, `type: :stacked` (single series), `data_labels: true` for counts on bars.
- Sources: `Contex.PieChart` with `mapping: %{category_col: "source", value_col: "count"}`, `legend_setting: :legend_right`, `data_labels: true`. Contex has no doughnut; accept full pie and style via `colour_palette` hex list.
- Tenant pipeline/time-in-stage: `Contex.BarChart` horizontal (`orientation: :horizontal`) with stage `color` mapped to `colour_palette` in stage order.
- Rationale: Uses Contex primitives that actually exist; avoids inventing funnel/sankey.

**Decision: Centralize in `TrebyWeb.Charts`**
- Module exposes `daily_plot/2`, `monthly_plot/1`, `sources_plot/1`, `pipeline_plot/1`, `time_in_stage_plot/1` returning `Contex.Plot.t()`. LiveViews call `TrebyWeb.Charts.to_svg(plot)` and render raw safe HTML. Keeps LiveView `render/1` thin and testable.
- Alternative: inline `Dataset.new` in each LiveView — rejected for duplication and inconsistent theming.

**Decision: Theming and responsiveness**
- Override Contex default CSS classes (`.exc-tick`, `.exc-grid`, `.exc-domain`, `.exc-legend`, `.exc-title`) in `assets/css/app.css` with zinc/orange tokens and `data-theme=dark` variants. SVG wrapper set to `width: 100%; height: auto` via `viewBox` preservation (Contex emits fixed `width`/`height`; wrap in `div class="w-full overflow-hidden [&>svg]:w-full [&>svg]:h-auto"`).
- Colors: `colour_palette` derived from design system (`ea580c` for orange-600, `3b82f6`/`a855f7`/`22c55e` for series, stage `color` passthrough where available). Order preserved to match stage order.

**Decision: Empty-state strategy**
- Each chart card is `min-h-[320px] flex flex-col`; inner chart area is `flex-1 flex items-center justify-center`. If data is empty or all counts are `0`, render placeholder `div` with dashed border, `hero-chart-bar` icon, title and descriptive text (e.g., "No views in this period — share the public link to start tracking"). No chart rendered, card height unchanged. This satisfies "occupy space and say no data".

## Risks / Trade-offs

- **No hover tooltips / zoom** → Mitigation: keep `data_labels: true` so values are printed on bars/points; for dense daily series (90 points) labels are sparse, axis ticks remain readable. Document that tooltip interactivity is deferred to a follow-up Chart.js change.
- **PieChart is full pie, not doughnut** → Mitigation: accept full pie for now; don't fake inner radius with CSS. If doughnut becomes a user request, follow-up change can replace this single chart with Chart.js.
- **Fixed SVG size not auto-responsive** → Mitigation: wrapper with `w-full` and `h-auto`, test at `1280`, `768`, `375` widths and with `scripts/screenshots.mjs --axe`; if overflow persists, reduce Plot width to `560` and let wrapper scale.
- **Contex last release 2023** → Mitigation: pin to `~> 0.5.0`, vendor CSS overrides are local; pure Elixir SVG generation has no runtime JS risk. Monitor `hex.audit` in `mix precommit`.
- **TimeScale label formatting** → Mitigation: use `custom_x_formatter` or pre-format category labels as `"%b %d"` strings for PointPlot fallback; verify axis rotation via `axis_label_rotation: 45` when `days > 30`.
- **Dark mode contrast** → Mitigation: explicit Contex CSS overrides for `data-theme=dark` (tick text `#a1a1aa`, grid `#3f3f46`); run `node scripts/screenshots.mjs --axe` as gate.
- **Funnel still not a visual funnel** → Mitigation: keep current two-box stat layout with conversion badge and tenant average line; visual funnel (trapezoids) is explicitly out of scope.

## Migration Plan

1. Add `{:contex, "~> 0.5.0"}` to `mix.exs`, `mix deps.get`, commit `mix.lock`.
2. Create `TrebyWeb.Charts` and `assets/css/app.css` overrides.
3. Update `JobsLive.Analytics` and `AnalyticsLive.Index` to use `TrebyWeb.Charts` and new empty-state wrappers; remove old div-bar markup.
4. Run `mix precommit` (format, credo, sobelow, hex.audit, tests).
5. Regenerate docs screenshots `node scripts/screenshots.mjs` and update `site/features/analytics.md` + `site/features/job-analytics.md` (English, no file paths).
6. Deploy — no migration, no env vars, safe to rollback by reverting the single change (charts are presentation-only).

## Open Questions

- Should monthly chart also use `TimeScale` (PointPlot) instead of `BarChart` vertical for consistency? Current decision keeps bar for discrete months (clearer for 12 sparse bars); revisitable after visual review.
- Do we need `colour_palette: :default` vs explicit palette for sources when there are >6 sources? Default palette cycles; explicit list would be more brand-consistent.
- Should funnel remain as cards or be upgraded to a simple custom SVG trapezoid in this change despite "no custom funnel" non-goal? Left as non-goal to keep scope small, but open to include a minimal custom SVG if review finds cards insufficient.
