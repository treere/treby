## Why

The assistant is only reachable from a dedicated page, replies arrive only once fully generated, and its conversation is resolved as "latest active" for the user. Users want to ask for help while staying on the page they are working on, see the answer appear as it is written, and have one chat session per login that survives page changes and refresh. The current blocking flow also freezes the page LiveView while the model is called.

## What Changes

- **Global chat widget**: a floating, openable/closable assistant panel available on every authenticated app page, rendered inside the shared app layout. The existing `/:tenant_slug/app/ai` page stays as a full-page option.
- **Non-obstructive**: the panel is fixed-size and floats over the page; the page underneath stays fully usable. The model call runs off the page LiveView process so the page stays responsive while a reply is generated.
- **Token streaming**: responses stream token-by-token to the widget, rendered progressively as markdown, instead of a single completed message.
- **Server-side page context**: the assistant receives the current path, query params, and any form/changeset present in the host page assigns, without relying on client-side reporting. Form detection is dynamic (any changeset/form in assigns) rather than a hardcoded key.
- **Session-scoped conversation**: a random chat session token is minted in the server session; the current conversation is the most recent one for `(tenant, user, session token)`, created lazily on first message. A new login rotates the token, so the chat starts fresh. Refresh and page changes keep the same token, so the conversation is preserved.
- **No deletion**: reset starts a newer conversation within the same session; prior conversations are never deleted or status-mutated.
- **Open/closed persistence**: the widget's open state is remembered across page changes and refresh (small client-side hook).

## Capabilities

### New Capabilities
- `ai-chat-widget`: floating assistant panel available across authenticated app pages, with open/close persistence, non-blocking page use, token streaming, markdown rendering, and session-scoped conversation continuity.

### Modified Capabilities
- `ai-assistant`: response streaming replaces the single complete-response requirement; page context now includes path/params and dynamically detected forms on any page; conversation resolution becomes session-token scoped and never deletes or resets implicitly; per-item confirmation and rate limiting are unchanged.

## Impact

- **Deps**: none new. Uses `ReqLLM.StreamResponse.process_stream/2` already available via `req_llm ~> 1.22`.
- **Migrations**: `mix ecto.gen.migration add_session_token_to_ai_conversations` adds `ai_conversations.session_token` (string, nullable for existing rows). No deletes, no renames.
- **Modules**: `lib/treby_web/components/layouts.ex` (mount widget), new widget LiveComponent under `lib/treby_web/components/` or `lib/treby_web/live/`, new shared `on_mount` hook (path/params + AI PubSub relay), `lib/treby_web/live/ai_chat_live.ex` (reuse the widget or keep page), `lib/treby/ai/agent.ex` (streaming), `lib/treby/ai/conversations.ex` (session-token resolution, no delete), `lib/treby/ai/context.ex` (dynamic form discovery, path/params), `lib/treby_web/plugs/auth.ex` (mint session token), `lib/treby_web/controllers/session_controller.ex` (rotate token on login), `assets/js` (open/close persistence hook).
- **Breaking**: none for existing data; `ai_conversations.status` is no longer used for deletion by the chat flow.
- **Out of scope**: applying form proposals to a live form; multi-agent/Jido; conversation history browser; bulk confirm-all; retention pruning.
