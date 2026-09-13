# Proposal: AI Assistant Chat

## Why

Team users need an internal chat assistant that can act on their behalf or help them act — aware of who they are, which tenant they belong to, and which page they are on. Today every action requires manual navigation and form filling; repetitive tasks (search, move through pipeline, add notes, schedule) slow down hiring. An assistant that reuses the same backend actions as the UI, with tenant-safe isolation and confirmation for destructive operations, unlocks speed without sacrificing safety.

## What Changes

- **Internal team chat** in `/:tenant_slug/app` (not candidate portal) as a global drawer, per-user conversation history shared across tabs via PubSub. **The drawer keeps its state in the same session: if open it stays open across page changes and reloads, and its content is restored — never lost, never reset implicitly.** Persistence is the DB (`ai_conversations`/`ai_messages`): on mount LiveView loads the session-pinned conversation and renders its messages; only the Reset button starts a new conversation. Old rows are kept 30 days for retention only.
- **Single current chat, no history browser**: the drawer shows no conversation list and no statuses, but the current chat content is always restored on mount. The current chat id is pinned in the logged-in user's server session (`ai_conversation_id`); the open/closed UI flag lives in `localStorage` (`ai-drawer-open`, via a tiny colocated hook) so a reload reopens an open drawer. Past conversations other than the current one are never shown.
- **Context-aware agent**: every message is enriched server-side from `socket.assigns` (user, tenant, membership role, live view + params + assigns snapshot, permissions) — never trusted from client. The client sends only the message text.
- **Unified Action Layer** (`Treby.Actions`) as single truth for domain mutations, used by LiveView handlers, AI agent, future external APIs and MCP. Enforces `tenant_id` as first argument and role checks.
- **Auto-discovered capabilities**: tools are not hand-written lists. Context functions annotated with `@ai_tool` are collected at compile time into `Treby.AI.Registry` which generates JSON Schema for ReqLLM/Jido from `@doc` + `@spec` + Ecto changesets.
- **App-level tenant isolation**: no composite FKs, no hardening migration. Isolation via `ctx.tenant_id` from socket (never from LLM), tenant-first action signatures, tenant-scoped queries, tenant-scoped history, PubSub topics including `tenant_id`. New AI tables carry `tenant_id` with standard FKs.
- **Safety**: read operations execute immediately; all write/destructive operations require explicit user confirmation via a preview card before execution.
- **Provider abstraction (direct Phase 2, no stub, no streaming)**: `ReqLLM ~> 1.22` for multi-provider LLM calls (OpenAI/Anthropic/local, single blocking call), `Jido ~> 2.3` for multi-agent orchestration (coordinator + specialists). No hand-rolled `Req` calls, no token streaming.
- **Multi-agent system with Jido (narrow scope)**: `CoordinatorAgent` (`use Jido.Agent`) routes via signals to `JobAgent` (list/create/update/delete jobs; destructive ops require confirmation) and `ExplainAgent` (helps the user operate the platform: explains current page, guides actions). Form intents are handled by the coordinator via form schema. Adding a domain later = new agent + 2-3 `@ai_tool`, zero coordinator changes.
- **Form tooling (co-use)**: while the user works in a LiveView form, actions reuse `Ecto.Changeset` + `to_form/2` schema so AI can fix texts and pre-fill fields for them; preview card shows diff before confirm, writes apply only on confirmation.
- **Sync response, no streaming**: blocking `ReqLLM` call → full reply persisted → single `Phoenix.PubSub` broadcast `ai:{tenant}:{user}` → LiveView `handle_info` renders the whole message. No `:stream` topic, no incremental updates. The only JS is a tiny colocated hook for the open-flag and scroll-to-bottom.
- **Persistence**: `ai_conversations` (`status`: `active`/`concluded`/`deleted`, `concluded_at`), `ai_messages`, `ai_tool_runs`, all tenant-scoped with standard FKs. The current conversation is pinned in the server session (`ai_conversation_id`); resolution order is explicit `conversation_id` param → session id → latest `active` (`get_or_create_conversation`). Mount NEVER creates a conversation: it renders `list_messages` for the session-pinned row (empty only if nothing was said yet). Only Reset creates a new `active` row (old kept 30 days). Lifecycle operations (list/conclude/reopen/delete) are context functions with no HTTP routes.

## Capabilities

### New Capabilities

- `ai-assistant`: internal chat, context building, history, confirmation flow, sync responses (no streaming).
- `ai-actions-layer`: unified action behaviour, registry, auto-discovery via `@ai_tool`, tenant-first signature.

### Modified Capabilities

- `audit-log`: AI-initiated actions logged with `actor_type: "system"` + `actor_id: user.id` + `metadata: %{via: "ai", prompt, tool}` so audit remains source of truth.
- `authentication`: no behavior change, but AI reuses existing `RequireMembership`/`RequireRole` for authorization.

## Impact

- **Deps**: `{:jido, "~> 2.3"}` (requires `elixir ~> 1.18`, ok with `1.20`), `{:req_llm, "~> 1.22"}` (requires `elixir ~> 1.15`, built on `Req ~> 0.5` already present per AGENTS.md).
- **Migrations**: `mix ecto.gen.migration add_ai_assistant_tables` (new AI tables only, standard FKs, no hardening of existing tables).
- **Modules**: `lib/treby/actions/*` (behaviour + concrete actions including form actions), `lib/treby/ai/registry.ex` (Beam introspection + domain filtering), `lib/treby/ai/context.ex`, `lib/treby/ai/conversations.ex` (history + lifecycle context functions), `lib/treby/ai/coordinator.ex` + `lib/treby/ai/agents/*`, `lib/treby_web/live/ai_chat_live.ex` (or LiveComponent + drawer in `Layouts.app`) + one tiny colocated hook for open-flag/scroll, `mix treby.check_ai_registry` CI check.
- **Breaking**: none. New AI tables only, no changes to existing FKs.
