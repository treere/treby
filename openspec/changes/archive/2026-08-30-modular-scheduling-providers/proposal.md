# Proposal: Modular Calendar & Meeting Providers

## Why

Google Calendar is hard-coupled into the interview scheduling flow: the internal scheduler only lists users connected to Google, booking fails entirely when an examiner isn't connected, and interviews already scheduled on Treby are never treated as conflicts. This blocks teams that don't use Google, and the current design can double-book an examiner because Treby's own `interview_events` are not part of the busy computation. Decoupling calendar and meeting providers makes Google optional, adds an always-active internal calendar that prevents double-booking, adds Jitsi as a meeting fallback, and opens the door to future integrations (Outlook, Zoom, etc.).

## What Changes

- Introduce `CalendarProvider` and `MeetingProvider` behaviours with a resolver, so future integrations plug in as new provider modules.
- Make Treby's **internal calendar** an always-active calendar provider: its busy periods come from already-scheduled `interview_events`. This prevents fixing a second interview at a time where one already exists, with or without external calendars.
- Aggregate busy periods from **all connected calendar providers in parallel** (internal always + every external connection). Slot availability = availability rules minus the union of all busy periods.
- **Fail-closed** on provider errors: if a connected provider returns an error, slot computation blocks instead of silently ignoring the conflict. Behavior is consistent across single- and multi-examiner paths.
- Add **Jitsi** as meeting fallback (`https://meet.jit.si/treby-<tenant-slug>-<uuid>`). When Google is connected, booking creates a single Google Calendar event (with a Meet link) whose attendees are **all examiners + the candidate**; otherwise only a Jitsi URL is generated (no external event).
- Fix **cancel**: delete the calendar event using the **calendar owner's** token, not the scheduler's (`scheduled_by_id`), which is wrong today when a different user creates the event.
- **BREAKING** schema migration:
  - `interview_events.google_event_id` → `provider_event_id`, plus `calendar_provider` and `calendar_owner_id`
  - `calendar_connections.google_email` → `provider_email`
  - allow **multiple connections per user** (unique per `provider` instead of per user) to support several providers in parallel
- Internal scheduler (`/app/schedule/:application_id`) lists examiners with **availability rules** (not only Google-connected users) and shows a connection badge.
- Replace the ETS `SlotCache` (which caches final slots) with a **distributed in-cluster ETS cache** (single `:global` owner with failover) that caches **external provider responses** only, so internal busy is always read fresh from the DB and no invalidation is needed.
- De-Google user-facing copy: "Join Google Meet" and "Video (Google Meet)" become provider-agnostic.

## Capabilities

### New Capabilities
- `calendar-providers`: provider abstraction (behaviour + resolver), connection model supporting multiple active providers per user, multi-provider busy aggregation, and the distributed provider-response cache.
- `meeting-providers`: meeting link generation and resolution (Google Meet when a required examiner is connected, Jitsi otherwise), with a single meeting link per interview.

### Modified Capabilities
- `google-calendar-integration`: Google becomes one calendar provider among several; connection model supports multiple providers per user; `google_email` becomes `provider_email`; event creation becomes a single event whose attendees are all examiners plus the candidate.
- `interview-scheduling`: slot computation includes the internal calendar (existing Treby interviews) and aggregates all connected providers; provider errors block; meeting links are provider-agnostic; cancellation uses the calendar owner's token; a single event is created with all examiners as attendees.
- `candidate-self-scheduling`: booking creates a single event with all examiners as attendees and a provider-agnostic meeting link; the confirmation page shows the dynamic link.

## Impact

- `lib/treby/calendar/` — new `CalendarProvider`/`MeetingProvider` behaviours, provider modules (`Google`, `Jitsi`, `Treby`), resolver in `Treby.Calendar`, distributed cache
- `lib/treby/availability/` — busy aggregation from internal + all connected providers; fail-closed error handling; cache granularity change
- `lib/treby/interviews/` — `schedule_interview` (single event, all examiners), `cancel_interview` (owner token)
- `lib/treby_web/live/settings_live/calendar.ex` — multi-provider connection UI
- `lib/treby_web/live/schedule_live/index.ex` — examiner picker by availability rules + connection badge
- `lib/treby_web/live/candidate_portal_live/schedule.ex` — provider-agnostic meeting flow and confirmation
- Migrations: `calendar_connections`, `interview_events`
- Tests: `calendar_test.exs`, availability, interview scheduling, candidate self-scheduling