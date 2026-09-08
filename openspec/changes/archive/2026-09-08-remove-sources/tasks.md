## 1. Database migration

- [x] 1.1 Generate migration via `mix ecto.gen.migration remove_candidate_sources` dropping the `sources` table and the `applications.source` column
- [x] 1.2 Run `mix ecto.migrate` and verify `mix ecto.migrate --to` rollback restores both

## 2. Backend removal

- [x] 2.1 Delete `lib/treby/sources/` (context + schema)
- [x] 2.2 Remove `:source` field and cast entry from `Treby.Pipeline.Application`
- [x] 2.3 Remove `source_breakdown/1,2` from `Treby.Pipeline.Analytics` and the `defdelegates` in `Treby.Pipeline`
- [x] 2.4 Remove the `source` import option threading in `Treby.CsvImport` (`opts[:source]`, row attrs)

## 3. LiveView + router removal

- [x] 3.1 Delete `lib/treby_web/live/settings_live/sources.ex` and remove both `/settings/sources` routes from the router
- [x] 3.2 Remove the Sources card from `SettingsLive.Index`
- [x] 3.3 Remove the "How did you hear about us?" dropdown, `@sources` assign, and `"source"` attr from `CareersLive.Apply`
- [x] 3.4 Remove the source selector (`@sources`, `select_source` event, `selected_source`, `source:` attr) from `ImportLive.Index`
- [x] 3.5 Remove the source-breakdown card and assigns from `AnalyticsLive.Index` (keep other cards)
- [x] 3.6 Remove the "Source:" line from `CandidatesLive.Show`, the "Via ..." line from `CandidatePortalLive.Index`, and `source: "manual"` from `CandidatesLive.Index`

## 4. Tests + translations

- [x] 4.1 Delete `test/treby_web/live/settings_live/sources_test.exs`
- [x] 4.2 Remove `source_breakdown` assertions from `test/treby/pipeline_test.exs`; fix `source: "csv_test"` setup in `test/treby/candidates_merge_test.exs` if it targets the removed column
- [x] 4.3 Repo-wide search for remaining `Sources`, `source_breakdown`, `settings/sources`, `application[source]` references; all must be gone (except `JobViews` traffic sources)
- [x] 4.4 Run `mix gettext.extract --merge`, verify no missing/fuzzy IT translations, run `mix precommit` green

## 5. Docs site + verification

- [x] 5.1 Delete `site/features/source-tracking.md`; remove its index, sidebar (`site/.vitepress/config.ts`), and workspace-switching mentions
- [x] 5.2 Remove the sources entry from `scripts/screenshots.mjs` and regenerate screenshots
- [x] 5.3 Full verification: `mix test`, Playwright smoke (settings index, apply form, analytics, import), `mix precommit`
