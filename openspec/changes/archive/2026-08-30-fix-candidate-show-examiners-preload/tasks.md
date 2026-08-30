## 1. Fix preload in CandidatesLive.Show

- [x] 1.1 Update `preload([:application, examiners: :user])` to `preload([:application, event_examiners: :user])` in `lib/treby_web/live/candidates_live/show.ex:68`
- [x] 1.2 Update template loop for `Scheduled Interviews` to iterate `interview.event_examiners` (or verify `examiners` through association) and render `user.name`
- [x] 1.3 Verify `interview.application.job.title` still preloads correctly with the new preload order

## 2. Tests

- [x] 2.1 Add regression test in `test/treby_web/live/candidates_show_live_test.exs`: create tenant + user + job + candidate + application + `InterviewEvent` with `EventExaminer`, then `live(conn, ~p"/app/candidates/#{candidate.id}")` asserts `html =~ "Scheduled Interviews"` and `html =~ examiner.name` with 200
- [x] 2.2 Run `mix test test/treby_web/live/candidates_show_live_test.exs` and `mix precommit` checks

## 3. Verification & Cleanup

- [x] 3.1 Manual Playwright smoke: `GET /app/candidates/:alice_id` for `Friction Co 86` Alice Dome (has completed interview) returns without LiveView crash
- [x] 3.2 Archive duplicate change `fix-candidate-profile-click-crash` as superseded (or mark in `openspec/changes/.../proposal.md`)
