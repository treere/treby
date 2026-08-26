## 1. Database Migrations

- [x] 1.1 Create `candidate_tokens` table migration (id, candidate_id, tenant_id, token, used_at, expires_at, inserted_at)
- [x] 1.2 Create `conversations` table migration (id, candidate_id, application_id, tenant_id, subject, context, status, last_message_at, inserted_at)
- [x] 1.3 Create `messages` table migration (id, conversation_id, sender_type, sender_id, body, message_type, metadata, inserted_at)
- [x] 1.4 Add `notification_preferences` JSONB field to `candidates` table migration

## 2. Candidate Context Module

- [x] 2.1 Create `Treby.CandidatePortal` context module with token generation and validation functions
- [x] 2.2 Implement `generate_magic_link_token/2` (create token, hash for storage, return raw token for URL)
- [x] 2.3 Implement `validate_magic_link_token/2` (verify hash, check expiry, check used_at, mark as used)
- [x] 2.4 Implement `create_session_from_token/2` (load candidate + tenant, return session data)
- [x] 2.5 Add `get_notification_preferences/1` and `set_notification_preference/3` for candidates

## 3. Conversation & Message Context

- [x] 3.1 Implement `create_conversation/1` (create conversation with context, status, and optional system message)
- [x] 3.2 Implement `send_message/1` (create message, update conversation last_message_at, update status)
- [x] 3.3 Implement `list_conversations_for_candidate/2` (by candidate + tenant, with preloaded last message)
- [x] 3.4 Implement `list_conversations_for_application/2` (by application + tenant)
- [x] 3.5 Implement `get_conversation!/2` with preloaded messages in chronological order
- [x] 3.6 Implement `close_conversation/2` (set status to "closed")
- [x] 3.7 Add system message helpers: `create_status_update_message/3`, `create_rejection_message/3`, `create_info_request_message/3`

## 4. Magic Link Authentication

- [x] 4.1 Create `TrebyWeb.Plugs.CandidateAuth` plug (validate session, load candidate + tenant, redirect to portal if invalid)
- [x] 4.2 Create `TrebyWeb.MagicLinkController` with `new/2` (show email form) and `create/2` (send magic link email)
- [x] 4.3 Create `TrebyWeb.MagicLinkController` `show/2` (validate token, create session, redirect to portal)
- [x] 4.4 Create magic link email builder in `Treby.Notifications.Email.magic_link_email/2`
- [x] 4.5 Add routes: `GET /:tenant_slug/portal` (request form), `POST /:tenant_slug/portal` (send link), `GET /:tenant_slug/c/:token` (validate)

## 5. Candidate Portal UI

- [x] 5.1 Create candidate portal layout template (simplified, tenant-branded, with header nav)
- [x] 5.2 Create `CandidatePortalLive.Index` — dashboard showing applications list with stage badges and unread indicators
- [x] 5.3 Create `CandidatePortalLive.Index` — application detail view with status and timeline
- [x] 5.4 Create `CandidatePortalLive.Messages` — conversation list for the candidate
- [x] 5.5 Create `CandidatePortalLive.MessageThread` — full conversation view with messages and reply form
- [x] 5.6 Create `CandidatePortalLive.Settings` — notification preference toggles
- [x] 5.7 Add portal routes under `/:tenant_slug/portal/*` with `CandidateAuth` plug

## 6. Recruiter Conversation UI

- [x] 6.1 Add "Conversations" tab to `CandidatesLive.Show` with open conversation count badge
- [x] 6.2 Implement conversation list in the tab (job title, context, status, last message preview, timestamp)
- [x] 6.3 Implement inline conversation thread expansion with message history
- [x] 6.4 Implement recruiter reply form at bottom of conversation thread
- [x] 6.5 Add quick action buttons: "New Message", "Request Info", "Reject"
- [x] 6.6 Implement "Request Info" form with template selector (portfolio, references, availability, certificates, custom)
- [x] 6.7 Implement "Reject" form with reason dropdown and optional feedback text

## 7. Application Submission Integration

- [x] 7.1 Update `CareersLive.Apply` to create a welcome conversation on submission
- [x] 7.2 Update thank-you page to show portal access link when portal is enabled
- [x] 7.3 Update `Notifications.notify_new_application_candidate/1` to send portal access email instead of full confirmation
- [x] 7.4 Add notification template for new application with portal link

## 8. Notification Changes

- [x] 8.1 Create notification email templates: new_message, status_change, info_request, interview_update, offer (short ping format with portal link)
- [x] 8.2 Update `Notifications.notify_stage_change/2` to create system message in conversation and send ping email
- [x] 8.3 Update email template preview in settings to show both full and ping formats
- [x] 8.4 Add candidate notification preference check to notification dispatch functions

## 9. Rejection Flow Integration

- [x] 9.1 When recruiter rejects via conversation, update `applications.rejection_reason` field
- [x] 9.2 Move application to Rejected stage on rejection message
- [x] 9.3 Create rejection system message in conversation with structured reason
- [x] 9.4 Send rejection notification email (ping format) to candidate

## 10. Testing

- [x] 10.1 Write tests for magic link token generation, validation, expiry, and single-use
- [x] 10.2 Write tests for conversation creation, message sending, status updates
- [x] 10.3 Write tests for candidate portal dashboard (applications list, unread indicators)
- [x] 10.4 Write tests for candidate message sending and reply
- [x] 10.5 Write tests for recruiter conversation view and quick actions
- [x] 10.6 Write tests for rejection flow (structured reason, stage move, notification)
- [x] 10.7 Write tests for candidate notification preferences filtering
- [x] 10.8 Run `mix precommit` and fix any issues
