## Why

Five small copy-paste duplications verified in `reports/ridondanze-architettura-2026-09-26.md` (points 6, 7, 11, 12) increase edit risk with zero behavior value. Unify each behind one tiny shared helper with no behavior change.

## What Changes

- `CandidatePortal` messages preload: extract one shared `messages_preload/0` (or module attribute consumer) for the 4x identical `messages: @messages_query` in `candidate_portal.ex:269,280,289,295`.
- Audit envelope: add `Audit.log_change/5` (or equivalent thin wrapper) building the repeated `%{tenant_id, actor_id, metadata %{before, after}}` envelope; migrate ~25 `Audit.log_event` call sites in `jobs`, `candidates`, `stages`, `scorecards`, `customization`, `interviews` to pass `before/after` only.
- Portal mount/guard + page title: add `CandidatePortalLive` shared `on_mount`-style `mount_portal/2` helper covering the x6 `mount(%{"tenant_slug" => slug})` + tenant guard, plus a tiny `assign_page_title/2` helper for the 10x `assign(:page_title, ...)` sites.
- Oban workers: add `Treby.Workers.BaseWorker` with `arg/2` string/atom fallback (`args["id"] || args[:id]` pattern) and shared `@backoff_by_attempt` + `backoff/1`; migrate `data_privacy_export_worker`, `data_privacy_erasure_worker`, `webhook_delivery`, `send_scheduled_message`.
- CSV entry point: make `ImportCsv.run/2` reuse `Treby.CsvImport.parse_csv/1` (+ `auto_detect_mapping`/`preview_import` path) instead of its private `String.split` + `parse_row/1`; `PreviewCsvImport` already uses the central path and stays as reference.

Explicitly out of scope: preload variants with different assocs, `Activities` vs `Audit` merge, Swoosh envelope vs content, PubSub topics, soft-delete policy, modal/business flows, form validate/save pairs (all classified NON-redundancy in the same report).

## Capabilities

### New Capabilities

- None: internal refactor, no new user-facing behavior.

### Modified Capabilities

- None: no REQUIREMENTS change; existing specs (`csv-import`, `audit-log`, `candidate-portal-dashboard`, `data-privacy-export`, `data-privacy-erasure`, `webhooks`, `email-scheduler`) keep current behavior.

## Impact

- Modules under `lib/treby/`: `candidate_portal`, `audit`, `csv_import`, `workers/base_worker` (new small module).
- Modules under `lib/treby_web/live/candidate_portal_live/`: shared mount/guard + title helper (new small helper module).
- No migrations, no API changes, no dependency changes. Risk is low; verification via existing suites for portal, audit, workers, and CSV import.
