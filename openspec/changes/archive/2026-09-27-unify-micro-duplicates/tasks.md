## 1. CandidatePortal shared messages preload

- [x] 1.1 Add `CandidatePortal.messages_preload/0` returning existing `messages: @messages_query` keyword verbatim
- [x] 1.2 Migrate 4 preload sites in `candidate_portal.ex` to call `messages_preload/0`, no assoc/shape change
- [x] 1.3 Verify: `mix test test/treby/candidate_portal_test.exs` green (plus portal Live tests touching messages)

## 2. Audit envelope helper

- [x] 2.1 Add thin `Audit.log_change` wrapper building only `%{tenant_id, actor_id, metadata %{before, after}}` envelope merged with caller payload, delegating to existing `log_event`
- [x] 2.2 Migrate call sites in jobs, candidates, stages, scorecards, customization, interviews to pass `before`/`after` only, keeping event strings and payload keys verbatim
- [x] 2.3 Verify: `mix test` audit-related suites green, `log_event` remains single insert path (grep delegate)

## 3. Portal mount/guard + page title helpers

- [x] 3.1 Add portal-scoped helper module under `candidate_portal_live/` exposing `mount_portal/2` (slug lookup + not-found/unauthorized guard, branch order verbatim) and `assign_page_title/2`
- [x] 3.2 Migrate 6 portal `mount/3` callbacks to `mount_portal/2`, preserving guard branches
- [x] 3.3 SKIPPED by design: all 7 titles distinct strings, wrapper dedups nothing; titles stay inline
- [x] 3.4 Verify: portal Live tests covering unknown slug + unauthorized branches green

## 4. Oban workers BaseWorker

- [x] 4.1 Add `Treby.Workers.BaseWorker` with `use` providing `arg/2` string/atom fallback and shared backoff table + `backoff/1`, values copied verbatim
- [x] 4.2 Migrate `data_privacy_export_worker`, `data_privacy_erasure_worker`, `webhook_delivery`, `send_scheduled_message` to `use BaseWorker`, delete local arg fallback + backoff copies
- [x] 4.3 Verify: worker tests + Oban retry/backoff assertions green, no retry-policy change

## 5. CSV single parse entry point

- [x] 5.1 Make `ImportCsv.run/2` reuse central `Treby.CsvImport.parse_csv/1` (+ existing `auto_detect_mapping`/`preview_import` path) instead of private split/parse
- [x] 5.2 Delete now-dead private `String.split` on import path; positional `parse_row/1` mapper stays (import semantics positional, preview header-mapped); `PreviewCsvImport` unchanged as reference
- [x] 5.3 Verify: CSV import + preview suites green, malformed-row error shapes match preview, no fail-open

## 6. Full verification

- [x] 6.1 Run full `mix test` green (or affected portal/audit/worker/CSV suites if full suite impractical, note scope)
- [x] 6.2 Run `mix precommit` and fix issues
- [x] 6.3 Run `openspec validate --strict` and fix issues
