# Interview Scheduling

Let candidates self-schedule interviews with an always-active internal calendar and optional external calendar providers (Google Calendar). Supports both single-interviewer and multi-examiner events.

## How it works

1. A recruiter schedules an interview manually, or lets the candidate book from their portal
2. The candidate picks an available time slot from the portal (or the recruiter picks one)
3. A meeting link is resolved automatically: **Google Meet** when a required examiner is connected to Google Calendar, otherwise a **Jitsi** link
4. The candidate is notified in their portal (conversation message + optional ping email); examiners are notified in-app

## Availability: internal calendar + connected providers

Slot availability always starts from Treby's **internal calendar**:

- Each team member sets their weekly availability windows in **Settings → Availability**
- Interviews already scheduled on Treby are treated as busy — a second interview can't be fixed at the same time, even without any external calendar
- If a member connects an external calendar (e.g. Google), its free/busy is **intersected** with the internal windows; multiple providers can be active in parallel
- A connected provider that errors blocks slot computation rather than silently ignoring the conflict

## Self-scheduling in the portal

- Candidates with an application in an interview stage see a **Schedule** page in their portal and pick their own slot
- The recruiter's **Schedule Interview** page lists examiners who have set availability (with a connection badge) — no Google account required
- Manual bookings also post the interview details into the candidate's portal conversation

## Multi-Examiner Scheduling

For interview-type stages with multiple examiners assigned, Treby computes **overlapping availability**:

- The system combines availability rules with busy periods from the internal calendar and every connected provider for all eligible examiners
- Only slots where the minimum required number of examiners for the stage is available are shown
- Each slot displays how many examiners are available (e.g., "3 available")
- When a slot is booked, a **single** calendar event is created with **all examiners plus the candidate as attendees**, and one meeting link is stored on the interview

### Examiner Substitution

When a confirmed examiner cancels:

1. The system searches for a substitute from the eligible examiner pool
2. Filters for examiners with overlapping availability in the same time slot
3. If a substitute is found, they are notified
4. If no substitute is found, the assigned advancer is notified and can reschedule, find a manual substitute, or cancel the event

## Features

- **Self-scheduling**: candidates choose from available slots, no back-and-forth
- **Internal calendar**: set weekly windows; existing interviews always block new ones (no double-booking)
- **Optional Google Calendar**: connect it to intersect your real calendar; scheduling works without it
- **Multi-examiner support**: overlapping availability computation for groups
- **Provider modularity**: calendar providers (presence) and meeting providers (video) are pluggable — Google Meet today, Jitsi as the always-available fallback
- **Jitsi meetings**: automatic `meet.jit.si` links when no Google connection exists
- **Timezone-aware**: automatic timezone detection for candidates
- **Scorecard completion tracking**: per-examiner scorecard status (pending/completed)
- **Explicit interview completion**: mark an interview as completed (with a confirmation dialog) — completion is a prerequisite for advancing the candidate

## Interviews Dashboard

![Interviews Dashboard](/screenshots/34-interviews-dashboard.png)

The interviews dashboard shows all upcoming interviews with:

- All examiner names for multi-examiner events
- Scorecard completion status (e.g., "2/3 scorecards")
- Filter by specific examiner
- Direct links to the meeting and candidate profiles
- **Mark as completed** action on scheduled interviews
- Scorecard form inline — examiners can submit or edit their scorecard without leaving the page

## Configuration

Google Calendar is **optional** and uses OAuth 2.0 with encrypted token storage — connect it in **Settings → Calendar** to check availability against your real calendar. Everyone can set their weekly availability in **Settings → Availability**. Assign examiners to interview-type stages in **Settings → Pipeline Stages** to enable multi-examiner scheduling. Future calendar providers plug into the same provider abstraction.

![Settings — Calendar](/screenshots/35-settings-calendar.png)

![Settings — Availability](/screenshots/36-settings-availability.png)

![Schedule Interview](/screenshots/41-schedule-page.png)