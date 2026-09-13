# Design: AI Assistant Chat

## Context

Treby is a multi-tenant ATS (Phoenix LiveView, Ecto/Postgres). Membership is via `RequireMembership` on_mount which assigns `current_user`, `current_tenant`, `current_membership.role`. Every domain table has `tenant_id` but FKs are single-column (`job_id → jobs.id`), so cross-tenant mis-link is only prevented by application code. LiveView handlers call contexts directly (`Treby.Candidates`, `Treby.Pipeline.Applications`, etc.) — no shared action boundary. No LLM integration exists; `Req` is the mandated HTTP client.

The assistant must: know who/where/which tenant, share history across tabs per-user, allow read instantly but require confirmation for writes, be extensible without hand-maintaining a tool list, and be reusable by LiveView, agent, future APIs/MCP.

## Goals / Non-Goals

**Goals:**
- Single Action Layer used by LiveView, AI agent, and future API/MCP with identical tenant/role checks.
- Context built server-side from socket, never from client payload.
- Auto-discovery of tools via `@ai_tool` annotation → registry → JSON Schema for ReqLLM/Jido.
- App-level tenant isolation via `ctx.tenant_id` (no composite FKs, no hardening migration).
- Per-user conversations shared across tabs; destructive actions require explicit confirmation.
- Sync responses only (no token streaming); LiveView-only UI with a single tiny colocated hook.

**Non-Goals:**
- Candidate portal assistant (team-only).
- Token streaming — deferred indefinitely; single-message replies.
- JSON API for chat (LiveView events only; lifecycle ops are context functions, no routes).
- L3 DOM manipulation (autofill/highlight) — deferred until L1/L2 proven.
- Self-hosted LLM hosting; provider keys via env, abstraction via ReqLLM.
- Full MCP server implementation — only ensure Action Layer is MCP-ready (behaviour contract).
- Composite FK hardening — deferred to a follow-up if ever needed.

## Decisions

### 1. Unified Action Layer — `Treby.Actions` behaviour

```elixir
@callback run(args :: map, ctx :: %{tenant_id: binary, user: User.t(), role: String.t()}) ::
  {:ok, any} | {:error, term}
@callback schema() :: map  # JSON Schema for LLM
@callback destructive?() :: boolean
```

Each action is a module (`Treby.Actions.AdvanceApplication`, `Treby.Actions.CreateNote`, ...). LiveView `handle_event` delegates to `Actions.run/3` instead of calling contexts directly. This makes tenant_first (`tenant_id` first param) and role check centralized. Alternative considered: keep contexts as-is and wrap only for AI — rejected, would duplicate checks and drift.

### 2. Hybrid Beam introspection — `@ai_tool` marker + BEAM-derived schema

Functions opt-in with minimal marker; Beam generates the rest:

```elixir
@ai_tool %{destructive: false}  # no description/schema needed
@doc "Search candidates by name/email within tenant"
@spec search_candidates(binary, map) :: [Candidate.t()]
def search_candidates(tenant_id, filters), do: ...
```

`Treby.AI.Registry` collects `@ai_tool` at compile time via `__on_definition__`, then at compile/runtime derives JSON Schema via Beam introspection:

- `Code.fetch_docs(module)` → `@doc` → LLM description
- `Code.Typespec.fetch_specs(module)` → `@spec` → JSON Schema types (via `ReqLLM.Tool` compatible mapping)
- `module.__info__(:attributes)` → `@ai_tool` flags (`destructive`, `confirm_hint`)
- `Ecto.Changeset` `cast` fields (when action wraps a changeset) → required/optional + validation
- `module.__info__(:functions)` → arity check: `tenant_id` must be first arg, else compile error

Only annotated functions become tools (small surface), but boilerplate is one line. Introspection removes hand-written schema drift. Alternative pure introspection (scan all `Treby.Actions.*` with `tenant_id` first arg via `:code.all_available`) rejected — exposes too many noisy/internal tools. Alternative per-tool `Treby.AI.Tools.*` modules kept as escape hatch when a tool needs custom confirmation UI or non-context logic.

### 3. ReqLLM + Jido Multi-Agent (direct Phase 2, no stub, no streaming)

- **Decision**: no hand-rolled `Req.post`. Direct use of `{:jido, "~> 2.3"}` + `{:req_llm, "~> 1.22"}` (compat `Elixir 1.20` verified on Hex: `jido 2.3.3` requires `~> 1.18`, `req_llm 1.22` requires `~> 1.15`; `req_llm` already uses `req ~> 0.5`, respects AGENTS.md). **No streaming**: blocking `ReqLLM` call → full markdown reply → single broadcast via `Phoenix.PubSub` `ai:{tenant}:{user}` → LiveView `handle_info` renders the whole message. No `:stream` topic, no incremental updates, no streaming hook.
- `Jido` orchestrator (coordinator + specialists). `Treby.AI.Coordinator` as a `Jido.Agent` with `signal_routes`: classifies intent and delegates to specialists via `Directive.spawn_agent` / `emit_to_pid` / `emit_to_parent`, tool subsets from `Registry.for_domain/1`. Pattern from the official Jido guide: parent spawns children, `child.started`, work dispatch, reply, aggregate, `await`, `child.exit` handling + timeouts + `StopChild`.

```
Coordinator (intent router) ──▶ JobAgent     [list_jobs, create_job, update_job, delete_job]
                              ──▶ ExplainAgent [explain_page]
Form intents ──▶ coordinator via form_schema [propose_form_fill]
```

JobAgent owns job mutations (delete and any destructive op requires confirmation); ExplainAgent owns platform help (current page explanation, guided steps). Form co-use (fix texts, pre-fill fields) is handled by the coordinator from `form_schema` with diff preview + confirm. Each specialist owns a filtered `Registry` subset (`Registry.for_domain(:job)` uses `Code.fetch_docs` tags). Adding a domain later = new `Treby.AI.Agents.*` + 2-3 `@ai_tool` actions — zero coordinator changes. All agents share `Treby.AI.Context` and `Treby.Actions` for tenant isolation.

- Agent prompt is built from `Treby.AI.Context.build(socket, history)` — includes user, tenant, page (`live_view`, `url`, `params`, filtered `assigns_snapshot`, `form_schema` when a form is present), permissions. LLM never receives raw `tenant_id` to choose; it is injected by server on tool execution.

Alternative: raw `Req` + custom single-agent loop — rejected, reinvents retries and becomes bottleneck at ~30 tools. Streaming rejected: complicates hook, scroll, and intermediate states for minimal gain.

### 4. Tenant isolation via app layer (no composite FKs)

No `UNIQUE(tenant_id, id)`, no composite FKs, no hardening migration. Isolation via `ctx.tenant_id` from socket (never from LLM), `tenant_id` as first action argument, queries always scoped with `where tenant_id`, tenant-scoped history, PubSub topics including `tenant_id`. New AI tables carry `tenant_id` with standard FKs. DB-level hardening deferred to a follow-up if ever needed.

### 5. Session-kept chat + sync replies + retention (LiveView only)

`ai_conversations` is `(tenant_id, user_id)` scoped with lifecycle `status` (`active`/`concluded`/`deleted`) + `concluded_at`. The drawer never loses content implicitly: on mount LiveView loads history for the session-pinned row via `Treby.AI.Conversations` and renders messages (empty only if nothing was said yet) — mount NEVER creates or resets. Only the Reset button (with in-drawer confirm) creates a new `active` row. Conversation resolution order: explicit `conversation_id` param → session id → latest `active` (`get_or_create_conversation`). Lifecycle operations (list/conclude/reopen/delete) are context functions for retention and auditing, with no HTTP routes; sending a message into a `concluded` chat reopens it. The open/closed UI flag is kept in `localStorage` (`ai-drawer-open`).

Chat events are LiveView `handle_event`s (`send_message`, `confirm_tool_run`, `reject_tool_run`, `reset_conversation`) — no JSON controller. Messages sync via a single `Phoenix.PubSub` topic `"ai:#{tenant_id}:#{user_id}"`. Any tab subscribes on mount; each completed message (user or assistant) broadcasts once to all tabs. AI responses persist as a single `role: "assistant"` row with full markdown. No per-tab state, no incremental updates. Ordering via `inserted_at` + `id` (UUIDv7). Markdown rendered server-side via `TrebyWeb.Markdown` before broadcast.

**Retention 30 days:** `Agent.prune_old_conversations/1` deletes `ai_messages`/`ai_conversations` where `inserted_at < now - 30 days`, run via Oban cron weekly (or `mix treby.prune_ai_history`). Reset never `DELETE`s; delete is a soft status change (see `Requirement: Chat history and reset`).

### 6. Drawer layout (scroll contract)

The drawer is a fixed-height flex column (`Layouts.app`, inline `height:min(480px,calc(100vh-8rem));max-height:70vh;min-height:min(400px,calc(100vh-10rem))` — inline style, not a Tailwind arbitrary class, so it holds even if the CSS scan misses it; the `min-height` keeps it decent on tall screens without overflowing short ones). Strict chain, each level `min-h-0`: `#ai-drawer` (flex-col) → `#ai-chat-root` (`flex-1`) → `#ai-messages` (`flex-1 min-h-0 overflow-y-auto`, the ONLY scrollable region) → form `shrink-0` pinned at the bottom. Header and thinking/reset previews are all `shrink-0` so they never steal scroll space. The only JS is a tiny colocated hook (`AIChatUi`) for the open-flag in `localStorage` and scroll-to-bottom; open/close state itself is driven by LiveView. Every render path (history load, full reply, user append) ends with `scrollTop = scrollHeight`.

### 7. Confirmation for writes + Form Tooling

`Registry.destructive?` is `true` for any write unless explicitly `destructive: false`. When LLM calls a destructive tool, server creates `ai_tool_runs` with `status: :pending_confirm` and returns a tool result prompting confirmation. UI renders card with diff (before/after). User `handle_event("confirm_tool_run")` re-invokes `Actions.run` with original args + `ctx` from socket. Audit logged only on actual execution, one event per executed run.

**Bulk confirm**: multiple pending runs proposed together share a `batch_id` on `ai_tool_runs` (nullable UUID). The drawer renders the batch as stacked cards with per-item Confirm/Reject plus `handle_event("confirm_batch")` / `"reject_batch"` for accept-all/reject-all. Accept-all executes pending runs in order, stops at first error, reports per-item results. Exception: `delete_*` batches NEVER offer accept-all — each delete requires its own click. Form-fill batches (low risk) offer accept-all by default.

**Form tooling**: LiveView forms use `to_form(changeset)` → `Treby.AI.Context` extracts `form_schema` from `Ecto.Changeset` (`cast` fields, `validate_required`, types) when `socket.assigns[:form]` is present. A generic `FillForm` tool proposes `%{field => value}` respecting changeset validations; UI shows preview diff (current vs proposed) before confirm. This reuses the same `Treby.Actions` changeset — no separate form logic.

## Risks / Trade-offs

- **LLM prompt injection via candidate data** → Mitigation: candidate content is treated as data, never as instruction; tool args validated against JSON Schema + Ecto changesets; tenant_id never from LLM.
- **Cost/latency of LLM per message** → Mitigation: cache `assigns_snapshot` per turn, rate-limit per user/tenant via existing `Treby.RateLimit` patterns. Single sync reply, fewer states than streaming.
- **Registry drift (annotation missing / doc/spec missing)** → Mitigation: CI check `mix treby.check_ai_registry` uses `Code.fetch_docs` + `fetch_specs` to warn if `@ai_tool` lacks `@doc`/`@spec` or `tenant_id` not first arg; denylist for internal functions.
- **Cross-tenant memory leak via history** → Mitigation: history query always `where tenant_id == ^ctx.tenant_id`; PubSub topic includes tenant_id; tests for isolation.

## Migration Plan

1. `mix ecto.gen.migration add_ai_assistant_tables` — creates `ai_conversations`, `ai_messages`, `ai_tool_runs` with standard FKs.
2. Deploy code with Action Layer + Registry + drawer (feature-flagged via `config :treby, :ai_enabled`).
3. No data backfill. Rollback: disable flag, drop AI tables.

## Open Questions

- [x] Exact ReqLLM/Jido version pins — resolved: `{:jido, "~> 2.3"}`, `{:req_llm, "~> 1.22"}`, compat `Elixir 1.20` verified via Hex/GitHub (`jido ~> 1.18`, `req_llm ~> 1.15`).
- [x] Initial tools — resolved (narrow scope): `list_jobs`, `create_job`, `update_job`, `delete_job` (destructive → confirm), `explain_page`, `propose_form_fill` (fix texts + pre-fill with diff preview + confirm).
- [x] Confirmation card for bulk operations — resolved: N runs grouped by `batch_id`, per-item Confirm/Reject + accept-all/reject-all (`confirm_batch`/`reject_batch`, stop at first error); `delete_*` forces per-item (no accept-all).
