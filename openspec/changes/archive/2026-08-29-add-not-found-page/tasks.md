## 1. Not Found page

- [x] 1.1 Add a `/404` route in the router (inside an appropriate browser `live_session` / scope so locale and layout apply) pointing to a new `ErrorLive.NotFound` LiveView
- [x] 1.2 Create `TrebyWeb.ErrorLive.NotFound` LiveView with a `render/1` that shows a styled, on-brand "404 Not Found" pane reusing `Layouts.app` (nav, locale, dark mode) and a prominent "back" link (e.g. to `/app/jobs` or `/app`)
- [x] 1.3 Verify the Not Found page renders correctly and no stacktrace appears when visiting `/404` directly

## 2. App entity detail LiveViews redirect on missing entity

- [x] 2.1 `JobsLive.Show` (`mount` at `lib/treby_web/live/jobs_live/show.ex:6`): replace `get_job!` with a safe lookup and redirect to `/404` when nil
- [x] 2.2 `CandidatesLive.Show` (`lib/treby_web/live/candidates_live/show.ex:18`): replace the `raise Ecto.NoResultsError` branch with a redirect to `/404`
- [x] 2.3 `ScheduleLive.Index` (`lib/treby_web/live/schedule_live/index.ex:12`): redirect to `/404` when the application is missing
- [x] 2.4 `PipelineLive.Index` (`lib/treby_web/live/pipeline_live/index.ex:11`): redirect to `/404` when the job is missing
- [x] 2.5 `CandidatePortalLive.MessageThread` and `CandidatePortalLive.Index` (application lookup): redirect to `/404` when missing

## 3. Settings entity views redirect on missing entity

- [x] 3.1 `SettingsLive.PipelineStages` (`pipeline_stages.ex:11`): redirect to `/404` when the pipeline is missing
- [x] 3.2 `SettingsLive.Fields` (`fields.ex`): redirect to `/404` when a custom field referenced by id in URL params is missing — verified: no `:id` URL param (mount takes `_params`); `get_custom_field!` only runs in event handlers on user-selected fields, so no navigation load to guard
- [x] 3.3 `SettingsLive.Sources`, `SettingsLive.Availability`, `SettingsLive.EmailTemplates`, `SettingsLive.Scorecards` route/id lookups: redirect to `/404` when missing where a mount/param load would raise — verified: all four mounts take `_params` (no entity in URL); entity `get_*!` calls are event-handler-only, so no mount load to guard

## 4. Public career/portal routes redirect on missing entity

- [x] 4.1 `CareersLive.Show` (`careers_live/show.ex:12`): use a safe lookup and redirect to `/404` when the job is missing
- [x] 4.2 `CareersLive.Apply` (`careers_live/apply.ex:18`): redirect to `/404` when the job is missing

## 5. Tests and verification

- [x] 5.1 Add LiveView tests asserting that opening a non-existent job/candidate/application/pipeline route redirects to `/404` and does not render a job/candidate template
- [x] 5.2 Add a test that an existing entity still renders normally (no redirect to `/404`)
- [x] 5.3 Run `mix test` (and `mix precommit`) to confirm no failures and no regressions
