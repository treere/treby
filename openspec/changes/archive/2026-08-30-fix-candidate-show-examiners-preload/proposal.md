## Why

After scheduling an interview (`/app/schedule/:application_id` → `Book Interview`), the redirect to `CandidatesLive.Show` crashes with `ArgumentError: schema Treby.Accounts.User does not have association :user`. The mount loads interviews via `preload([:application, examiners: :user])` at `candidates_live/show.ex:68`, but `InterviewEvent` has no `:examiners` association — the correct association is `event_examiners` (join to `User`). This blocks the happy path: `Schedule` succeeds (ActivityLog, InterviewEvent created), but the user sees a LiveView crash instead of the candidate profile, breaking the hire loop on fresh tenants.

## What Changes

- Fix the preload in `TrebyWeb.CandidatesLive.Show.mount_active/6`:
  - Change `preload([:application, examiners: :user])` to `preload([:application, event_examiners: :user])` (or `examiners` through `event_examiners` if a `has_many :examiners, through:` is intended) to match `Treby.Interviews.InterviewEvent` schema.
  - Ensure the rendered `interview.examiners` loop (`show.ex` template) uses the same corrected preload key.
- No behavioral change beyond fixing the crash; tenant isolation and existing specs remain unchanged.

## Capabilities

### New Capabilities
- _None_ — hotfix only.

### Modified Capabilities
- `candidate-management`: Candidate profile SHALL load scheduled interviews without crashing when interviews exist; the "Scheduled Interviews" section SHALL display examiner names via the correct association.

## Impact

- Affected code: `lib/treby_web/live/candidates_live/show.ex` (1 line), possibly `lib/treby/interviews/interview_event.ex` assoc alias
- No migration. No dependency change.
- Tests: add regression in `test/treby_web/live/candidates_show_live_test.exs` covering `Schedule Interview → redirect to candidate show` with an interview present.
