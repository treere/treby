# AI Assistant

## Purpose

Provide a team-internal chat assistant that is aware of user, tenant, and current page, with per-user history shared across tabs, capable of answering and acting via the unified action layer. LiveView-only UI, sync replies, no token streaming.

## ADDED Requirements

### Requirement: Internal team chat

The system SHALL provide an AI chat drawer available in all `/:tenant_slug/app` pages for authenticated team members. Candidate portal SHALL NOT expose the assistant.

#### Scenario: Drawer available in app
- **WHEN** an authenticated user with a valid membership visits any `/:tenant_slug/app` page
- **THEN** a chat entry point is visible and opening it shows the conversation

#### Scenario: Portal has no assistant
- **WHEN** a candidate accesses `/:tenant_slug/portal/*`
- **THEN** no AI chat UI is rendered

### Requirement: Server-built context awareness

The system SHALL build AI context server-side from `socket.assigns` (user, tenant, membership role, live view module, URL, params, filtered assigns snapshot, permissions) and SHALL NOT trust context fields from the client. The client sends only the message text via the `send_message` LiveView event.

#### Scenario: Context derived from socket
- **WHEN** the user sends a message from `CandidatesLive.Show` for candidate `123` in tenant `acme`
- **THEN** the agent receives `tenant_id` from `socket.assigns.current_tenant.id`, `user_id` from `current_user.id`, and `page: %{live_view: "CandidatesLive.Show", params: %{"id" => "123"}}`

#### Scenario: Client cannot spoof tenant
- **WHEN** a client payload contains `tenant_id` for another tenant
- **THEN** the server ignores it and uses the socket tenant

### Requirement: Per-user history shared across tabs

The system SHALL persist conversations per `(tenant_id, user_id)` and broadcast each completed message once via PubSub topic `ai:{tenant_id}:{user_id}` so all tabs for that user in that tenant stay in sync. History SHALL be scoped by `tenant_id`. No `:stream` topic SHALL exist.

#### Scenario: History visible across tabs
- **WHEN** a user sends a message in tab A and the assistant reply completes
- **THEN** tab B for the same user and tenant shows both messages without reload

#### Scenario: History isolated by tenant
- **WHEN** a user belongs to tenants `acme` and `beta` and chats in `acme`
- **THEN** history for `beta` is not visible in `acme`

### Requirement: Single current chat and reset

The system SHALL persist chat history per `(tenant_id, user_id)` in `ai_conversations`/`ai_messages` in the DB (never `localStorage`). LiveView mount SHALL load the session-pinned conversation and render its messages, and SHALL NEVER create or reset it implicitly — only the Reset button starts a new conversation. History SHALL be retained for 30 days and then pruned. Lifecycle operations (list/conclude/reopen/delete) SHALL be context functions with no HTTP routes.

#### Scenario: Content restored on mount
- **WHEN** the drawer mounts (page load or navigation) with messages in the session-pinned conversation
- **THEN** LiveView loads them via `Treby.AI.Conversations` and renders those messages — content is never lost and no new conversation is created

#### Scenario: Both user and assistant messages are stored
- **WHEN** the user sends a message via the `send_message` event
- **THEN** both the user message and the completed assistant reply are persisted in `ai_messages` under the conversation, so a reload renders the full exchange

#### Scenario: Open state kept across navigation and reload
- **WHEN** the drawer is open and the user changes page or reloads
- **THEN** the drawer is open again afterwards (flag `ai-drawer-open` in `localStorage` via the tiny colocated hook); a closed drawer stays closed

#### Scenario: Reset confirmation in drawer
- **WHEN** the user clicks the Reset button in the drawer
- **THEN** an in-drawer modal/bubble asks for confirmation (`Reset chat? The context will be cleared, but history is kept for 30 days.` with `Cancel` / `Reset`) and no `confirm()` dialog is used

#### Scenario: Reset creates new conversation
- **WHEN** the user confirms Reset
- **THEN** the system creates a new `active` `ai_conversations` row for that `(tenant_id, user_id)`, pins it in the session, and clears the drawer, without deleting prior `ai_messages`

#### Scenario: Retention 30 days
- **WHEN** 30 days have passed since a conversation was created
- **THEN** a background job deletes `ai_conversations`/`ai_messages`/`ai_tool_runs` older than 30 days

### Requirement: Read vs destructive with confirmation

The system SHALL execute read-only tool calls immediately and SHALL require explicit user confirmation for any destructive/write tool call. A pending confirmation is stored as `ai_tool_runs` with `status: :pending_confirm` and rendered as a confirmation card with diff.

#### Scenario: Read executes immediately
- **WHEN** the assistant calls a read tool like `list_jobs` or `explain_page`
- **THEN** the tool runs without confirmation and the result is returned

#### Scenario: Job delete requires confirmation
- **WHEN** the assistant calls `delete_job`
- **THEN** the system does not execute it, creates a pending run, and shows a confirmation card

#### Scenario: Destructive requires confirmation
- **WHEN** the assistant calls a destructive tool (any write)
- **THEN** the system does not execute it, creates a pending run, and shows a confirmation card

#### Scenario: User confirms destructive
- **WHEN** the user clicks Confirm on the pending card
- **THEN** the system executes the tool with `tenant_id` from socket and `user` from socket, and logs an audit event

#### Scenario: User rejects
- **WHEN** the user clicks Cancel
- **THEN** the pending run is marked rejected and no mutation occurs

#### Scenario: Bulk accept-all
- **WHEN** the assistant proposes several mutations together (e.g. multiple form fixes)
- **THEN** each is stored as its own pending run sharing a `batch_id`, shown as stacked cards with per-item Confirm/Reject plus Accept-all / Reject-all
- **AND** Accept-all executes them in order, stops at the first error, and reports per-item results

#### Scenario: Delete forces per-item feedback
- **WHEN** the batch contains `delete_*` operations
- **THEN** no Accept-all button is offered and each delete requires its own Confirm click

### Requirement: Sync response and rate limiting

The system SHALL return complete LLM responses in a single message (no token streaming) and SHALL rate-limit AI messages per user/tenant.

#### Scenario: Complete response
- **WHEN** the LLM responds
- **THEN** a single message is persisted as `role: "assistant"` with full markdown content and broadcast once via PubSub `ai:{tenant_id}:{user_id}`
- **AND** no `:stream` topic exists

#### Scenario: Markdown rendering
- **WHEN** the assistant replies
- **THEN** the content is rendered as markdown (via `TrebyWeb.Markdown`) in the drawer

#### Scenario: Rate limited
- **WHEN** the user exceeds the configured AI message rate
- **THEN** the system returns a localized rate-limit error and does not call the provider

### Requirement: Multi-agent routing with Jido (Job + Explain + Form)

The system SHALL use a Jido coordinator agent that routes intents to `JobAgent` (job management), `ExplainAgent` (platform help), and form co-use via `form_schema`. Each specialist SHALL own a filtered subset of tools from `Registry.for_domain/1`.

#### Scenario: Job intent routes to JobAgent
- **WHEN** the user asks to list, create, update, or delete jobs
- **THEN** the coordinator delegates to `JobAgent`
- **AND** destructive ops (e.g. delete) require confirmation before execution

#### Scenario: Help intent routes to ExplainAgent
- **WHEN** the user asks how to do something on the platform
- **THEN** the coordinator delegates to `ExplainAgent`, which explains the current page and guides the steps

#### Scenario: Adding a new domain later
- **WHEN** a new domain agent is added with its `@ai_tool` actions
- **THEN** the coordinator can route to it without changing existing agents

### Requirement: Form co-use

While the user works in a LiveView form, the system SHALL expose its schema via `Treby.AI.Context` and allow the assistant to fix texts and pre-fill fields for them. Proposals SHALL be shown as a diff preview and SHALL apply only on user confirmation.

#### Scenario: Form present in context
- **WHEN** the current page has a form (e.g., candidate creation)
- **THEN** `Context.build` includes `form_schema` derived from the changeset

#### Scenario: Form fill requires confirmation
- **WHEN** the assistant proposes form values
- **THEN** a confirmation card shows the diff and no write occurs until the user confirms

#### Scenario: Fix texts in current form
- **WHEN** the user asks to fix or improve the texts they are writing
- **THEN** the assistant proposes corrected field values as a diff preview and applies them only on confirmation

### Requirement: Drawer layout

The drawer SHALL be a fixed-height flex column where the message list is the only scrollable region and the text input stays pinned at the bottom. The only JS SHALL be a tiny colocated hook for the open-flag and scroll-to-bottom.

#### Scenario: Minimum height
- **WHEN** the drawer opens on a tall screen
- **THEN** it is at least `min(400px, calc(100vh - 10rem))` tall while never exceeding `min(480px, calc(100vh - 8rem))`

#### Scenario: Long history scrolls, input stays
- **WHEN** the conversation has more messages than fit the drawer
- **THEN** `#ai-messages` scrolls (`flex-1 min-h-0 overflow-y-auto`) while header and the input form stay fixed, and new content auto-scrolls to the bottom
