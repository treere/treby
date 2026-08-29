## Why

Conversations between recruiters and candidates are not realtime. When a new message arrives — in the candidate portal chat, the candidate profile's conversation view, or the portal inbox — the other party must manually reload the page to see it. This breaks the expectation of a chat experience and slows down time-sensitive hiring communication.

## What Changes

- Add Phoenix PubSub broadcasting to `Treby.CandidatePortal` so every message/conversation event is pushed to subscribed LiveViews without a page reload.
- Subscribe and live-update the following views:
  - `CandidatePortalLive.MessageThread` (portal thread chat) — new messages appear instantly.
  - `CandidatePortalLive.Messages` (portal inbox) — conversation previews and last-message order refresh.
  - `CandidatePortalLive.Index` (portal dashboard conversation list) — refreshes on new activity.
  - `CandidatesLive.Show` (admin candidate profile conversations) — new candidate messages appear instantly for the recruiter.
- All existing message paths (manual send, templates, scheduled/bulk messages, status updates, rejection/info requests, system messages) flow through the same broadcast, so they all become realtime.

## Capabilities

### New Capabilities

### Modified Capabilities
- `candidate-conversations`: add realtime delivery requirement — messages and conversation state changes propagate to open views via PubSub without reload.

## Impact

- `lib/treby/candidate_portal/candidate_portal.ex` — PubSub broadcast helpers + subscribe functions; broadcast after message/conversation mutations.
- `lib/treby_web/live/candidate_portal_live/message_thread.ex` — subscribe + `handle_info` reload.
- `lib/treby_web/live/candidate_portal_live/messages.ex` — subscribe + `handle_info` reload.
- `lib/treby_web/live/candidate_portal_live/index.ex` — subscribe + `handle_info` reload.
- `lib/treby_web/live/candidates_live/show.ex` — subscribe per conversation + `handle_info` reload.
- Tests for realtime propagation in portal and admin views.
- Relies on existing `Treby.PubSub` (already configured); no new dependencies.