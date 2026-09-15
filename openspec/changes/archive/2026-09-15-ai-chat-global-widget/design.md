## Context

The assistant currently lives on a dedicated LiveView page (`lib/treby_web/live/ai_chat_live.ex`) mounted at `/:tenant_slug/app/ai` and `/app/ai` (legacy). It renders history from `ai_conversations`/`ai_messages`, calls `Treby.AI.Agent.chat/2` synchronously inside `handle_event`, and receives one `{:ai_updated, user_id}` PubSub broadcast per completed reply. `Treby.AI.Conversations.resolve_conversation/3` resolves the session-pinned conversation when present, otherwise the most recent `active` row; `reset_conversation/2` soft-deletes the previous active row (`status: "deleted"`). Markdown rendering already goes through `TrebyWeb.Markdown.to_safe_html/1`.

The shared authenticated layout is the `Layouts.app/1` function component (`lib/treby_web/components/layouts.ex`), used by every app LiveView and only by those (`public_header`, `candidate_portal`, `auth_toolbar` are separate, so the candidate portal and public pages never render it). Two `live_session` groups exist for the app (`:default` and `:admin`) plus legacy equivalents. There is no `Task.Supervisor` in the supervision tree and no `localStorage` usage in `assets/js`.

## Goals / Non-Goals

**Goals:**
- Floating, openable/closable assistant available on every authenticated app page, without obstructing page use.
- Token streaming with progressive markdown rendering.
- Current path, query params, and dynamically discovered form/changeset from the host page fed to the agent.
- Server-side application of assistant form proposals to the host page form on confirmation (not advisory-only).
- One chat session per login per `(tenant, user)`, preserved across page changes and refresh, fresh after a new login.
- No deletion or implicit reset of conversation data.

**Non-Goals:**
- Conversation history browser, bulk confirm-all, retention pruning.
- Multi-agent/Jido.
- Chat on the candidate portal or public career pages.

## Decisions

### 1. Widget is a LiveComponent inside `Layouts.app`, not a sticky nested LiveView
A `live_render(@socket, Widget, sticky: true)` child LiveView would own its own process (clean PubSub/streaming) but loses the host page assigns (needed for context) and is destroyed when navigation crosses a `live_session` boundary (`:default` ↔ `:admin`). Since page context is a priority and there are two app `live_session` groups, a stateful `LiveComponent` rendered inside `Layouts.app` is preferred: it is recreated per page and receives fresh host assigns, and it works identically across both groups.

### 2. Streaming runs in a supervised, unlinked Task
`handle_event("send_message", ...)` persists the user message, then starts a task under a new `Task.Supervisor` (`Treby.TaskSupervisor`, added to the supervision tree) that runs the agent loop. The task must outlive the LiveView (user may navigate mid-stream), so it is unlinked from the caller; it communicates results only through PubSub. This also keeps the host page responsive during model calls.

Alternative considered: streaming inside the LiveView process — rejected because it blocks the host page.

### 3. Streaming via `ReqLLM.StreamResponse.process_stream/2`
`process_stream(stream_response, on_result: &broadcast_chunk/1)` emits content chunks as they arrive and returns the fully materialized `ReqLLM.Response` including reconstructed `tool_calls`. This maps onto the existing loop in `Agent.handle_response/5`: `complete/2` changes from `ReqLLM.generate_text` to a streaming variant, while `Response.classify/1`, `append_reads/4`, `persist_pending/3`, and confirmation handling stay the same. Chunk broadcasts are throttled (time-based) to avoid flooding PubSub.

### 4. Page context delivered server-side via a shared `on_mount` hook
A hook attached in `on_mount` (same pattern as `TrebyWeb.Hooks.Notifications`) attaches a `:handle_params` hook that sets `current_path` and `current_params` from the URI on every page, and subscribes the page to the AI PubSub topic. `Layouts.app` passes these assigns plus any form/changeset into the widget component, so `Treby.AI.Context.build/2` can read host context. This avoids client-reported location.

`Context.build/2` is extended to discover any `%Ecto.Changeset{}` or `%Phoenix.HTML.Form{}` in assigns instead of only the `:form` key; the existing scalar snapshot already captures user-entered data of that form.

Alternative considered: a tiny JS hook sending `window.location` — rejected in favour of server-side (less JS).

### 5. Conversation resolution by session token
`SessionController.create/2` (and registration / OAuth completion) rotates `ai_session_token` in the server session; `TrebyWeb.Plugs.Auth` mints one when absent so any authenticated page has a token. `ai_conversations` gains a nullable `session_token` column. Resolution becomes the most recent conversation for `(tenant_id, user_id, session_token)`, created lazily on the first message. Reset creates a newer conversation with the same token; nothing is deleted and `status` is not mutated.

Alternatives considered:
- Latest-active per user (today): cannot distinguish a new login and violates the fresh-session requirement.
- Conversation id pinned directly in the session: requires a controller round-trip to create lazily; the token is simpler and supports lazy creation from the task.
- Soft-delete on rotation: rejected (no deletion).

### 6. Form proposals applied server-side via host LiveView send

When the model calls `propose_form_fill` and the user confirms, the agent sends `{:ai_apply_form, %{assign_key: key, values: values}}` to `host_pid` (the host LiveView pid stored in `ctx`). The `TrebyWeb.Hooks.AIChat` `handle_info` receives it and calls `TrebyWeb.AIForm.apply_values/3`, which updates the form's changeset in assigns and pushes the applied values to the client via `push_event("ai_form_applied", ...)` so the DOM reflects them.

Alternative considered: keep proposals advisory and let the user copy them — rejected because the goal is to co-edit forms, and server-side application gives immediate, accurate DOM updates scoped to the form in context without the user retyping.

### 7. Open/close persistence via a small colocated hook
The widget panel open state is stored in `localStorage` and restored on mount by a minimal client hook. This is the only client-side logic; all context, session, and message state stays server-side. `localStorage` is not used for message content (DB remains the source of truth, per the existing capability).

## Risks / Trade-offs

- [Task outlives LiveView / orphaned streams] → Task is supervised; broadcasts are ignored when no subscriber; on navigation the new LiveView/component reloads persisted state. Mid-stream transient text is not replayed — acceptable.
- [Streaming + tool loops show a preamble that is later replaced by a pending-confirmation card] → On tool-call turns the agent persists the preamble as before; the widget clears the transient buffer on `{:ai_updated}`. Documented as expected.
- [Two logins (two browsers) now have separate conversations; two tabs of one login share one] → Matches the requested "per user per tenant, fresh at login" semantics; topic remains per `(tenant, user)` so both sessions receive reloads but render their own conversation. If cross-talk appears, scope the topic by token.
- [Migration adds a nullable column; existing active conversations have `session_token = NULL`] → First message after deploy resolves no row for the new token and creates a fresh conversation; old rows remain readable but are not resumed. Acceptable and non-destructive.
- [`live_session` boundary] → Solved by the LiveComponent approach; no route restructuring needed.
- [Streaming markdown on every chunk is expensive] → Throttle broadcasts and re-render markdown at most a few times per second; final render on completion.

## Migration Plan

1. `mix ecto.gen.migration add_session_token_to_ai_conversations` → add nullable `session_token :string` plus an index on `(tenant_id, user_id, session_token, inserted_at)`.
2. Add `Treby.TaskSupervisor` to `lib/treby/application.ex`.
3. Deploy: existing rows keep `NULL` token and are not resumed; new logins mint tokens. No data loss.
4. Rollback: stop using the column and the widget; old page and sync path remain until the streaming code replaces it. No destructive migration to reverse.

## Open Questions

- Should the AI PubSub topic be scoped by `session_token` instead of `(tenant, user)` to fully isolate two simultaneous logins? Default: keep `(tenant, user)` and revisit if cross-talk is observed.
- Rate limiting: keep the existing per-user `:ai_message` limit unchanged (yes) or add a per-tenant cap?
- Should the full `/ai` page reuse the same LiveComponent to avoid duplicated markup? Preferred: yes, extract the widget and render it full-width on the page.
