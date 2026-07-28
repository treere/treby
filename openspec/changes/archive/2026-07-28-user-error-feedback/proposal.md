## Why

When form submissions fail validation, users get no explicit signal — the form silently re-renders with inline field errors that are easy to miss, especially on longer forms. Users think the app is broken. Additionally, the public candidate application page (`CareersLive.Apply`) crashes on certain invalid inputs, losing potential hires entirely. Both issues directly hurt core product value: the first erodes trust in the app, the second loses actual job applicants.

## What Changes

- Add `put_flash(:error, ...)` to every `handle_event` that currently silently re-renders the form on `{:error, changeset}` (~12 form handlers across Jobs, Candidates, and Settings LiveViews)
- Use a consistent, user-friendly flash message: "Please review the errors below" (not raw changeset inspection)
- Fix `CareersLive.Apply` bare pattern match crash on `find_or_create_candidate` failure — wrap in `case` with user-friendly error flash
- Fix `PipelineLive.Index` silent swallow on `toggle_review` failure — add flash message

## Capabilities

### New Capabilities

- `error-feedback`: Flash message feedback on form validation failures, public application error handling, and pipeline toggle failure feedback

### Modified Capabilities

## Impact

- **Files**: ~12 LiveView modules (`jobs_live/index.ex`, `jobs_live/show.ex`, `candidates_live/index.ex`, `candidates_live/show.ex`, `settings_live/sources.ex`, `settings_live/fields.ex`, `settings_live/pipeline_stages.ex`, `settings_live/email_templates.ex`, `settings_live/branding.ex`, `settings_live/availability.ex`, `settings_live/language.ex`, `settings_live/pipeline.ex`), plus `careers_live/apply.ex` and `pipeline_live/index.ex`
- **No breaking changes**: Only additive — adding flash messages to existing error branches
- **No new dependencies**: Uses existing `put_flash` and `core_components` flash infrastructure
- **No schema/migration changes**: Purely UI-layer error feedback
