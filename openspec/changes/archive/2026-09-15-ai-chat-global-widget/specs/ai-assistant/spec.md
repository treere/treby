## MODIFIED Requirements

### Requirement: Server-built context awareness

The system SHALL build AI context server-side from `socket.assigns` (user, tenant, membership role, live view module, URL, query params, filtered assigns snapshot, permissions, and any form present on the page) and SHALL NOT trust context fields from the client. The client sends only the message text via the `send_message` event. Current path and query params SHALL be populated on every authenticated app page. Form context SHALL be detected dynamically from any changeset or form present in assigns, not from a hardcoded key.

#### Scenario: Context derived from socket
- **WHEN** the user sends a message from any app page in tenant `acme`
- **THEN** the agent receives `tenant_id` from `socket.assigns.current_tenant.id` and `user_id` from `current_user.id`

#### Scenario: Client cannot spoof tenant
- **WHEN** a client payload contains `tenant_id` for another tenant
- **THEN** the server ignores it and uses the socket tenant

#### Scenario: Path and query params available on every page
- **WHEN** the user is on any authenticated app page, including one with query params
- **THEN** `Context.build` includes the current path and query params in the agent context

#### Scenario: Form discovered dynamically
- **WHEN** the current page exposes a changeset or form in its assigns
- **THEN** `Context.build` includes that form's field schema in the agent context

### Requirement: Per-user history shared across tabs

The system SHALL persist conversations per `(tenant_id, user_id, session_token)` and broadcast each update once via PubSub topic `ai:{tenant_id}:{user_id}` so all tabs of the same login stay in sync. History SHALL be scoped by `tenant_id`. No `:stream` topic SHALL exist.

#### Scenario: History visible across tabs
- **WHEN** a user sends a message in tab A and the assistant updates
- **THEN** tab B for the same user, tenant and login session shows the messages without reload

#### Scenario: History isolated by tenant
- **WHEN** a user belongs to tenants `acme` and `beta` and chats in `acme`
- **THEN** history for `beta` is not visible in `acme`

### Requirement: Single current chat and reset

The system SHALL persist history in `ai_conversations`/`ai_messages` in the DB (never `localStorage`). The current conversation SHALL be the most recent conversation for the session token held in the server session, and SHALL be created lazily on the first message of a session. A new login SHALL rotate the session token so the chat starts fresh. The system SHALL NEVER delete or status-mutate prior conversations. Reset SHALL start a newer conversation within the same session.

#### Scenario: Content restored on mount
- **WHEN** the widget or page mounts with messages in the session conversation
- **THEN** it loads them via `Treby.AI.Conversations` and renders them — content is never lost and no new conversation is created when one exists

#### Scenario: Both user and assistant messages are stored
- **WHEN** the user sends a message via the `send_message` event
- **THEN** both the user message and the assistant reply are persisted in `ai_messages`

#### Scenario: New login starts a fresh conversation
- **WHEN** a user logs in and sends the first message
- **THEN** a new conversation is created for the rotated session token and previous conversations are left untouched

#### Scenario: Reset creates a new conversation without deleting
- **WHEN** the user confirms Reset
- **THEN** the system creates a newer conversation for the same session token and leaves all previous conversations intact

## REMOVED Requirements

### Requirement: Sync response and rate limiting

**Reason**: Token streaming replaces the single complete-response behavior.
**Migration**: Replaced by the ADDED requirement "Streaming response and rate limiting"; rate limiting is unchanged.

## ADDED Requirements

### Requirement: Streaming response and rate limiting

The system SHALL stream assistant responses token-by-token to the client and SHALL rate-limit AI messages per user. The model call SHALL run off the page LiveView process so the host page stays responsive. Partial content SHALL be broadcast over `ai:{tenant_id}:{user_id}`; the completed reply SHALL be persisted as a single `role: "assistant"` message with full markdown content and broadcast once. No `:stream` topic SHALL exist.

#### Scenario: Tokens streamed
- **WHEN** the model produces a reply
- **THEN** partial content is broadcast and rendered before the reply completes

#### Scenario: Complete response persisted
- **WHEN** streaming completes
- **THEN** a single message is persisted as `role: "assistant"` with the full markdown content and broadcast once via PubSub `ai:{tenant_id}:{user_id}`

#### Scenario: Markdown rendering
- **WHEN** the assistant replies
- **THEN** the content is rendered as markdown (via `TrebyWeb.Markdown`)

#### Scenario: Page stays responsive
- **WHEN** a reply is being generated
- **THEN** the host page continues to handle user interactions

#### Scenario: Rate limited
- **WHEN** the user exceeds the configured AI message rate
- **THEN** the system returns a localized rate-limit error and does not call the provider

### Requirement: Apply form proposals to live form

When the assistant proposes corrected or pre-filled form values for the form in context and the user confirms the `propose_form_fill` tool run, the system SHALL apply those values to the live form on the host page server-side, updating the form's changeset and pushing the applied values to the client. Application SHALL be scoped to the form currently in context and SHALL NOT affect other forms or data.

#### Scenario: Form values applied on confirm
- **WHEN** the user confirms a `propose_form_fill` suggestion for the form in context
- **THEN** the host page form is updated with the proposed values and the change is reflected in the DOM

#### Scenario: Application scoped to context form
- **WHEN** no form is present in the current page assigns
- **THEN** the form proposal is still returned but no host form is updated
