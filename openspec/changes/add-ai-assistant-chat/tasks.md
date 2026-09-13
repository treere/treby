# Tasks: AI Assistant Chat

## 1. Migrations — AI tables only

- [ ] 1.1 Generate `mix ecto.gen.migration add_ai_assistant_tables` creating `ai_conversations(id UUIDv7 PK, tenant_id FK, user_id FK, title, status, concluded_at, inserted_at, updated_at)`, `ai_messages(id, conversation_id FK, tenant_id, role, content, tool_calls JSONB, inserted_at)`, `ai_tool_runs(id, message_id FK, tenant_id, tool, args JSONB, status, result JSONB, inserted_at)` with standard FKs. Verify `mix ecto.migrate` + rollback.

## 2. Action Layer + Registry

- [ ] 2.1 Create `lib/treby/actions/behaviour.ex` defining `Treby.Actions` behaviour (`run/2`, `schema/0`, `destructive?/0`) and `ctx` struct `%{tenant_id, user, role}` with `from_socket/1` helper reusing `RequireMembership`.
- [ ] 2.2 Create `lib/treby/ai/registry.ex` collecting `@ai_tool` marker at compile time, deriving JSON Schema via Beam introspection (`Code.fetch_docs/1`, `Code.Typespec.fetch_specs/1`, changeset `cast` fields) with `tenant_id` first-arg validation, exposing `list_tools/0`, `get/1`, `destructive?/1`, `for_domain/1`. Add `mix treby.check_ai_registry` CI check erroring on missing `@doc`/`@spec`.
- [ ] 2.3 Extract initial actions as `Treby.Actions.*` delegating to existing contexts (`ListJobs`, `CreateJob`, `UpdateJob`, `DeleteJob`, `ExplainPage`) plus `ProposeFormFill` (fix texts + pre-fill from changesets with diff preview), all with `tenant_id` first arg and role check, covered by unit tests. `DeleteJob` and any destructive op require confirmation. Refactor corresponding LiveView `handle_event`s to call `Actions.run`.

## 3. AI Context + Conversations + Jido agents (direct Phase 2, no streaming)

- [ ] 3.1 Add `{:jido, "~> 2.3"}` + `{:req_llm, "~> 1.22"}` deps (`mix deps.get`), configure `config :treby, :ai` with provider + model env overrides.
- [ ] 3.2 Implement `lib/treby/ai/context.ex` `build(socket, history)` returning `%{user, tenant, page: %{live_view, url, params, assigns_snapshot, form_schema}, permissions}` server-side only, deriving `form_schema` from `socket.assigns[:form]` changeset when present.
- [ ] 3.3 Implement `lib/treby/ai/conversations.ex` (`get_or_create_conversation`, `list_messages`, `create_message`, `reset_conversation`, `conclude/reopen/delete`) scoped by `(tenant_id, user_id)`, plus 30-day prune (`mix treby.prune_ai_history`, Oban cron weekly).
- [ ] 3.4 Implement `lib/treby/ai/coordinator.ex` + `lib/treby/ai/agents/*` as `use Jido.Agent` with blocking `ReqLLM` calls (narrow scope): coordinator routes via `spawn_agent`/`emit_to_pid`/`emit_to_parent` to `JobAgent` (`list_jobs`, `create_job`, `update_job`, `delete_job`) and `ExplainAgent` (`explain_page`), form intents via `form_schema` (`propose_form_fill`); tool loop injects `ctx.tenant_id`, creates `ai_tool_runs` `:pending_confirm` for destructive tools; single PubSub broadcast `ai:{tenant}:{user}` with the full markdown reply.
- [ ] 3.5 Implement confirmation flow: `ai_tool_runs` pending card (+ `batch_id` grouping, `confirm_batch`/`reject_batch` accept-all stopping at first error, no accept-all for `delete_*`), `handle_event("confirm_tool_run")` / `"reject_tool_run"` re-invoking `Actions.run` + `Treby.Audit.log_event` with `via: "ai"` (one event per execution). Unit test destructive vs read paths + bulk paths.

## 4. LiveView UI — drawer, single chat, shared across tabs

- [ ] 4.1 Create `lib/treby_web/live/ai_chat_live.ex` (or LiveComponent + drawer in `Layouts.app`) with `send_message` / `confirm_tool_run` / `reject_tool_run` / `reset_conversation` events, subscribed to `Phoenix.PubSub` `"ai:#{tenant_id}:#{user_id}"`, rendering session-pinned chat, pending-confirmation cards, in-drawer reset confirm. No JSON routes. Verify light + dark themes.
- [ ] 4.2 Add one tiny colocated hook for `localStorage` open-flag (`ai-drawer-open`) + scroll-to-bottom only. No streaming hook.
- [ ] 4.3 Wire PubSub broadcast on `ai_messages` insert and `ai_tool_runs` status change; verify two browser tabs stay in sync. Add rate limiting via `Treby.RateLimit` for AI messages.

## 5. Tests + Docs

- [ ] 5.1 Add tests: registry discovery, app-level tenant scoping (cross-tenant id rejected), context tenant spoof ignored, confirmation gate, PubSub sync, audit log for AI writes. Run `mix test test/treby/ai` + relevant existing tests.
- [ ] 5.2 Ensure change specs stay green: `openspec validate --changes --strict` and fix.
- [ ] 5.3 Update `site/features/*.md` + `site/features/index.md` + sidebar `site/.vitepress/config.ts` for the new AI Assistant feature (user-manual style, English only, no code refs), regenerate screenshots `node scripts/screenshots.mjs`, verify `grep -R "btn btn-primary\|badge badge-" lib/treby_web` clean.

## 6. Final verification

- [ ] 6.1 Run `mix precommit` and `openspec validate --changes --strict` and fix issues.
