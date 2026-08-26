## Why

Communication between candidates and hiring teams is fragmented across email, platform notes, and ad-hoc channels. Candidates don't know their application status without emailing to ask. Recruiter messages get lost in inboxes. Rejections lack structure and feedback. The platform is a database, not a communication hub.

The goal is to make the platform the primary place where candidate-company communication happens, with emails serving only as notifications to bring people back. This reduces manual work for recruiters, gives candidates visibility and voice, and creates structured data for analytics.

## What Changes

- **Candidate Portal**: A public, authenticated area where candidates can see their applications, view status, read and respond to messages, and configure notification preferences
- **Magic Link Authentication**: Candidates authenticate via email link (no password) — click a link in email, land in the portal, session lasts 24-48h
- **In-Platform Messaging**: A conversation system between recruiters and candidates, tied to specific applications. Messages are structured (text, request_info, rejection, status_update, interview_invite, offer)
- **Candidate Notification Preferences**: Candidates control what emails they receive (new_message, status_change, interview_update, important_only). Default: only important notifications
- **Structured Rejection Flow**: Rejection requires a reason (dropdown: experience, skills mismatch, position closed, other selected, other) with optional personalized feedback. Candidate sees it in-platform and can respond
- **Structured Info Request**: Recruiters can request specific information (portfolio, references, availability, certificates) via templates. Candidate responds in-platform
- **Recruiter Conversation View**: Candidate profile page gains a "Conversations" tab showing all active threads with quick actions (message, request info, reject)
- **Email as Notification**: All notification emails become short pings with a link to the portal message, not standalone content. Candidates can opt out of non-important notifications

## Capabilities

### New Capabilities
- `candidate-magic-link`: Magic link authentication for candidates — token generation, email delivery, session management, token validation and expiry
- `candidate-portal-dashboard`: Public candidate-facing portal showing applications, status, and recent messages
- `candidate-conversations`: In-platform messaging between recruiters and candidates, tied to applications, with structured message types
- `candidate-notifications-config`: Per-candidate notification preferences for email delivery control

### Modified Capabilities
- `email-notifications`: Notifications change from full-content emails to short "ping" emails linking to portal messages
- `candidate-management`: Candidate profile page gains a conversations tab with messaging UI and quick actions
- `career-page`: Application submission creates a welcome conversation and sends portal access email instead of full confirmation email
- `stage-email-templates`: Templates change to notification-style emails (short, link to portal)
- `bidirectional-email`: Email threads remain as fallback but become secondary to in-platform conversations

## Impact

- **New database tables**: `candidate_tokens`, `conversations`, `messages`
- **New routes**: `/:slug/c/:token` (magic link), `/:slug/portal/*` (candidate portal)
- **Modified schemas**: `candidates` gains `notification_preferences` (JSONB)
- **Modified LiveViews**: `CandidatesLive.Show` gains conversations tab; `CareersLive.Apply` triggers conversation creation
- **New LiveViews**: `CandidatePortalLive.Index`, `CandidatePortalLive.Messages`, `CandidatePortalLive.MessageThread`, `CandidatePortalLive.Settings`
- **New context module**: `Treby.CandidatePortal` for magic link tokens, conversations, messages, candidate-side operations
- **Email changes**: `Treby.Notifications` and `Treby.Notifications.Email` updated to send short notification emails
- **No new dependencies**: Uses existing `Swoosh` for email, `Ecto` for data, `Phoenix.LiveView` for UI
