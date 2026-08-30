## Why

Clicking **Alice Dome** in `Candidates` (`/app/candidates` → row link `/app/candidates/0fada3cb-adcc-4e11-8b58-6e3aec7da8d0`) currently crashes the LiveView with `** (ArgumentError) schema Treby.Accounts.User does not have association or embed :user` (`candidates_live/show.ex:68`). The same crash occurs for any candidate that has at least one `InterviewEvent` (Alice has `20831a64… status=completed`). The board (`Pipeline` → Interview card) correctly links back via `?return_to=/app/pipeline/…`, so the hire loop is blocked on the most common navigation (candidate detail from candidates list or pipeline). This is the user-reported "click an Alice Dome in candidates I have an error."

Root cause is a wrong Ecto preload in `CandidatesLive.Show.mount_active/6`:
```elixir
Treby.Interviews.InterviewEvent |> preload([:application, examiners: :user])
```
`InterviewEvent` has no `:examiners` association; the join is `has_many :event_examiners` → `belongs_to :user`. Preloading `examiners: :user` forces Ecto to look for `User.examiners` then `User.user`, hence the error. The correct preload is `event_examiners: :user` (and the template should iterate `interview.event_examiners |> Enum.map(& &1.user)` or use the existing `has_many :examiners, through:` if defined).

This duplicates hotfix `fix-candidate-show-examiners-preload` found during the friction simulation; this proposal keeps the same fix but is filed under the user-reported symptom (click crash) for traceability.

## What Changes

- Fix `lib/treby_web/live/candidates_live/show.ex` `mount_active`:
  - Change `preload([:application, examiners: :user])` to `preload([:application, event_examiners: :user])`.
  - Update the `show.html.heex` loop that renders `Scheduled Interviews` to use the corrected association (`interview.event_examiners` or `interview.examiners` through `event_examiners` if the through is kept).
  - Add a nil-guard so an empty `application_ids` list does not trigger unnecessary query (already present) and a template with no interviews still renders.
- No schema or migration change; tenant isolation unchanged.

## Capabilities

### New Capabilities
- _None_ — hotfix only.

### Modified Capabilities
- `candidate-management`: Candidate profile SHALL load and render without crashing when the candidate has interviews; `GET /app/candidates/:id` with interviews SHALL return 200 and show the `Scheduled Interviews` section with examiner names.

## Impact

- Affected code: `lib/treby_web/live/candidates_live/show.ex` (1 line + template), possibly `lib/treby/interviews/interview_event.ex` association alias
- No migration. No deps.
- Tests: add regression in `test/treby_web/live/candidates_show_live_test.exs`: create candidate → create application → schedule interview (with examiner) → `live(conn, ~p"/app/candidates/#{id}")` asserts no crash and shows examiner name. This also covers pipeline→candidate back-link.
- Docs: no `site/` change (user manual does not expose preloads).
