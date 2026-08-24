## 1. Booking link email capability

- [x] 1.1 Add `booking_link_candidate/4` (candidate, job, tenant, link) to `lib/treby/scheduling_email.ex`, mirroring the existing email style (HTML + text body, from `{"Treby", "noreply@treby.app"}`, subject "Book your interview - <job.title>"), explaining the candidate can choose their own slot and including the absolute booking link.
- [x] 1.2 Add a helper in `lib/treby/interviews/interviews.ex` (e.g. `booking_link_url(token)` or `generate_booking_link/1`) that generates a booking token via `generate_booking_token/1` and returns the absolute URL `TrebyWeb.Endpoint.url() <> "/#{tenant.slug}/schedule/#{token.token}"`.
- [x] 1.3 Add a unit test for `SchedulingEmail.booking_link_candidate/4` (assert subject, recipient, and that the body contains the link).

## 2. Email booking link from the scheduling page

- [x] 2.1 In `lib/treby_web/live/schedule_live/index.ex`, add an "Email Booking Link" button next to the existing "Generate Booking Link" button.
- [x] 2.2 Add a `handle_event("email_booking_link", ...)` that generates the token (reusing the existing interviewer selection or without an interviewer), builds the absolute URL, delivers the email via `Treby.Mailer.deliver/1` (wrapped in try/rescue so failures surface as a flash), and sets `@booking_link` + an info flash.
- [x] 2.3 Add a LiveView test in a new/existing schedule test file covering: email booking link action sends a Swoosh email to the candidate's address and shows a success flash.
- [x] 2.4 Verify the manual "Book Interview" flow still sends the candidate confirmation email (existing behavior); add a LiveView test asserting the confirmation email is sent when booking from the schedule page.

## 3. Reach scheduling from the candidate detail page

- [x] 3.1 In `lib/treby_web/live/candidates_live/show.ex`, add a "Schedule Interview" link per application (in the Applications section, next to "View Resume"/"Add Note") navigating to `/app/schedule/:application_id`.
- [x] 3.2 Add a LiveView test in `candidates_live_test.exs` asserting each application shows the "Schedule Interview" link and that it points to `/app/schedule/:application_id`.

## 4. Remove standalone Pipeline landing page

- [x] 4.1 Remove `live "/pipeline", PipelineLive` from `lib/treby_web/router.ex` (keep `live "/pipeline/:job_id", PipelineLive.Index`).
- [x] 4.2 Delete `lib/treby_web/live/pipeline_live/pipeline_live.ex`.
- [x] 4.3 Remove the desktop Pipeline nav link from `lib/treby_web/components/layouts.ex` (lines ~66-71).
- [x] 4.4 Remove the mobile drawer Pipeline nav link from `lib/treby_web/components/layouts.ex` (lines ~175-180).
- [x] 4.5 Update `openspec/specs/app-navigation/spec.md` main spec only after archiving (do not edit main specs in this change).
- [x] 4.6 Grep the codebase for `/app/pipeline"` and `PipelineLive` (without `Index`) to confirm no stale links or references remain; fix any found.

## 5. Pipeline candidate cards link to candidate details

- [x] 5.1 In `lib/treby_web/live/pipeline_live/index.ex`, wrap the candidate name in a `<.link navigate={~p"/app/candidates/#{application.candidate_id}">` on each card (keep the card root as the `Sortable` drag target).
- [x] 5.2 Add a LiveView test in `pipeline_live_test.exs` asserting a candidate card contains a link to `/app/candidates/:candidate_id`.
- [x] 5.3 Manually verify drag-and-drop still works with the nested link (browser check).

## 6. Verification and docs

- [x] 6.1 Run `mix precommit` and fix any failures.
- [x] 6.2 Run the affected tests: `mix test test/treby/interviews_test.exs test/treby_web/live/pipeline_live_test.exs test/treby_web/live/candidates_live_test.exs` and any new scheduling test file.
- [x] 6.3 Regenerate screenshots with `node scripts/screenshots.mjs`.
- [x] 6.4 Update the relevant `site/features/` pages: document the booking-link email flow and the pipeline navigation change (no top-level Pipeline page; cards link to candidate details).
