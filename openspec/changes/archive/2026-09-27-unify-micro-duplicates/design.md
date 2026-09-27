## Context

Five verified micro-duplications from `reports/ridondanze-architettura-2026-09-26.md` (points 6, 7, 11, 12) are pure copy-paste with zero behavior value. Current state: 4x identical `messages: @messages_query` preloads in the `CandidatePortal` context; ~25 `Audit.log_event` call sites hand-building the same `%{tenant_id, actor_id, metadata %{before, after}}` envelope across jobs, candidates, stages, scorecards, customization, interviews; 6x `mount(%{"tenant_slug" => slug})` + tenant guard plus 10x `assign(:page_title, ...)` in `CandidatePortalLive` views; 4 Oban workers repeating `args["id"] || args[:id]` fallback and per-worker backoff tables; two CSV parse paths (`Treby.CsvImport.parse_csv/1` used by preview vs. private `String.split` + `parse_row/1` in `ImportCsv`).

Constraints: multi-tenancy (`tenant_id` scoping on every query, slug-based portal URLs) must not weaken; auth (team session, portal OTP/magic-link guard) unchanged; no migrations, no API changes, no new dependencies; LiveView conventions (`<Layouts.app>`, `<.input>`, streams, `to_form/2`, no inline `<script>`) stay as-is.

## Goals / Non-Goals

**Goals:**
- Give each of the five duplications exactly one owner helper with identical runtime behavior.
- Keep call-site diffs mechanical (argument passing only, no logic moves).
- Verify with existing suites only (portal, audit, workers, CSV import); no new user-facing behavior.

**Non-Goals:**
- No preload variants with different assocs; no `Activities` vs `Audit` merge; no Swoosh envelope/content unification; no PubSub topic, soft-delete, modal/flow, or form validate/save changes (all classified NON-redundancy in the same report).
- No new abstractions beyond the five tiny helpers; no retry-policy, backoff-value, CSV-dialect, or title-copy changes.
- No docs-site updates (internal refactor, no user-visible change).

## Decisions

### (a) Shared messages preload lives in the `CandidatePortal` context

**Decision:** Add `CandidatePortal.messages_preload/0` (function returning the existing `messages: @messages_query` keyword) in the domain context; the 4 sites in `candidate_portal.ex` call it.

**Rationale:** The preloaded query is domain knowledge (which assocs a portal message needs). A zero-arity function is testable and allows future parameterization without touching call sites.

**Alternatives considered:**
- Module attribute consumer (`@messages_preload` shared): rejected — attributes cannot take future args and are harder to unit-test in isolation.
- Web-layer helper (`LiveHelpers` / portal Live module): rejected — leaks domain preload shape into `treby_web`; context callers outside LiveView could not reuse it.

### (b) Audit envelope helper unifies tenant/actor/meta only, keeps event/payload args

**Decision:** Add thin `Audit.log_change/5`-style wrapper (exact arity follows existing `log_event` convention) with signature conceptually `(tenant, actor_id, event, before, after, extra_payload \\ %{})`. It builds only the repeated envelope `%{tenant_id, actor_id, metadata: %{before: ..., after: ...}}` merged with caller-supplied extra payload, then delegates to the existing `log_event`. Callers in jobs, candidates, stages, scorecards, customization, interviews pass `before`/`after` only; `event` string and payload keys stay at call sites. `log_event` contract unchanged.

**Rationale:** The duplication is the envelope, not the event vocabulary. Keeping `event`/`payload` at call sites avoids a giant event-name registry and keeps the diff mechanical (delete envelope literal, pass two values).

**Alternatives considered:**
- Full replacement of `log_event` with event atoms/structs: rejected — invasive, touches ~25 sites semantically, risks behavior drift.
- Macro injecting the envelope: rejected — hides `tenant_id`/`actor_id` flow, harder to grep and test than a plain function.

Tenant isolation: helper takes `tenant`/`tenant_id` explicitly as today; no implicit process-dictionary tenant. Authorization unchanged (callers already authorized before logging).

### (c) Portal mount/guard + page title helper lives in a portal-scoped Live helper module

**Decision:** New small module under `lib/treby_web/live/candidate_portal_live/` (e.g. portal helpers) exposing `mount_portal/2` (handles `%{"tenant_slug" => slug}` lookup + not-found/unauthorized guard). All six portal `mount/3` callbacks route through it. Page titles stay inline (verified: all 7 title strings distinct — a helper would dedup nothing). `schedule.ex` keeps its nil-tolerant slug variant (different semantics, not migrated).

**Rationale:** The slug-guard sequence is portal-specific (public slug URL, candidate session check) and does not belong in global helpers. Scoping it to `CandidatePortalLive` keeps blast radius to the portal and avoids coupling unrelated LiveViews to portal auth semantics. The title helper lives alongside because its call sites are the same views and its values are portal copy.

**Alternatives considered:**
- Global `LiveHelpers`: rejected — pollutes every LiveView with portal slug logic; future portal guard changes would look like global changes.
- Domain (`CandidatePortal`) module: rejected — `mount`/`assign` are LiveView concerns (`socket` manipulation); putting them in the domain context breaks layering.

### (d) `BaseWorker` scope is args fallback + backoff only

**Decision:** New `Treby.Workers.BaseWorker` providing via `use` only: `arg(args, key)` handling `args["key"] || args[:key]` string/atom fallback, plus shared `backoff/1` over per-worker `@backoff_by_attempt`/`@backoff_default` tables (values legitimately differ per worker, kept verbatim in each worker). Migrate `data_privacy_export_worker`, `data_privacy_erasure_worker`, `webhook_delivery`, `send_scheduled_message` to `use` it and delete local copies. No `perform` wrapper, no telemetry/logging, no retry-attempt policy change, no queue/unique-config consolidation.

**Rationale:** The verified duplication is exactly these two snippets. Anything more (shared perform pipeline, error reporting) is speculative abstraction across workers with different side effects (S3 export vs. erasure vs. webhook POST vs. scheduled send).

**Alternatives considered:**
- Rich base with `perform` template + error handling: rejected — couples unrelated failure modes; behavior-change risk for privacy-critical erasure path.
- Plain functions module without `__using__`: rejected — backoff attribute sharing is cleaner via `use`; plain imports would still duplicate the attribute per worker.

Error handling: backoff values byte-identical to today; workers fail/retry exactly as before (fail-closed preserved, no new rescue).

### (e) Single CSV split entry point: `Treby.CsvImport.parse_lines/1`

**Decision:** `ImportCsv.run/2` drops its private `String.split` and calls the new central `Treby.CsvImport.parse_lines/1` (NimbleCSV, same splitter `parse_csv` uses). The positional row mapper stays: import semantics are positional, preview's are header-mapped — unifying them would change behavior. Malformed input returns the preview-shaped error; no fail-open.

**Rationale:** Preview is the proven reference implementation of the central path. Reusing it for import deletes a second dialect (different split/trim/quote edge cases) with no new parser dependency.

**Alternatives considered:**
- New third parser or new dependency (NimbleCSV et al.): rejected — adds a dependency and a third dialect instead of deleting one.
- Extracting a shared private helper used by both but keeping two entry points: rejected — leaves two owners; the goal is one entry point.

Error handling: malformed rows propagate through the central error shape; no fail-open (import still rejects bad rows exactly as preview reports them). No caching (imports are one-shot).

## Risks / Trade-offs

- [Risk] Helper signature mismatch at one of ~25 Audit sites → compile/runtime error → Mitigation: keep `log_event` intact as the single delegate; mechanical per-domain migration with existing audit specs as gate.
- [Risk] Portal guard subtlety (slug not found vs. unauthorized) flattened by shared `mount_portal/2` → Mitigation: helper reproduces current branch order verbatim; portal Live tests cover both branches.
- [Risk] Backoff table copy error during worker migration → changed retry timing → Mitigation: copy values verbatim, no re-tuning; worker tests plus Oban config assertions gate.
- [Risk] CSV edge-case divergence (quoting/BOM) between old private parser and central path → Mitigation: central path is the preview-tested one; existing CSV import/preview suites must pass unchanged — any fixture diff means stop and keep old path for that case.
- Trade-off: five new tiny indirection points (one function call each) for zero behavior gain — accepted because edit risk of five copy-paste clusters exceeds one-hop read cost.

## Migration Plan

1. Add helpers without callers (context function, Audit wrapper, portal helper module, `BaseWorker`, CSV reuse import) — pure additions, suite green.
2. Migrate call sites one cluster at a time in this order: portal preload → Audit envelope → portal mount/title → workers → CSV entry point. Run the relevant existing suite after each cluster.
3. Delete now-dead private duplicates (`parse_row/1`, per-worker backoff tables, repeated envelopes) only after its cluster is green.
4. Full `mix precommit` + affected suites; rollback is revert of the cluster commit (no migrations, no data changes).

## Open Questions

None. All five decisions resolved above; no behavior change, verification via existing suite.
