# AI Assistant

## Purpose

Provide a team-internal chat page with a single ReqLLM-powered agent that manages jobs, explains the platform, and co-uses forms. Per-user history, per-item confirmation, sync replies, zero JS.

## ADDED Requirements

### Requirement: Internal team chat page

The system SHALL provide an AI chat page at `/:tenant_slug/app/ai` for authenticated team members. Candidate portal SHALL NOT expose the assistant.

#### Scenario: Page available in app
- **WHEN** an authenticated user with a valid membership visits `/:tenant_slug/app/ai`
- **THEN** the chat page renders with the current conversation

#### Scenario: Portal has no assistant
- **WHEN** a candidate accesses `/:tenant_slug/portal/*`
- **THEN** no AI chat UI is rendered

### Requirement: Server-built context awareness

The system SHALL build AI context server-side from `socket.assigns` (user, tenant, membership role, live view module, URL, params, filtered assigns snapshot, permissions) and SHALL NOT trust context fields from the client. The client sends only the message text via the `send_message` LiveView event.

#### Scenario: Context derived from socket
- **WHEN** the user sends a message from the AI page in tenant `acme`
- **THEN** the agent receives `tenant_id` from `socket.assigns.current_tenant.id` and `user_id` from `current_user.id`

#### Scenario: Client cannot spoof tenant
- **WHEN** a client payload contains `tenant_id` for another tenant
- **THEN** the server ignores it and uses the socket tenant

### Requirement: Per-user history shared across tabs

The system SHALL persist conversations per `(tenant_id, user_id)` and broadcast each completed message once via PubSub topic `ai:{tenant_id}:{user_id}` so all tabs stay in sync. History SHALL be scoped by `tenant_id`. No `:stream` topic SHALL exist.

#### Scenario: History visible across tabs
- **WHEN** a user sends a message in tab A and the assistant reply completes
- **THEN** tab B for the same user and tenant shows both messages without reload

#### Scenario: History isolated by tenant
- **WHEN** a user belongs to tenants `acme` and `beta` and chats in `acme`
- **THEN** history for `beta` is not visible in `acme`

### Requirement: Single current chat and reset

The system SHALL persist history in `ai_conversations`/`ai_messages` in the DB (never `localStorage`). LiveView mount SHALL load the session-pinned conversation and SHALL NEVER create or reset it implicitly — only the Reset button starts a new conversation. No retention pruning in v1.

#### Scenario: Content restored on mount
- **WHEN** the page mounts with messages in the session-pinned conversation
- **THEN** LiveView loads them via `Treby.AI.Conversations` and renders them — content is never lost and no new conversation is created

#### Scenario: Both user and assistant messages are stored
- **WHEN** the user sends a message via the `send_message` event
- **THEN** both the user message and the completed assistant reply are persisted in `ai_messages`

#### Scenario: Reset creates new conversation
- **WHEN** the user confirms Reset
- **THEN** the system creates a new `active` `ai_conversations` row for that `(tenant_id, user_id)` and pins it in the session, without deleting prior `ai_messages`

### Requirement: Job management with per-item confirmation

The system SHALL offer `list_jobs` (read, immediate) and `create_job`, `update_job`, `delete_job` (destructive, per-item confirmation). Each pending run is stored as `ai_tool_runs` with `status: :pending_confirm` and rendered as its own card with diff. No bulk accept-all in v1.

#### Scenario: List executes immediately
- **WHEN** the assistant calls `list_jobs`
- **THEN** the tool runs without confirmation and the result is returned

#### Scenario: Job delete requires its own confirmation
- **WHEN** the assistant calls `delete_job`
- **THEN** the system does not execute it, creates a pending run, and shows a confirmation card requiring its own Confirm click

#### Scenario: User confirms
- **WHEN** the user clicks Confirm on the pending card
- **THEN** the system executes the tool with `tenant_id` from socket and `user` from socket, and logs an audit event

#### Scenario: User rejects
- **WHEN** the user clicks Cancel
- **THEN** the pending run is marked rejected and no mutation occurs

### Requirement: Platform help

The system SHALL offer `explain_page`, which explains the current page and guides the user through the steps to accomplish their goal. It is read-only and executes immediately.

#### Scenario: Help request
- **WHEN** the user asks how to do something on the platform
- **THEN** the assistant explains the current page and guides the steps using the context snapshot

### Requirement: Sync response and rate limiting

The system SHALL return complete LLM responses in a single message (no token streaming) and SHALL rate-limit AI messages per user/tenant.

#### Scenario: Complete response
- **WHEN** the LLM responds
- **THEN** a single message is persisted as `role: "assistant"` with full markdown content and broadcast once via PubSub `ai:{tenant_id}:{user_id}`
- **AND** no `:stream` topic exists

#### Scenario: Markdown rendering
- **WHEN** the assistant replies
- **THEN** the content is rendered as markdown (via `TrebyWeb.Markdown`)

#### Scenario: Rate limited
- **WHEN** the user exceeds the configured AI message rate
- **THEN** the system returns a localized rate-limit error and does not call the provider

### Requirement: Form co-use

While the user works in a LiveView form, the system SHALL expose its schema via `Treby.AI.Context` and allow the assistant to fix texts and pre-fill fields for them via `propose_form_fill`. Proposals SHALL be shown as a diff preview and SHALL apply only on per-item confirmation.

#### Scenario: Form present in context
- **WHEN** the current page has a form
- **THEN** `Context.build` includes `form_schema` derived from the changeset

#### Scenario: Fix texts in current form
- **WHEN** the user asks to fix or improve the texts they are writing
- **THEN** the assistant proposes corrected field values as a diff preview and applies them only on confirmation
