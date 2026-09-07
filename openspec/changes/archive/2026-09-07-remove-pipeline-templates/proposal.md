## Why

Pipeline templates are dead weight: they can be created (name only — no stages, no assignments, no rename) but serve no real workflow. Each job already gets its own pipeline, and the configured pipelines themselves act as reusable models (duplicate + detach flows). The template UI confuses users ("what are templates for?") and the user docs even describe template features that do not exist. Removing them simplifies the product.

## What Changes

- **BREAKING** Remove the "Pipeline Templates" section from Settings → Pipeline (list, New Template form, delete).
- **BREAKING** Remove the "Or start from a template" option from the new-job form; jobs use the pipeline selector or the default pipeline.
- **BREAKING** Remove template context functions (`list_templates`, `create_template`, `delete_template`, `clone_template_to_pipeline`).
- Remove the `is_template` column from `pipelines` (migration deletes template rows, then drops the column) and the `is_template == false` filter from `list_pipelines`.
- Harden per-job pipeline clones (`detach_job_pipeline`) to use unique names so the `(tenant_id, name)` unique index can never break detaches.
- Retire the `pipeline-templates` capability spec; touch up the user manual (`site/features/pipeline.md` templates section).

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `pipeline-config`: template-related UI removed; per-job clones keep unique names.
- `pipeline-templates`: **REMOVED** — entire capability retired (delete `openspec/specs/pipeline-templates/spec.md`).

## Impact

- Affected code: `Treby.Pipeline.Stages` (+ facade), `SettingsLive.Pipeline`, `JobsLive.Index`, `pipelines` table (migration), `pipeline_test.exs` (template tests removed), user manual.
- No impact on real pipelines, stages, role assignments, duplicate/detach flows, or jobs: template rows carry no stages and are referenced by nothing (`jobs.pipeline_id` is `nilify_all`, and nothing ever assigns a template to a job).
