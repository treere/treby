## 1. Verify the implemented fix

- [x] 1.1 Confirm the per-card stage selector in `jobs_live/show.ex` is wrapped in `<.form for={%{}} id={"move-form-#{application.id}"} phx-change="move_application">` with a hidden `application_id` input and `stage_id` select name
- [x] 1.2 Confirm the "Move to stage" label renders above the selector
- [x] 1.3 Run `rtk mix test test/treby_web/live/jobs_live_show_test.exs` — the "moves a candidate to another stage via the selector" test asserts the form wiring (`#move-form-#{id} #move-select-#{id}`) and the move outcome

## 2. Finalize

- [x] 2.1 Run `mix precommit` (format, credo, sobelow, compile --warnings-as-errors, full test suite)
- [x] 2.2 Sync the delta spec to `openspec/specs/job-page-candidate-management/spec.md` and archive the change