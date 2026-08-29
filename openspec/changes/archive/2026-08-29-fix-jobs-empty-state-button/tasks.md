## 1. Empty state button fix

- [x] 1.1 Replace the `action` map on the jobs index empty state with a `:cta` slot containing a `<button phx-click="show_create_form" class="btn btn-primary">` labeled "Create your first job"

## 2. Test coverage

- [x] 2.1 Replace the text-only assertion in `test/treby_web/live/jobs_live_test.exs` with an interaction test: render the empty state, click the "Create your first job" button, and assert the inline form (`#job-form`) is revealed

## 3. Verification

- [x] 3.1 Run `mix test test/treby_web/live/jobs_live_test.exs` and confirm the empty-state tests pass