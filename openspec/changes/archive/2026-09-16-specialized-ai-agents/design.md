## Context

Today `Treby.AI.Agent` runs a hand-written ReAct loop (`run_loop`) over `ReqLLM`, with six tools registered in `Treby.AI.Tools` and history persisted in `Treby.AI.Conversations`. The agent context (`Treby.AI.Context.build/2`) already snapshots the current LiveView assigns (`assigns_snapshot`) and the editing form (`form_schema`/`form_assign_key`), and `propose_form_fill` already pushes values to the page via `host_pid`.

We want more domains, less UI clicking, and specialized agents — without a new framework. The existing loop, tools, history, PubSub streaming, and confirm flow are kept; we add a thin session/router/profile layer on top.

## Goals / Non-Goals

**Goals:**
- Specialized profiles selected per turn by an LLM router.
- Tools covering the whole recruiting system, each calling existing business modules.
- Agent reads the current page and writes form values.
- Human confirmation on destructive tools preserved.

**Non-Goals:**
- No separate OTP process per specialized agent (profiles, not processes) — process-based error isolation may come later.
- No API / MCP exposure of tools in this change.
- No rewrite of business logic; tools are thin wrappers.

## Decisions

### Profiles are config, not processes
A profile is `%{domain, system_prompt, tools}`. `Treby.AI.Profiles.profiles()` returns a map keyed by domain. The single `run_loop` receives the chosen profile's toolset and prompt. This reuses the existing loop and avoids spawning one GenServer per agent.

### Router is an LLM classifier, sticky with fallback
`Treby.AI.Router.classify(history, last_domain)` sends the last N messages to a small ReqLLM prompt and returns a domain atom. Sticky: keep `last_domain` unless the classifier returns a different domain with confidence, or the agent emitted a handoff. On LLM failure, fall back to `last_domain` (fail-closed to the previous domain).

### Agent signals domain exit via a `handoff` tool
A non-destructive `handoff` tool lets the agent report "this is not my domain". `Treby.AI.Session` stores the new domain and re-routes the next turn. This is deterministic and LLM-friendly, better than parsing free-text replies.

### Tool registry split by domain
`Treby.AI.Tools` dispatches `get/name` across per-domain registries (`Recruiter`, `Analytics`, `Comms`, `Admin`). Existing `CreateJob`/`UpdateJob`/`DeleteJob`/`ListJobs`/`ExplainPage`/`ProposeFormFill` move into the relevant registries. Each new tool's `run/2` calls the existing business module directly (e.g. `Treby.Candidates.create_candidate`, `Treby.Pipeline.move_application`).

### Page read/write
- Read: `Context.build` already produces `assigns_snapshot` (scalar assigns). Enrich it to also serialize the key Ecto structs present on the page (job, candidate, application) into JSON-safe form, and include a readable page section in `system_prompt`.
- Write: `propose_form_fill` stays; `Agent.maybe_apply_form` sends `{:ai_apply_form, ...}` to `host_pid` (existing path).

### Per-user session
`Treby.AI.Session` is a GenServer, one per user, registry key `user:#{tenant}:#{user}`. State: `%{tenant_id, user_id, conversation, domain, host_pid, form_assign_key}`. On start it rebuilds `conversation` from `Treby.AI.Conversations.list_messages/1`. Working state is volatile; message history is already durable in `Conversations`.

## Risks / Trade-offs

- [Router mis-classifies] → sticky + handoff + fallback to last_domain; low blast radius because tools are tenant-scoped and destructive ones require confirmation.
- [Tool surface grows] → curate to chat-friendly actions only; avoid exposing internal/maintenance functions (e.g. duplicate-flag recompute).
- [Page snapshot too large] → only serialize explicitly relevant structs, JSON-safe via existing `safe_json`/`sanitize`.
- [Profiles not isolated processes] → no separate fault boundary per agent; acceptable now, can add later.

## Migration Plan

No migrations. Rollback = revert the new modules; the existing single-agent path is preserved until `Agent.chat/2` is switched to use `Session` + `Router`.
