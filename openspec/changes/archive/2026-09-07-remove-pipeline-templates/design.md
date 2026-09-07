# Design: Remove pipeline templates

## Context

`pipelines` rows with `is_template = true` are name-only records: no UI exists to
add stages, assign roles, or rename them, and nothing ever references them
(`jobs.pipeline_id` is `nilify_all` and no flow assigns a template to a job).
Each job already receives its own pipeline (default, selected, duplicated, or
detached clone), so configured pipelines cover the "reusable model" need.

## Decisions

- **D1: Delete, don't migrate, template rows.** Template rows carry no stages
  worth preserving (stages cannot be added to a template through any UI) and
  are referenced by nothing. The migration deletes `WHERE is_template = true`
  before dropping the column. `jobs.pipeline_id` is `nilify_all`, so even a
  hypothetical dangling reference degrades to "use default pipeline".
- **D2: Drop the column, don't just ignore it.** Keeping an unused boolean
  invites future confusion (this change exists because of exactly that).
  Migration: `DELETE FROM pipelines WHERE is_template = true`, then
  `remove :is_template`.
- **D3: Keep generic clone machinery.** `clone_pipeline/2` +
  `clone_pipeline_with_map/2` stay (used by duplicate + detach). Only the
  template-specific wrappers (`list/create/delete/clone_template_to_pipeline`)
  go. Key normalization in `create_template`/`clone_pipeline_with_map` (added
  as a crash fix) is superseded for templates; the `clone_pipeline_with_map`
  normalization stays as defense for duplicate/detach paths.
- **D4: Unique names for detach clones.** `detach_job_pipeline` names clones
  `"<source> (Job)"`; a second detach from the same source would now collide
  with the `(tenant_id, name)` unique index. Reuse the existing
  `unique_copy_name/2` helper so detaches fall back to numbered suffixes.
- **D5: Retire the spec, don't rewrite it.** `pipeline-templates` described
  features that were never built (save-as-template, template stage editor).
  It is deleted; the removal is recorded in this change's delta spec.

## Risks

- A tenant with hand-inserted template rows referenced by jobs: migration
  nullifies those `pipeline_id`s (FK `nilify_all`) and jobs fall back to the
  default pipeline. Acceptable and self-healing.
