## Context

Treby is a multi-tenant ATS where candidates apply via public career pages and hiring teams manage them through pipeline stages. Today, communication happens via email (bidirectional email threads) and internal notes. The platform is a database, not a communication hub.

Current state:
- Candidates apply via `CareersLive.Apply`, get a confirmation email, and disappear from view
- Recruiters manage candidates through the Kanban pipeline, add notes, send emails
- Email threads (`EmailThread` + `EmailMessage`) track email-based communication
- Notifications are full-content emails sent via Swoosh
- Candidate notification preferences are tenant-level only (`tenant.settings["notifications"]`)

The change introduces a candidate-facing portal with in-platform messaging, making the platform the primary communication channel.

## Goals / Non-Goals

**Goals:**
- Candidates can access a portal via magic link to see their applications and communicate with recruiters
- Recruiters can send/receive messages to candidates within the platform
- Rejections are structured (reason + optional feedback) and visible to candidates
- Information requests use templates (portfolio, references, etc.)
- Email notifications become short "pings" linking to portal messages
- Candidates can configure their notification preferences

**Non-Goals:**
- AI-powered screening or fit scoring (planned for later)
- Real-time chat / instant messaging (async messaging is sufficient)
- Video interview integration (Google Meet links already work via scheduling)
- Candidate-to-candidate features
- Mobile app (responsive web is sufficient)
- Migration of existing email threads to conversations (they remain as-is)

## Decisions

### D1: Magic link authentication (not password, not OAuth)

**Decision**: Candidates authenticate via email-based magic link.

**Why**: 
- Candidates are external users — requiring them to create and remember a password adds friction
- OAuth (Google) adds dependency and not all candidates use Google
- Magic link is the simplest flow: enter email → receive link → click → authenticated
- Consistent with how booking links already work in `SchedulingLive.Booking`

**Implementation**:
- `candidate_tokens` table: `token` (random 32 bytes, stored as hex), `candidate_id`, `expires_at` (15 min), `used_at`
- On request: generate token, hash with SHA-256 for storage, send email with raw token in URL
- On click: hash the token from URL, look up by hash + tenant, validate expiry + unused, create session cookie
- Session duration: 24 hours (stored in signed cookie, like user sessions)
- Route: `GET /:tenant_slug/c/:token` → controller validates and redirects to portal

**Alternative considered**: Password-based auth — rejected because candidates are ephemeral users who may apply once and never return. Password reset flow adds unnecessary complexity.

### D2: Separate conversation system (not extending email threads)

**Decision**: Create a new `conversations` + `messages` system alongside existing email threads.

**Why**:
- Email threads are tightly coupled to email delivery (Swoosh, webhooks, scheduled emails)
- In-platform messages have different semantics: sender is a candidate or recruiter (not an email address), no subject line needed per message, structured message types
- Keeping them separate avoids breaking existing email functionality
- Email threads remain as fallback for candidates who don't use the portal

**Implementation**:
- `conversations` table: links to `candidate_id` + `application_id` + `tenant_id`, has `context` (general/info_request/rejection/interview/offer), `status` (open/waiting_candidate/closed)
- `messages` table: `sender_type` (recruiter/candidate/system), `sender_id` (UUID or null for system), `body` (text), `message_type` (text/request_info/rejection/status_update/interview_invite/offer), `metadata` (JSONB for structured data like rejection reason)
- System messages are auto-generated on events (stage change, application created)
- Recruiter view: conversations appear in `CandidatesLive.Show` under a new tab
- Candidate view: dedicated portal pages

### D3: Notification emails as pings (not full content)

**Decision**: Notification emails become short messages with a link to the portal, not standalone content.

**Why**:
- Full-content emails are not interactive and not tracible
- Pings drive candidates to the platform where they can respond
- Reduces email size and complexity
- Candidates who don't use the portal still get basic info in the email

**Implementation**:
- New email template types: `new_message`, `status_change`, `info_request`, `interview_update`, `offer`
- Each template: 2-3 line summary + prominent "View in Portal" button linking to `/portal/messages/:conversation_id`
- Existing `stage_email_templates` remain for backward compatibility but default behavior changes to ping mode
- Candidate notification preferences control which pings are sent (default: all enabled, `important_only` disables new_message pings)

### D4: Candidate notification preferences stored as JSONB on candidate

**Decision**: Store per-candidate notification preferences as a JSONB field on the `candidates` table.

**Why**:
- Consistent with how `custom_fields` and `tenant.settings` work in the codebase
- Avoids an extra table and joins for a small, fixed set of preferences
- Easy to read/write with Ecto changesets

**Implementation**:
- Add `notification_preferences` JSONB field to `candidates` schema
- Default: `%{"new_message" => true, "status_change" => true, "interview_update" => true, "important_only" => false}`
- Merge with defaults at read time (same pattern as `Notifications.notification_preferences/1`)
- Settings UI in candidate portal: simple toggle switches

### D5: Conversations created at key lifecycle moments

**Decision**: Conversations are created automatically at specific points, not manually by recruiters.

**Why**:
- Ensures every application has a communication channel from the start
- Reduces recruiter setup work
- System messages provide automatic status updates

**Creation points**:
1. **Application submitted** → conversation with context "general", system message "Application received"
2. **Stage change** → system message in existing conversation (or new if none exists)
3. **Recruiter sends first message** → creates conversation if needed
4. **Rejection** → creates conversation with context "rejection", structured rejection message
5. **Info request** → creates conversation with context "info_request"

### D6: Recruiter sees conversations in candidate profile (not separate page)

**Decision**: Add a "Conversations" tab to the existing `CandidatesLive.Show` page rather than creating a separate recruiter messaging page.

**Why**:
- Recruiters need context (anagrafica, applications, notes, scorecards) while messaging
- A separate page would require navigating back and forth
- Consistent with how email threads are already shown on the candidate profile
- Reduces new route/page surface area

**Implementation**:
- New tab in `CandidatesLive.Show`: "Conversations" (with unread count badge)
- List of conversations with status, last message preview, timestamp
- Click to expand conversation thread inline (like email threads currently work)
- Reply form at bottom of each conversation
- Quick action buttons: "Message", "Request Info", "Reject" — each opens the appropriate form

### D7: Rejection reasons are structured with optional free text

**Decision**: Rejection requires selecting a reason from a dropdown, with optional personalized feedback text.

**Why**:
- Structured reasons enable analytics (why are candidates rejected?)
- Optional feedback provides human touch when recruiters want to give it
- Dropdown ensures consistency across the team

**Reason options**:
- `experience_insufficient` — "Esperienza non sufficiente"
- `skills_mismatch` — "Competenze non in linea"
- `position_closed` — "Posizione chiusa"
- `other_selected` — "Altro candidato selezionato"
- `other` — "Altro" (requires free text)

**Implementation**:
- Stored in `messages.metadata` as `%{"rejection_reason" => "skills_mismatch", "feedback" => "..."}`
- Also stored in `applications.rejection_reason` (existing field) for backward compatibility
- Candidate sees: reason label + feedback text (if provided) + can respond in conversation

### D8: Session management for candidates

**Decision**: Candidate sessions use signed cookies (like user sessions) with 24-hour expiry.

**Why**:
- No server-side session store needed (consistent with existing Phoenix session approach)
- 24 hours is reasonable — candidates check periodically, not continuously
- If session expires, they request a new magic link (same flow)

**Implementation**:
- On magic link validation: `put_session(conn, :candidate_id, candidate.id)` and `put_session(conn, :candidate_tenant_id, tenant.id)`
- A plug (`TrebyWeb.Plugs.CandidateAuth`) checks for valid candidate session on portal routes
- If no session: redirect to magic link request page
- Session cookie signed with Phoenix session secret

## Risks / Trade-offs

- **[Risk] Candidates never use the portal** → Mitigation: emails still contain basic info (not just pings) during transition. Portal adds value (status visibility, structured responses) that email doesn't have.
- **[Risk] Magic link emails go to spam** → Mitigation: use recognizable sender name, clear subject lines, ensure SPF/DKIM are configured.
- **[Risk] Conversation system diverges from email threads** → Mitigation: both systems coexist. Email threads remain for backward compatibility. Future: could migrate email threads to conversations.
- **[Trade-off] No real-time push notifications** → Candidates must check the portal or rely on email pings. Acceptable for async hiring communication.
- **[Trade-off] No file attachments in messages** → Initial version is text-only. Candidates can share links (portfolio, etc.). File upload can be added later.
- **[Trade-off] Single conversation per application** → If a conversation gets long, it stays as one thread. Could add conversation splitting later if needed.

## Migration Plan

1. Add `candidate_tokens`, `conversations`, `messages` tables via migration
2. Add `notification_preferences` JSONB field to `candidates` table
3. Deploy new code (portal routes are new, no breaking changes)
4. Update notification emails to ping format (can be toggled per tenant via existing notification preferences)
5. No data migration needed — existing email threads remain as-is

## Open Questions

- Should the candidate portal have a separate layout (simpler, candidate-branded) or reuse the app layout?
- How to handle tenants that don't want the candidate portal? (opt-out via settings?)
- Should system messages (stage changes) appear in the same conversation as recruiter messages, or in a separate "activity" view?
