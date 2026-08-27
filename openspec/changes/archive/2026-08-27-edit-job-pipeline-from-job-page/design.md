# Edit Job Pipeline From Job Page — Design

## Context

The job detail page (`TrebyWeb.JobsLive.Show`, `lib/treby_web/live/jobs_live/show.ex`) currently exposes the pipeline only as a `select` field (`@form[:pipeline_id]`) used to assign a pre-existing pipeline to the job. The full pipeline stage editor lives in Settings (`TrebyWeb.SettingsLive.PipelineStages`, `lib/treby_web/live/settings_live/pipeline_stages.ex`).

The `Treby.Pipeline` context already exposes all the stage-management functions needed:
- `list_pipeline_stages/1`, `get_pipeline_stage!`
- `create_pipeline_stage/2`, `update_pipeline_stage/3`, `delete_pipeline_stage/2`
- `reassign_and_delete_stage/2`, `active_applications_count/1`
- role helpers: `assign_examiner/2`, `remove_examiner/2`, `list_examiners/1`, etc.

All `create/update/delete_pipeline_stage` functions take an `actor` and return `{:error, :unauthorized}` when `actor.role != "admin"`.

Constraint: a job may use the tenant's default pipeline (when `pipeline_id` is nil), per `list_pipeline_stages_for_job/1`. The job's effective pipeline is `job.pipeline_id || default_pipeline_id(job.tenant_id)`.

**Job-scoped pipeline invariant**: When a job is created from a template, the pipeline is cloned (`clone_template_to_pipeline`) and is therefore dedicated to that job and decoupled from the template. The user wants this invariant to hold for the editor: edits from a job's page must never affect other jobs. When a job points to a pipeline shared with other jobs (selected via the dropdown or the tenant default), the editor decouples it by cloning on first edit.

## Goals / Non-Goals

**Goals:**
- Edit the stages of a job's pipeline directly from the job detail page.
- Preserve the invariant that a job's pipeline is dedicated to that job: edits never affect other jobs (auto-clone shared pipelines on first edit).
- Reuse the existing `Treby.Pipeline` context API and the Settings editor's behavior/guards.
- Support stage add/edit/reorder/delete (with candidate reassignment) and role management.
- Keep the existing "Pipeline" assign dropdown on the job page.
- Restrict stage mutations to admins, consistent with Settings.

**Non-Goals:**
- Modifying the Settings editor or its routes.
- Adding a per-job pipeline data model change/migration (decoupling is done by cloning existing pipelines, not a new schema).
- Editing the job's other fields from within the new pipeline section.

## Decisions

### D1: Embed the editor in the job detail page (no new route)
Add a "Pipeline" section directly in `JobsLive.Show`, below the Edit Job form / alongside the candidates section. Single-price: reuses `@job.pipeline`, `@pipelines`, existing assigns; no router changes.

Alternatives considered:
- A separate job-scoped route (`/app/jobs/:id/pipeline/edit`) reusing `PipelineStages`. Rejected: introduces a parallel page and navigation, more surface area, and delivers worse UX than an inline overlay on the job page.

### D2: Resolve the effective pipeline with the same fallback as the Kanban board
Use `job.pipeline_id || default_pipeline_id(job.tenant_id)`, mirroring `list_pipeline_stages_for_job/1`. This ensures the editor shows exactly the stages the job's Kanban board uses, even when the job uses the default pipeline implicitly.

### D3: Reuse the existing context functions verbatim
No new `Treby.Pipeline` functions for the CRUD/roles themselves. The editor calls the same functions `PipelineStages` uses. This keeps authorization (`actor.role != "admin"`) and reassignment logic single-sourced; DRY wins over a dedicated job-scoped variant. A small helper may be added to (a) detect whether a pipeline is shared by more than one active job and (b) clone-on-first-edit — implemented on top of existing functions (`count_active_jobs/1`, `clone_template_to_pipeline/2`).

### D4: Decouple shared pipelines on first edit
Before the first stage mutation from the job page, compute the job's effective pipeline. If it is shared (i.e. used by more than one active job, including the tenant default), clone it for the job via the existing `clone_template_to_pipeline/2` mechanism and point `job.pipeline_id` to the clone. Only the edited job is affected; other jobs keep the original pipeline. A job whose pipeline was created from a template is already dedicated, so no clone occurs. The clone is transparent to the user — the stage list they see is simply the editor operating on the job's own pipeline.

### D5: Stage role management via an inline modal
Reuse the examiner/reviewer/advancer role modal pattern already implemented in `PipelineStages` (the `@editing_roles` overlay) within the job page. Only interview-type stages show the "Roles" action, matching Settings.

### D6: Reuse stage form fields and options
The stage form on the job page mirrors the Settings form: name, type (`stage_type_options`), color, and conditional interview fields (min examiners, scorecard template). Extract shared option helpers only if both editors live in the same view module; otherwise keep the small duplicated helpers (they are tiny). Prefer extraction into a shared module if it avoids duplication across `JobsLive.Show` and the Settings editor.

## Risks / Trade-offs

- **Clone-on-first-edit surprises** → Repointing `job.pipeline_id` at edit time is largely transparent since the clone carries over all stages, colors, types, and role assignments. Communicate via the editor header (e.g. "This pipeline belongs to this job only"). Applications retain their `pipeline_stage_id` after the clone (stage IDs are preserved by `clone_template_to_pipeline`), so the Kanban board remains consistent for the edited job; other jobs are untouched.
- **Default-pipeline implicit usage** → If the job has no explicit `pipeline_id`, it implicitly uses the tenant default; editing from the job page clones that default for the job instead of mutating the shared default. The dropdown may still be set explicitly first by the user; either path keeps the job isolated.
- **Stage deletion with candidates** → Reuse the same reassignment flow (`reassign_and_delete_stage`), which operates within the job's (now dedicated) pipeline, avoiding cross-job effects.
- **Only "new" stage deletion** → Reuse the guard that prevents deleting the only stage of type "new".
- **Unauthorized (non-admin) access** → The context returns `{:error, :unauthorized}`; the editor shows the "Edit" affordance only to admins, mirroring the settings behavior to avoid exposing failure paths to non-admins.

## Migration Plan

- No data migration; no schema change.
- Ships as a single LiveView template + handler update.
- Rollback: revert the `JobsLive.Show` changes; pipeline context is untouched.

## Open Questions

- None blocking. Minor: whether to extract the stage form/options into a shared helper module vs. duplicating a few lines — resolved at implementation for the smallest cohesive change.
