# Interview Scheduling

Let candidates self-schedule interviews, integrated with Google Calendar. Supports both single-interviewer and multi-examiner events.

## How it works

1. A recruiter schedules an interview manually, or lets the candidate book from their portal
2. The candidate picks an available time slot from the portal (or the recruiter picks one)
3. A Google Calendar event is created with a Google Meet link
4. The candidate is notified in their portal (conversation message + optional ping email); examiners are notified in-app

## Self-scheduling in the portal

- Candidates with an application in an interview stage see a **Schedule** page in their portal and pick their own slot
- The recruiter's **Schedule Interview** page shows a self-scheduling hint — no public booking link or email is sent
- Manual bookings also post the interview details into the candidate's portal conversation

## Multi-Examiner Scheduling

For interview-type stages with multiple examiners assigned, Treby computes **overlapping availability**:

- The system checks Google Calendar free/busy for all eligible examiners
- Only time slots where at least `min_examiners` examiners are simultaneously available are shown
- Each slot displays how many examiners are available (e.g., "3 available")
- When a slot is booked, a single Google Calendar event is created with all available examiners linked

### Examiner Substitution

When a confirmed examiner cancels:

1. The system searches for a substitute from the eligible examiner pool
2. Filters for examiners with overlapping availability in the same time slot
3. If a substitute is found, they are notified
4. If no substitute is found, the assigned advancer is notified and can reschedule, find a manual substitute, or cancel the event

## Features

- **Self-scheduling**: candidates choose from available slots, no back-and-forth
- **Multi-examiner support**: overlapping availability computation for groups
- **Calendar sync**: events appear on examiners' Google Calendar
- **Google Meet**: automatic video conferencing links
- **Availability rules**: configure when you're available for interviews
- **Timezone-aware**: automatic timezone detection for candidates
- **Scorecard completion tracking**: per-examiner scorecard status (pending/completed)
- **Explicit interview completion**: mark an interview as completed (with a confirmation dialog) — completion is a prerequisite for advancing the candidate

## Interviews Dashboard

The interviews dashboard shows all upcoming interviews with:

- All examiner names for multi-examiner events
- Scorecard completion status (e.g., "2/3 scorecards")
- Filter by specific examiner
- Direct links to Google Meet and candidate profiles
- **Mark as completed** action on scheduled interviews
- Scorecard form inline — examiners can submit or edit their scorecard without leaving the page

## Configuration

Connect your Google Calendar in Settings to enable interview scheduling. The integration uses OAuth 2.0 with encrypted token storage. Assign examiners to interview-type stages in **Settings → Pipeline Stages** to enable multi-examiner scheduling.
