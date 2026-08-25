# Interview Scheduling

Let candidates self-schedule interviews, integrated with Google Calendar. Supports both single-interviewer and multi-examiner events.

## How it works

1. A team member sends a scheduling link to a candidate — either by emailing the candidate's booking link or from the candidate profile via **Schedule Interview**
2. The candidate picks an available time slot
3. A Google Calendar event is created with a Google Meet link
4. All examiners and the candidate receive email confirmations

## Sending a booking link

- From an application's **Schedule Interview** page, click **Email Booking Link** to send the candidate a link they can use to pick their own slot
- Manual bookings from the platform also email the candidate and examiners a confirmation

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

## Interviews Dashboard

The interviews dashboard shows all upcoming interviews with:

- All examiner names for multi-examiner events
- Scorecard completion status (e.g., "2/3 scorecards")
- Filter by specific examiner
- Direct links to Google Meet and candidate profiles

## Configuration

Connect your Google Calendar in Settings to enable interview scheduling. The integration uses OAuth 2.0 with encrypted token storage. Assign examiners to interview-type stages in **Settings → Pipeline Stages** to enable multi-examiner scheduling.
