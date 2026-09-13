# Design: AI Assistant Chat

## Context

Treby is a multi-tenant ATS (Phoenix LiveView, Ecto/Postgres). Membership is via `RequireMembership` on_mount which assigns `current_user`, `current_tenant`, `current_membership.role`. Every domain table has `tenant_id` but FKs are single-column (`job_id → jobs.id`), so cross-tenant mis-link is only prevented by application code. LiveView handlers call contexts directly (`Treby.Candidates`, `Treby.Jobs`, etc.). No LLM integration exists; `Req` is the mandated HTTP client.

The assistant must: know who/where/which tenant, keep per-user history, allow read instantly but require per-item confirmation for writes, help with jobs, explain the platform, and co-use forms. Bone-minimal v1: one page, one agent, hand-written tools.

## Goals / Non-Goals

**Goals:**
- Thin AI-only tools delegating to existing contexts, with identical tenant/role checks, no LiveView refactor.
- Context built server-side from socket, never from client payload.
- Hand-written tool schemas (6 maps), no metaprogramming.
- App-level tenant isolation via `ctx.tenant_id` (no composite FKs).
- Single chat page with per-user history; per-item confirmation for destructive actions.
- Sync responses via blocking `ReqLLM` call; zero JS.

**Non-Goals (follow-ups):**
- `Jido` multi-agent — v1 is a single plain agent module.
- Auto-discovered schemas / registry / CI check.
- Action Layer behaviour + LiveView handler refactor.
- Global drawer (v1 is a dedicated page, native scroll).
- Bulk accept-all (v1 is per-item confirm only).
- Retention pruning (v1 keeps rows).
- Candidate portal assistant (team-only).
- Full MCP server implementation.

## Decisions

### 1. Thin AI-only tool modules (no behaviour, no refactor)

Plain modules under `Treby.AI.Tools.*`, each with:

```elixir
def schema(), do: %{...}        # plain map for ReqLLM
def destructive?(), do: true | false
def run(args :: map, ctx :: %{tenant_id: binary, user: User.t(), role: String.t()}),
  do: {:ok, any} | {:error, term}
```

Each `run/2` delegates to the existing context (e.g. `Treby.Jobs`) with `tenant_id` from `ctx`, never from LLM output. LiveView handlers are untouched. The 6 v1 tools: `list_jobs`, `create_job`, `update_job`, `delete_job`, `explain_page`, `propose_form_fill`.

### 2. Hand-written schemas (no introspection)

Each tool returns a plain schema map compatible with `ReqLLM.Tool`. No `@ai_tool` markers, no `Code.fetch_docs`/`fetch_specs`, no compile-time registry, no `mix treby.check_ai_registry`. A unit test per tool asserts required keys and tenant-first validation. Drift risk is accepted for 6 tools and covered by tests.

### 3. Single agent + ReqLLM blocking tool loop (no Jido)

`{:req_llm, "~> 1.22"}` is the only new dep (requires `elixir ~> 1.15`, built on `req ~> 0.5`, respects AGENTS.md). `Treby.AI.Agent` is a plain module:

```
chat(socket, text):
  ctx = Context.build(socket, history)
  messages = history + [user: text]
  loop:
    reply = ReqLLM.chat_blocking(model, messages, tool_schemas)
    persist assistant message
    if reply has tool_calls:
      for each call: inject ctx.tenant_id
        read tool → run now, append result, continue loop
        destructive tool → persist ai_tool_runs :pending_confirm, render card, STOP (wait user)
    else: broadcast full reply, done
```

No streaming: single `Phoenix.PubSub` broadcast `ai:{tenant}:{user}` per completed message → LiveView `handle_info` renders it whole.

### 4. Tenant isolation via app layer (no composite FKs)

No `UNIQUE(tenant_id, id)`, no composite FKs, no hardening migration. Isolation via `ctx.tenant_id` from socket (never from LLM), `tenant_id` as first tool argument, queries always scoped with `where tenant_id`, tenant-scoped history, PubSub topics including `tenant_id`. New AI tables carry `tenant_id` with standard FKs.

### 5. Dedicated chat page + history (no drawer, no JS)

Route `/:tenant_slug/app/ai` rendering `AiChatLive` (standard page, native scroll, zero JS). On mount it loads the session-pinned conversation via `Treby.AI.Conversations` (`get_or_create_conversation`: session id → latest `active`) and renders messages — mount NEVER resets. Only the Reset button (with inline confirm) creates a new `active` row. Each completed message broadcasts once on `"ai:#{tenant_id}:#{user_id}"` so multiple tabs stay in sync. Chat events are LiveView `handle_event`s (`send_message`, `confirm_tool_run`, `reject_tool_run`, `reset_conversation`) — no JSON routes. No retention pruning in v1.

### 6. Per-item confirmation + Form co-use (no batch)

`destructive?()` is `true` for any write. When the agent calls a destructive tool, server persists `ai_tool_runs` `:pending_confirm` and renders a card with diff (before/after); each card has its own Confirm/Reject — no accept-all in v1. `confirm_tool_run` re-invokes the tool with original args + `ctx` from socket. Audit logged only on actual execution, one event per run.

**Form co-use**: `Context.build` extracts `form_schema` from `Ecto.Changeset` (`cast` fields, `validate_required`, types) when `socket.assigns[:form]` is present. `propose_form_fill` proposes `%{field => value}` (text fixes, pre-fill) respecting changeset validations; UI shows diff preview; values apply only on per-item confirm.

## Risks / Trade-offs

- **LLM prompt injection via job/form data** → Mitigation: content treated as data, never instruction; args validated against hand-written schemas + Ecto changesets; tenant_id never from LLM.
- **Hand-written schema drift** → Mitigation: one unit test per tool asserting schema shape; only 6 tools.
- **Cost/latency per message** → Mitigation: single blocking call, rate-limit per user/tenant via `Treby.RateLimit`.
- **Cross-tenant leak via history** → Mitigation: history always `where tenant_id == ^ctx.tenant_id`; PubSub topic includes tenant_id; isolation test.

## Migration Plan

1. `mix ecto.gen.migration add_ai_assistant_tables` — creates `ai_conversations`, `ai_messages`, `ai_tool_runs` with standard FKs.
2. Deploy code behind `config :treby, :ai_enabled` flag.
3. No data backfill. Rollback: disable flag, drop AI tables.

## Open Questions

None open for v1. Follow-ups tracked in proposal Impact.
