## Why

The interview scheduling flow is currently half-finished and hard to reach. The scheduling page (`ScheduleLive.Index`) exists but has **no navigation pointing to it**, so recruiters cannot open it without typing the URL manually. Candidates who apply cannot be emailed a self-booking link, and the recruiter-side manual booking page is orphaned. Separately, the standalone Pipeline landing page (`/app/pipeline`) duplicates a job list that already lives in Jobs, and pipeline cards give no way to jump into a candidate's details.

## What Changes

- Make the interview scheduling page reachable by adding a "Schedule Interview" action from the candidate detail page (per application), replacing the current dead-end route.
- Add the ability to **email a candidate a self-scheduling booking link** (generates a booking token and emails the candidate the `/:tenant_slug/schedule/:token` URL), so the candidate can book a slot themselves.
- Keep the existing **manual booking flow** (recruiter picks interviewer + slot) and ensure it **emails the candidate a confirmation** with interview details and Meet link — the email-sending already exists in `Interviews.schedule_interview/1` and is covered by tests; this change wires the page into navigation.
- **BREAKING**: Remove the standalone Pipeline landing page (`/app/pipeline` — the list of jobs) and its nav entries (desktop + mobile). Pipeline boards stay reachable only per job via `/app/pipeline/:job_id` (from Jobs).
- Make pipeline candidate cards link to the candidate detail page (`/app/candidates/:id`), so recruiters can click a card to view candidate details.

## Capabilities

### New Capabilities
- `candidate-booking-email`: Sending a candidate an email containing a self-scheduling booking link (`/:tenant_slug/schedule/:token`) so they can book an interview slot themselves.

### Modified Capabilities
- `candidate-self-scheduling`: add a requirement that the booking link can be emailed to the candidate (generation + sharing flow now includes emailing).
- `interview-scheduling`: add a scenario that the recruiter scheduling page is reachable from the candidate/application page and that scheduling sends the candidate a confirmation email.
- `pipeline`: add a requirement that candidate cards link to the candidate detail page; remove the standalone global pipeline landing page so the board is only accessible per job.
- `app-navigation`: remove the Pipeline nav link (desktop and mobile drawer); pipeline boards are reached from Jobs.

## Impact

- `lib/treby_web/router.ex` — remove `live "/pipeline", PipelineLive` (keep `live "/pipeline/:job_id", PipelineLive.Index`).
- `lib/treby_web/live/pipeline_live/pipeline_live.ex` — delete the standalone module.
- `lib/treby_web/components/layouts.ex` — remove Pipeline nav links (desktop + mobile).
- `lib/treby_web/live/pipeline_live/index.ex` — make candidate cards link to `/app/candidates/:id`.
- `lib/treby_web/live/candidates_live/show.ex` — add a "Schedule Interview" action per application linking to `/app/schedule/:application_id`.
- `lib/treby_web/live/schedule_live/index.ex` — add an "Email booking link" action next to the existing "Generate Booking Link".
- `lib/treby/scheduling_email.ex` — add a `booking_link_candidate/4` email template (with absolute URL).
- `lib/treby/interviews/interviews.ex` — add a helper that generates a booking token and returns an absolute link.
- Tests: `pipeline_live_test.exs`, `interviews_test.exs`, and a new scheduling/booking-email test.
- Docs site: regenerate screenshots and update `site/features/` pages for the booking email and pipeline navigation changes.
- No new dependencies, DB changes, or external API changes.
