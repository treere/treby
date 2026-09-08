## Why

Candidate sources ("how did you hear about us") are an optional free-text dropdown on the public application form. In practice candidates skip it, so Analytics is dominated by an "Unknown" bucket (12 of 13 applications in testing) and the feature provides no actionable insight. Rather than investing in mandatory fields or UTM auto-tracking, we remove the feature entirely to reduce settings clutter and maintenance surface.

## What Changes

- **BREAKING** Remove the entire candidate-sources feature:
  - Settings → Sources page, settings index card, and both router routes (tenant + legacy scopes).
  - `Treby.Sources` context, `Source` schema, and the `sources` table (via migration).
  - `source` column on `applications` (via migration).
  - "How did you hear about us?" dropdown on the public application form.
  - Source selector on CSV import (imported applications no longer get tagged).
  - Source breakdown card on the Analytics page and `Pipeline.source_breakdown` functions.
  - "Source:" line on candidate detail and "Via ..." line on the candidate portal dashboard.
  - `source: "manual"` / `source: "csv_test"` attributes set on internal creation and import.
  - Settings test for sources; source-related assertions in pipeline tests.
- Explicitly KEPT (different feature): job-view traffic-source tracking (`JobViews`, UTM/referrer based) on per-job Analytics.
- User docs: remove the source-tracking feature page, index entries, sidebar entry, screenshot, and workspace-switching mention.
- Retire the `source-tracking` spec; update `analytics`, `csv-import`, and `candidate-portal-dashboard` specs.

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `source-tracking`: retired — the whole spec is removed.
- `analytics`: the source-breakdown requirement and its scenarios are removed.
- `csv-import`: the import-with-source scenario is removed.
- `candidate-portal-dashboard`: the application "source" display item is removed.

## Impact

- Deps: none added or removed.
- Migrations: one new migration dropping the `sources` table and the `applications.source` column (generated via `mix ecto.gen.migration`).
- Modules under `lib/treby/`: delete `sources/`; touch `pipeline/analytics.ex`, `pipeline/application.ex`, `pipeline.ex`, `csv_import/csv_import.ex`.
- LiveViews: `settings_live/sources.ex` (delete), `settings_live/index.ex`, `careers_live/apply.ex`, `import_live/index.ex`, `analytics_live/index.ex`, `candidates_live/show.ex`, `candidates_live/index.ex`, `candidate_portal_live/index.ex`.
- Router: remove both `/settings/sources` routes.
- Gettext: orphaned msgids cleaned via `mix gettext.extract --merge` (+ manual IT translations check).
- Docs site (`site/`): remove `features/source-tracking.md` + sidebar/index/screenshot references.
