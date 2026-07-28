## 1. Fix Public Application Crash

- [x] 1.1 Fix `careers_live/apply.ex` — replace bare `{:ok, candidate} = find_or_create_candidate(...)` pattern match with `case` block that handles `{:error, changeset}` and shows flash error
- [x] 1.2 Add test for public application submission with invalid email (no crash, error flash shown)

## 2. Fix Silent Pipeline Toggle

- [x] 2.1 Fix `pipeline_live/index.ex` — add `put_flash(:error, "Failed to update review status")` to `toggle_review` `{:error, _}` branch
- [x] 2.2 Add test for pipeline toggle review failure showing flash

## 3. Add Flash to Form Handlers (Jobs)

- [x] 3.1 `jobs_live/index.ex` — add flash to `create_job` `{:error, changeset}` branch
- [x] 3.2 `jobs_live/show.ex` — add flash to `update_job` `{:error, changeset}` branch

## 4. Add Flash to Form Handlers (Candidates)

- [x] 4.1 `candidates_live/index.ex` — add flash to `create_candidate` `{:error, changeset}` branch
- [x] 4.2 `candidates_live/show.ex` — add flash to `create_note` `{:error, changeset}` branch
- [x] 4.3 `candidates_live/show.ex` — add flash to `save_edit` `{:error, changeset}` branch

## 5. Add Flash to Form Handlers (Settings)

- [x] 5.1 `settings_live/sources.ex` — add flash to `save_source` and `update_source` `{:error, changeset}` branches
- [x] 5.2 `settings_live/fields.ex` — add flash to `save_field` `{:error, changeset}` branch
- [x] 5.3 `settings_live/pipeline_stages.ex` — add flash to `save_stage` `{:error, changeset}` branch
- [x] 5.4 `settings_live/email_templates.ex` — add flash to `save_template` `{:error, changeset}` branch
- [x] 5.5 `settings_live/branding.ex` — add flash to `save_branding` `{:error, changeset}` branch
- [x] 5.6 `settings_live/availability.ex` — add flash to `save_rule` `{:error, changeset}` branch
- [x] 5.7 `settings_live/language.ex` — add flash to `save` `{:error, changeset}` branch
- [x] 5.8 `settings_live/pipeline.ex` — add flash to `save_pipeline` `{:error, changeset}` branch

## 6. Align Scorecards Pattern

- [x] 6.1 `settings_live/scorecards.ex` — replace `traverse_errors` + `inspect()` flash with standard `"Please review the errors below"` message

## 7. Tests

- [x] 7.1 Add test for form submission with changeset validation failure showing flash in JobsLive
- [x] 7.2 Add test for form submission with changeset validation failure showing flash in CandidatesLive
- [x] 7.3 Run `mix precommit` to verify all changes pass linting and existing tests
