## Why

Treby currently has no interview scheduling capability. Recruiters must manually coordinate availability outside the platform, leading to friction, double-bookings, and lost context. Adding native scheduling with Google Calendar integration closes the gap between "candidate in pipeline" and "interview conducted" — the most critical handoff in the hiring workflow.

## What Changes

- Add Google Calendar OAuth integration for team members to connect their calendars
- Add per-user, per-day availability rules (working hours, timezone, buffer times)
- Add interview event creation with auto-generated Google Meet video links
- Add a recruiter-facing scheduling page: pick interviewer → see available slots → book
- Add a candidate-facing public booking page for self-scheduling
- Add an interviews dashboard showing upcoming interviews
- Add encrypted storage for OAuth tokens (Cloak + Cloak.Ecto)
- Add lazy token refresh (check expiry on every API call, refresh if needed)

## Capabilities

### New Capabilities

- `google-calendar-integration`: Google OAuth connection, token storage (encrypted), lazy refresh, FreeBusy queries, event creation with Google Meet links
- `availability-rules`: Per-user, per-day availability configuration (working hours, timezone, buffer times) with CRUD interface
- `interview-scheduling`: Core scheduling engine — slot computation (availability rules minus calendar busy times), recruiter-facing scheduling flow, email notifications with Meet links, auto-advance to interview stage
- `candidate-self-scheduling`: Public booking page for candidates to pick interview slots, booking token generation, event auto-creation on slot selection

### Modified Capabilities

- `pipeline`: Interview stage now triggers scheduling prompt; applications auto-advance on interview creation
- `candidate-management`: Candidate profile shows scheduled interviews with Meet links

## Impact

- **New dependencies**: `cloak_ecto ~> 1.3.0`, `goth ~> 1.4`
- **New database tables**: `calendar_connections`, `availability_rules`, `interview_events`, `booking_tokens`
- **New routes**: `/app/settings/calendar`, `/app/schedule/:application_id`, `/app/interviews`, `/:slug/schedule/:token`
- **New config**: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `CLOAK_KEY` env vars
- **Modified files**: `router.ex` (new routes), `config.exs` / `runtime.exs` (new config), pipeline context (interview stage behavior), candidate show view (interview list)
- **External APIs**: Google Calendar API v3 (OAuth, FreeBusy, Events with conferenceData)
