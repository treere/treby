# Edit Job Pipeline From Job Page — Tasks

## 1. Pipeline context support

- [x] 1.1 Add a `Treby.Pipeline` helper to detect whether a pipeline is shared by more than one active job (e.g. `pipeline_shared?/1` or `active_job_count(pipeline_id)` wrapper around `count_active_jobs/1`, treating the tenant default case explicitly).
- [x] 1.2 Add a helper to resolve a job's effective pipeline id (`job.pipeline_id || default_pipeline_id(job.tenant_id)`), mirroring `list_pipeline_stages_for_job/1`.
- [x] 1.3 Add a helper to decouple a job from a shared pipeline by cloning on first edit, reusing `clone_template_to_pipeline/2`, then updating `job.pipeline_id` to the clone; return the (possibly new) pipeline/stages.
- [x] 1.4 Ensure `clone_template_to_pipeline/2` works when given a non-template pipeline (used to clone shared pipelines); adjust the function or add a sibling clone helper so it does not require `is_template == true`.

## 2. Job detail page editor

- [x] 2.1 In `JobsLive.Show` mount, preload the job's effective pipeline and its stages with role counts (examiner/reviewer/advancer), mirroring `SettingsLive.PipelineStages.mount`.
- [x] 2.2 Add a "Pipeline" section to the job detail template listing stages (color, name, type, role counts) with actions: reorder up/down, Edit, Roles (interview-only), Delete, plus an "Add Stage" button.
- [x] 2.3 Add the stage form (name, type, color, conditional interview fields: min examiners, scorecard template) reused/duplicated from Settings; wire `save_stage`, `cancel_form`, `show_create_form`, `edit_stage` handlers with `actor = @current_user` for authorization.
- [x] 2.4 Add reorder handlers `move_stage_up` / `move_stage_down` operating on the job's stages.
- [x] 2.5 Add delete handlers `delete_stage` / `confirm_reassign` / `cancel_delete` reusing `active_applications_count`, `reassign_and_delete_stage`, and the only-"new"-stage guard.
- [x] 2.6 Add the role assignment modal (examiners/reviewers/advancers) with `show_roles`, `close_roles`, `add_examiner/reviewer/advancer`, `remove_examiner/reviewer/advancer` handlers, mirroring `PipelineStages`.
- [x] 2.7 On the first stage mutation (add/edit/delete/reorder), invoke the decouple helper from task 1.3 so the job is moved to a dedicated pipeline before applying the mutation; refresh the pipeline/stage assigns afterward.
- [x] 2.8 Keep the existing "Pipeline" assign dropdown intact; after decoupling, ensure the dropdown reflects the job's new `pipeline_id`.

## 3. Tests

- [x] 3.1 Add/adjust LiveView tests covering: stage list shown on the job page, add stage, edit stage (name/type/color), reorder up/down.
- [x] 3.2 Add tests for delete with candidates (reassignment modal) and the only-"new"-stage guard.
- [x] 3.3 Add tests for role assignment (examiner/reviewer/advancer) from the job page.
- [x] 3.4 Add tests for the decouple behavior: editing a job using a shared/default pipeline clones it and leaves other jobs and the original pipeline unchanged; a job already dedicated is not cloned again.
- [x] 3.5 Add a test that non-admin users cannot mutate stages from the job page.

## 4. Verification

- [x] 4.1 Run `mix format` on changed files.
- [x] 4.2 Run the job and pipeline LiveView tests and the `Pipeline`-related tests; fix any failures.
- [x] 4.3 Run `mix precommit` and resolve any pending issues.
- [x] 4.4 Regenerate site screenshots with `node scripts/screenshots.mjs` and update the relevant feature page in `site/features/` if the job detail page showcase changed.
