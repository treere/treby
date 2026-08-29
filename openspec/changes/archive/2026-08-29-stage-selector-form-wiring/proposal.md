## Why

The per-card stage selector on the job detail page fired `phx-change="move_application"` on a `<select>` that was **not inside a `<form>`**. LiveView raised `form events require the input to be inside a form` in the browser console and the stage move silently failed — users could not change a candidate's state from the job page, the core daily interaction.

## What Changes

- Wrap each per-card stage selector in a `<.form>` with a hidden `application_id` input and a `stage_id` select name, so `phx-change` dispatches correctly.
- Add a clear "Move to stage" label to the selector so the affordance is recognizable.
- Add regression assertions that the selector lives inside a form and that moving a candidate actually updates the stage (guards against the silent console-error failure).

## Capabilities

### New Capabilities

### Modified Capabilities
- `job-page-candidate-management`: the "Inline stage change" requirement gains a scenario that the selector is wired through a form (no console error) and that a browser-driven change actually moves the candidate.

## Impact

- `lib/treby_web/live/jobs_live/show.ex` — per-card selector wrapped in `<.form>` with hidden `application_id`, `stage_id` name, and a "Move to stage" label.
- `test/treby_web/live/jobs_live_show_test.exs` — regression assertions on the form wiring and the move outcome.