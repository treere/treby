## 1. Context removal

- [x] 1.1 Remove `list_templates`, `create_template`, `delete_template`, `clone_template_to_pipeline` from `Treby.Pipeline.Stages` and their `defdelegate`s from `Treby.Pipeline`
- [x] 1.2 Drop the `is_template == false` filter from `list_pipelines`
- [x] 1.3 Remove `:is_template` from `Pipeline` schema cast list
- [x] 1.4 Use `unique_copy_name/2` for detach clone names in `detach_job_pipeline`

## 2. Migration

- [x] 2.1 Generate migration: delete `pipelines` rows with `is_template = true`, then `remove :is_template`
- [x] 2.2 Run `mix ecto.migrate` on dev DB

## 3. LiveView UI

- [x] 3.1 Remove templates section (list, New Template form, delete) + `show_template_form`/`template_form` assigns + 4 template events from `SettingsLive.Pipeline`
- [x] 3.2 Remove `templates` assign, "Or start from a template" UI, and `template_id` clone branch from `JobsLive.Index.create_job`

## 4. Tests

- [x] 4.1 Remove template tests from `test/treby/pipeline_test.exs` (namespace, string-key form params, clone-from-template); keep uniqueness/rename/duplicate tests green
- [x] 4.2 Run full suite (`mix test`) green

## 5. Specs & docs

- [x] 5.1 Delete `openspec/specs/pipeline-templates/spec.md` (retired; removal recorded in this change's delta spec)
- [x] 5.2 Remove the "Pipeline Templates" section from `site/features/pipeline.md` (English, user-manual tone, no code references)
- [x] 5.3 `mix precommit` clean
