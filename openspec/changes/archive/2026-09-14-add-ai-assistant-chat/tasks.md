# Tasks: AI Assistant Chat (v1 minimal)

## 1. Migrations — AI tables only

- [x] 1.1 Generate `mix ecto.gen.migration add_ai_assistant_tables` creating `ai_conversations(id UUIDv7 PK, tenant_id FK, user_id FK, title, status, inserted_at, updated_at)`, `ai_messages(id, conversation_id FK, tenant_id, role, content, tool_calls JSONB, inserted_at)`, `ai_tool_runs(id, message_id FK, tenant_id, tool, args JSONB, status, result JSONB, inserted_at)` with standard FKs. Verify `mix ecto.migrate` + rollback.

## 2. Six hand-written tools (no registry, no refactor)

- [x] 2.1 Create `lib/treby/ai/tools/` with 6 plain modules (`list_jobs`, `create_job`, `update_job`, `delete_job`, `explain_page`, `propose_form_fill`), each with `schema/0`, `destructive?/0`, `run/2` delegating to existing contexts with `tenant_id` first arg from `ctx`. `delete_job` and all writes are destructive.
- [x] 2.2 Unit test each tool: schema shape, tenant-first arg order, cross-tenant id rejected, role check.

## 3. Agent (single, ReqLLM, no Jido, no streaming)

- [x] 3.1 Add `{:req_llm, "~> 1.22"}` dep (`mix deps.get`), configure `config :treby, :ai` with provider + model env overrides.
- [x] 3.2 Implement `lib/treby/ai/context.ex` `build(socket, history)` server-side only, with `form_schema` from `socket.assigns[:form]` changeset when present.
- [x] 3.3 Implement `lib/treby/ai/conversations.ex` (`get_or_create_conversation`, `list_messages`, `create_message`, `reset_conversation`) scoped by `(tenant_id, user_id)`.
- [x] 3.4 Implement `lib/treby/ai/agent.ex` plain module with blocking `ReqLLM` tool loop: inject `ctx.tenant_id`, run reads immediately, persist `:pending_confirm` `ai_tool_runs` for destructives and STOP for user confirm, single PubSub broadcast `ai:{tenant}:{user}` with full markdown reply.
- [x] 3.5 Implement per-item confirmation: `handle_event("confirm_tool_run")` / `"reject_tool_run"` re-invoking the tool + `Treby.Audit.log_event` with `via: "ai"` (one event per execution). No batch in v1.

## 4. Chat page (no drawer, zero JS)

- [x] 4.1 Create route `/:tenant_slug/app/ai` + `lib/treby_web/live/ai_chat_live.ex` with `send_message` / `confirm_tool_run` / `reject_tool_run` / `reset_conversation` events, subscribed to `"ai:#{tenant_id}:#{user_id}"`, rendering session-pinned chat + pending cards + inline reset confirm. Verify light + dark themes.
- [x] 4.2 Wire PubSub broadcast on `ai_messages` insert and `ai_tool_runs` status change; verify two tabs stay in sync. Rate limit via `Treby.RateLimit`.

## 5. Tests + Docs

- [x] 5.1 Add tests: 6 tool schemas, tenant scoping, context spoof ignored, confirm gate, PubSub sync, audit log for AI writes. Run `mix test test/treby/ai` + relevant existing tests.
- [x] 5.2 Ensure change specs stay green: `openspec validate --changes --strict` and fix.
- [x] 5.3 Update `site/features/*.md` + `site/features/index.md` + sidebar `site/.vitepress/config.ts` (user-manual style, English only, no code refs), regenerate screenshots `node scripts/screenshots.mjs`.

## 6. Final verification

- [x] 6.1 Run `mix precommit` and `openspec validate --changes --strict` and fix issues.
