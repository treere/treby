# Proposal: AI Assistant Chat

## Why

Team users need an internal chat assistant that can act on their behalf or help them act — aware of who they are, which tenant they belong to, and which page they are on. Today every action requires manual navigation and form filling; repetitive tasks slow down hiring. An assistant that reuses the existing contexts, with tenant-safe isolation and confirmation for destructive operations, unlocks speed without sacrificing safety.

## What Changes

- **Internal team chat page** at `/:tenant_slug/app/ai` (not candidate portal) for authenticated team members. Per-user conversation history shared across tabs via PubSub. Content is restored on mount — never lost, never reset implicitly. Persistence is the DB (`ai_conversations`/`ai_messages`): on mount LiveView loads the session-pinned conversation; only the Reset button starts a new conversation. No retention pruning in v1 (follow-up).
- **Single current chat, no history browser**: the page shows no conversation list and no statuses. The current chat id is pinned in the logged-in user's server session (`ai_conversation_id`). Past conversations other than the current one are never shown.
- **Context-aware agent**: every message is enriched server-side from `socket.assigns` (user, tenant, membership role, live view + params + assigns snapshot, permissions) — never trusted from client. The client sends only the message text.
- **Thin AI-only tools**: plain modules (`Treby.AI.Tools.*`) with `run/2`, `schema/0`, `destructive?/0`, delegating to the existing contexts. No Action Layer behaviour, no LiveView refactor — LiveView handlers keep calling contexts directly.
- **Hand-written tool schemas**: 6 schemas as plain maps, no Beam introspection, no compile-time registry, no CI check. Schema drift is covered by unit tests.
- **App-level tenant isolation**: no composite FKs, no hardening migration. Isolation via `ctx.tenant_id` from socket (never from LLM), tenant-first tool signatures, tenant-scoped queries, tenant-scoped history, PubSub topics including `tenant_id`. New AI tables carry `tenant_id` with standard FKs.
- **Safety**: read operations execute immediately; all write/destructive operations require explicit per-item user confirmation via a preview card before execution. No bulk accept-all in v1 (follow-up).
- **Single provider call, single agent, no streaming**: `ReqLLM ~> 1.22` single blocking call inside a plain `Treby.AI.Agent` module with a hand-written tool loop. No `Jido`, no hand-rolled `Req`, no token streaming.
- **Narrow capabilities**: `JobAgent` scope becomes plain tools — list/create/update/delete jobs (destructive ops require confirmation); `ExplainAgent` scope becomes `explain_page` (helps the user operate the platform); form co-use via `propose_form_fill` (fixes texts and pre-fills fields while the user works in a form, diff preview, applies only on confirmation).
- **Sync response, no streaming**: blocking `ReqLLM` call → full reply persisted → single `Phoenix.PubSub` broadcast `ai:{tenant}:{user}` → LiveView `handle_info` renders the whole message. No `:stream` topic, no incremental updates, zero JS.
- **Persistence**: `ai_conversations` (`status`: `active`/`deleted`), `ai_messages`, `ai_tool_runs`, all tenant-scoped with standard FKs. The current conversation is pinned in the server session (`ai_conversation_id`); resolution order is session id → latest `active` (`get_or_create_conversation`). Mount NEVER creates a conversation: it renders `list_messages` for the session-pinned row (empty only if nothing was said yet). Only Reset creates a new `active` row.

## Capabilities

### New Capabilities

- `ai-assistant`: internal chat page, context building, history, per-item confirmation flow, sync responses (no streaming).
- `ai-actions-layer`: thin AI-only tool modules with hand-written schemas and tenant-first signatures.

### Modified Capabilities

- `audit-log`: AI-initiated actions logged with `actor_type: "system"` + `actor_id: user.id` + `metadata: %{via: "ai", prompt, tool}` so audit remains source of truth.
- `authentication`: no behavior change, but AI reuses existing `RequireMembership`/`RequireRole` for authorization.

## Impact

- **Deps**: `{:req_llm, "~> 1.22"}` only (requires `elixir ~> 1.15`, built on `Req ~> 0.5` already present per AGENTS.md). No `Jido`.
- **Migrations**: `mix ecto.gen.migration add_ai_assistant_tables` (new AI tables only, standard FKs).
- **Modules**: `lib/treby/ai/tools/*` (6 plain tool modules), `lib/treby/ai/agent.ex` (single agent + tool loop), `lib/treby/ai/context.ex`, `lib/treby/ai/conversations.ex`, `lib/treby_web/live/ai_chat_live.ex` (dedicated page, zero JS).
- **Breaking**: none. New AI tables only, no changes to existing code paths.
- **Follow-ups (not in v1)**: Jido multi-agent, auto-discovered schemas, Action Layer + LiveView refactor, global drawer, bulk accept-all, retention pruning.
