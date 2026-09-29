## Context

The assistant chat (`AiChatWidget` live component + `Hooks.AiChat` relay + `AI.Agent`/`Conversations` backend) already supports destructive-tool confirmation: pending runs are stored in `ai_tool_runs` with `pending_confirm` status and re-broadcast over `ai:{tenant_id}:{user_id}`. The confirmation UI is a single amber card rendering `Jason.encode!(run.args, pretty: true)` inside a `<pre>` — accurate but unreadable for non-technical users.

Page refresh is currently chat-scoped only: `{:ai_updated, user_id}` triggers `send_update` with `ai_reload: true`, which reloads the widget's messages and pending runs. The host LiveView (jobs list, candidates, pipeline, etc.) never learns that an entity changed, so the user must manually reload to see a job created from chat.

Constraints: multi-tenant isolation on every query and broadcast; LiveView streams for collections; design-system styling with light/dark support; no new DB tables expected; no new external dependencies.

## Goals / Non-Goals

**Goals:**
- Readable per-tool confirmation cards (title + key fields + collapsible raw JSON).
- Host-page live refresh after a confirmed chat mutation, without full-page reload.
- Generic fallback so tools/pages without custom handling still behave sanely.

**Non-Goals:**
- No change to authorization, confirmation policy (which tools need confirmation), audit logging, or rate limiting.
- No bulk accept-all for pending runs.
- No cross-user or cross-tenant broadcasting.
- No redesign of the chat panel itself (layout, streaming, persistence untouched).

## Decisions

### 1. Per-tool `summary/1` callback with generic fallback (over custom template per tool)

Each tool module optionally implements `summary(args) -> %{title: binary, fields: [{label, value}]}`. A shared `Tools.describe(tool_name, args)` helper returns the custom summary when present, otherwise a generic humanizer (humanized key labels, truncated values, max ~8 rows). All 62 destructive tools get a curated summary; the fallback exists only as a safety net for unknown or future tools, enforced by a test enumerating every destructive tool.

- Why: ~100 tool modules exist and 62 need confirmation; data-driven rows cover all cases without custom UI per tool, while curated titles/fields keep IDs, enums, and nested payloads (e.g. custom fields, schedule payloads) meaningful.
- Alternative considered: pure generic formatter with no per-tool override — rejected because IDs, enums, and nested payloads (e.g. custom fields, schedule payloads) need curation to be meaningful.
- Alternative considered: full HEEx component per tool — rejected as too much code for the gain; data-driven rows cover 95% of cases.

### 2. Confirmation card = summary rows + `<details>` raw JSON (over hiding JSON entirely)

The card shows the action title, up to ~8 label/value rows, Confirm/Cancel buttons (unchanged events), and a collapsed "Details" disclosure containing the existing pretty-printed JSON.

- Why: preserves transparency/debuggability (support can still see exact args) while making the default view scannable. Zero behavior change to confirm/reject flow.
- Caching/error strategy: summary is pure rendering of already-loaded `run.args`; no extra queries; rendering failure falls back to the current raw JSON block (fail-closed to today's behavior).

### 3. Page refresh via `{:ai_entity_changed, user_id, entity}` PubSub message + opt-in `handle_info` clauses (over `send_update` to arbitrary LiveViews or full `push_navigate` reload)

After `Agent.confirm_tool_run/2` succeeds, the agent broadcasts `{:ai_entity_changed, user_id, %{type, id, tenant_id}}` on the same per-user topic alongside the existing `{:ai_updated, user_id}`. `Hooks.AiChat.handle_info` forwards entity messages to the host via `send(self(), ...)` so each LiveView can pattern-match and refresh its own streams/assigns (e.g. `stream_insert(:jobs, job)` or re-list). Pages without a clause show a flash with a link to the entity.

- Why: the hook already subscribes every authenticated LiveView to the per-user topic and relays to the widget; reusing that channel keeps tenant/user isolation identical (topic is `ai:{tenant_id}:{user_id}`, guarded by `user_id == socket.assigns.current_user.id`). Per-page `handle_info` clauses respect each page's own query/stream setup instead of forcing a one-size-fits-all reload. `push_navigate`/reload would lose scroll, filters, and Kanban drag state.
- Alternative considered: broadcasting directly to a per-tenant topic all LiveViews share — rejected (leaks other users' actions into your page; breaks per-user isolation).
- Alternative considered: `Phoenix.PubSub` + `handle_info` in every LiveView from day one — accepted incrementally: jobs list/detail, candidates list, pipeline, notes first; generic flash fallback covers the rest.
- Entity payload derivation: `Tools.run` result already returns the created/updated struct for most mutating tools; a small `Tools.entity_of(tool_name, result)` maps `{tool, result}` to `%{type, id}` with `nil` fallback (→ flash-only path).

### 4. Confirm path stays synchronous in the widget event; broadcast after commit (over optimistic UI)

`confirm_tool_run` event → `Agent.confirm_tool_run` → DB update committed → broadcast `ai_updated` (existing) + `ai_entity_changed` (new). The widget reloads from DB as today; the host page refreshes from DB on receipt.

- Why: no new race between chat state and page state; both read committed rows. Keeps the existing "reload from DB" pattern in both places.

## Risks / Trade-offs

- [Risk] Stale page filters: a stream_insert may insert a job the current filter would exclude → Mitigation: pages re-run their current filter/query on entity change when cheap (jobs/candidates lists), stream_insert only on detail pages.
- [Risk] Noisy refreshes when the user has the chat open on an unrelated page → Mitigation: each page only reacts to entity types it displays; others ignore the message (flash only for the acted-on entity when it makes sense, suppressed otherwise).
- [Risk] Per-tool summaries drift from schemas → Mitigation: fallback formatter covers missing keys; add a test asserting every destructive tool either implements `summary/1` or renders via fallback without crashing.
- [Risk] Long values (descriptions, JSON blobs) blow up the card → Mitigation: truncate values at ~120 chars with full text in Details; CSS `break-words` + `overflow-hidden` per design-system card pattern.
- [Risk] i18n gaps for new labels → Mitigation: card chrome ("Confirmation required", "Confirm", "Cancel", "Details", flash notices) uses `gettext`; curated summary titles and field labels stay English-only (accepted: translating 62 per-tool vocabularies is out of scope; the translation-coverage guard covers the chrome strings).

## Migration Plan

1. Add `Tools.describe/2` + optional `summary/1` callback (default fallback); widget renders new card with Details disclosure. No migration, no config change. Rollback: revert widget template.
2. Add `ai_entity_changed` broadcast + hook forwarding + per-page `handle_info` clauses (jobs, candidates, pipeline, notes). No migration. Rollback: remove clauses; `ai_updated` path keeps chat working.
3. Update user manual (`site/features/`) + regenerate screenshots. Rollback: docs-only revert.

## Open Questions

- ~~Which entity types beyond job/candidate/application/note/interview need curated summaries in v1?~~ Resolved: all 62 destructive tools got curated summaries, enforced by a coverage test.
- ~~Should the flash fallback include a direct link to the entity?~~ Resolved: text-only notice naming the entity — flash messages render text only, so no link is embedded.
