## 1. Persistence and session token

- [x] 1.1 Generate and run `mix ecto.gen.migration add_session_token_to_ai_conversations` adding a nullable `session_token :string` to `ai_conversations` plus an index on `(tenant_id, user_id, session_token, inserted_at)`
- [x] 1.2 Add `session_token` to the `Treby.AI.Conversation` schema and `cast` in its changeset
- [x] 1.3 Rewrite `Treby.AI.Conversations.resolve_conversation/3` and `get_or_create_conversation/3` to resolve the most recent conversation for `(tenant_id, user_id, session_token)`, creating lazily on first message, with no `status` mutation
- [x] 1.4 Rewrite `reset_conversation/3` to create a newer conversation for the same session token and never delete or status-mutate prior conversations
- [x] 1.5 Update `TrebyWeb.Plugs.Auth` to mint a random `ai_session_token` in the session when absent
- [x] 1.6 Rotate (delete) `ai_session_token` on successful login, registration, and OAuth completion so each login starts a fresh chat
- [x] 1.7 Update `AiChatLive` and `Treby.AI.Context` to read and pass the session token instead of `ai_conversation_id`

## 2. Streaming agent

- [x] 2.1 Add `{Task.Supervisor, name: Treby.TaskSupervisor}` to `lib/treby/application.ex`
- [x] 2.2 Replace `Agent.complete/2` with a streaming variant using `ReqLLM.StreamResponse.process_stream/2` with `on_result`, returning the materialized `ReqLLM.Response`
- [x] 2.3 Refactor `Agent.chat/2` to take a context map (not the socket) and broadcast throttled `{:ai_stream, user_id, chunk}` partials plus the existing `{:ai_updated, user_id}` on completion, and `{:ai_error, user_id, reason}` on failure
- [x] 2.4 Keep `handle_response/5`, `append_reads/4`, `persist_pending/3`, confirmation, and rate-limit behavior unchanged
- [x] 2.5 Start the agent in an unlinked supervised task from the `send_message` handler so the host LiveView stays responsive and the task survives navigation

## 3. Page context

- [x] 3.1 Add a shared `on_mount` hook that attaches a `:handle_params` hook setting `current_path` and `current_params` from the URI on every authenticated app page
- [x] 3.2 Subscribe the page/component to the AI PubSub topic from the same hook and relay `:handle_info` messages to the widget
- [x] 3.3 Extend `Treby.AI.Context.build/2` to discover any `%Ecto.Changeset{}` or `%Phoenix.HTML.Form{}` in assigns dynamically, not only the `:form` key
- [x] 3.4 Verify `Context.build/2` receives the host page assigns (path, params, form) from the widget component, not the widget's own assigns

## 4. Widget UI

- [x] 4.1 Create a stateful `AiChatWidget` LiveComponent rendering the floating panel, trigger, message stream, streaming bubble, pending-confirmation cards, reset, and input form, using `TrebyWeb.DesignSystem`/Tailwind tokens and unique DOM IDs
- [x] 4.2 Render the widget inside `Layouts.app/1` so it appears on every authenticated app page (not on `public_header` or `candidate_portal`)
- [x] 4.3 Render each message as markdown via `TrebyWeb.Markdown.to_safe_html/1` (user messages plain), with a streaming bubble rendered progressively
- [x] 4.4 Render the panel as a fixed-size floating surface that does not block interaction with the page beneath
- [x] 4.5 Add a colocated JS hook storing the panel open state in `localStorage` and restoring it on mount; ensure open state survives page changes and refresh
- [x] 4.6 Reuse the same widget on the full `/ai` page so the page and the floating panel share one implementation

## 5. i18n and design

- [x] 5.1 Add English and Italian translations for all new widget strings
- [x] 5.2 Verify the widget in light and dark themes (`data-theme="light"` / `data-theme="dark"`) and on mobile

## 6. Tests

- [x] 6.1 Tests for session-token resolution: same token resumes the conversation, new token starts fresh, reset creates a newer conversation without deleting
- [x] 6.2 Tests for context building: path/params set on a non-AI page and dynamic form discovery
- [x] 6.3 Tests for streaming: chunks broadcast before completion, final message persisted once, rate-limit error path
- [x] 6.4 LiveView test for the widget: renders on an app page, not on the portal, opens/closes, and keeps the conversation across a page navigation
- [x] 6.5 Run `mix precommit` and fix any issues

## 7. Documentation

- [x] 7.1 Update `site/features/` (assistant page) to describe the global widget, streaming replies, and session behavior, in English
- [x] 7.2 Regenerate screenshots with `node scripts/screenshots.mjs`
