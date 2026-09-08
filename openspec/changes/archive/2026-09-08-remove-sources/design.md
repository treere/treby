## Context

Candidate sources live in three layers: a `sources` table managed from Settings → Sources (`Treby.Sources`), a `source` string column on `applications` filled from the public apply form / CSV import / internal creation, and read surfaces (Analytics breakdown, candidate detail, candidate portal). A separate, unrelated mechanism tracks job-page traffic sources via UTM/referrer (`Treby.JobViews`), which stays.

Current data is overwhelmingly empty/`Unknown` because the apply-form field is optional, so a hard removal loses no meaningful information.

## Goals / Non-Goals

**Goals:**

- Remove every trace of candidate sources: settings UI, routes, context + schema, DB table + column, apply-form field, import tagging, analytics card, detail/portal lines, tests, and user docs.
- Leave job-view traffic-source analytics (`JobViews`) fully working.

**Non-Goals:**

- No replacement attribution (no mandatory field, no UTM auto-fill on applications) — that would be a new feature, not this change.
- No data export of existing `sources`/`applications.source` values — the data is near-empty and unused.

## Decisions

- **Hard delete, single change.** The feature is user-invisible after removal except for cleaner Settings; no deprecation period needed since the data has no consumers outside the removed surfaces.
- **One migration drops both the table and the column** (`mix ecto.gen.migration remove_candidate_sources`). Kept ordering safe: the old `seed_default_sources` migration runs before it, so fresh setups migrate cleanly. Alternative (two migrations) rejected as noise.
- **Import path: remove the source selector entirely** (`@sources` assign, `select_source` event, `selected_source`, and the `source:` option threaded through `CsvImport`). Imported applications simply carry no source anymore. Alternative (keep parameter defaulting to nil) rejected — dead options rot.
- **Internal creation (`candidates_live/index.ex`) drops `source: "manual"`** for the same reason.
- **Analytics page keeps pipeline-counts/time-to-hire/conversion cards**; only the source-breakdown card, its assigns, and `Pipeline.source_breakdown/1,2` (+ `Analytics` implementations) go.
- **Docs updated in the same change** per project convention (`site/features/source-tracking.md` deleted; index, sidebar, screenshot, and workspace-switching mention cleaned; screenshots regenerated).

## Risks / Trade-offs

- [Risk] A tenant relied on the free-text source values → Mitigation: values were optional and mostly empty; no export provided by design decision above.
- [Risk] Stale gettext msgids → Mitigation: run `mix gettext.extract --merge` and verify `mix precommit` (includes translation-coverage guard).
- [Risk] Leftover references break compilation (aliases, routes, tests) → Mitigation: tasks include a repo-wide search verification step and full `mix precommit` + test suite run.
- [Risk] Screenshot script references the deleted page → Mitigation: remove its entry from `scripts/screenshots.mjs` in the same change.

## Migration Plan

1. Land code + migration together; standard deploy (`migrate` on boot/release).
2. Rollback: `mix ecto.rollback` restores table/column (data not restored — accepted, see Non-Goals); code rollback via revert.

## Open Questions

- None. Scope fully inventoried from the current codebase.
