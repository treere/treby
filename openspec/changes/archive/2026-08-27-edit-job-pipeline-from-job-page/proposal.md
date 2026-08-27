# Edit Job Pipeline From Job Page

## Why

Today pipeline stages can only be edited in the Settings (Settings → Pipelines → Edit). On the job detail page the only pipeline interaction is a `select` dropdown that assigns a pre-existing pipeline to the job. A user managing a single job cannot tweak its stages without leaving the job page and navigating through Settings, which is tedious and context-breaking.

This change lets an admin edit the stages of the job's pipeline directly from the job detail page, while keeping the existing Settings editor intact. A job's pipeline is already dedicated to that job (when created from a template it is cloned and decoupled from the template); the editor preserves this invariant.

## What Changes

- Add a "Pipeline" section/editor on the job detail page (`JobsLive.Show`) that lists the stages of the job's pipeline.
- Allow the same stage operations available in Settings, executed in the job context:
  - Add a new stage
  - Edit a stage's name, type, color, min examiners, scorecard template
  - Reorder stages (move up/down)
  - Delete a stage (with candidate reassignment when the stage has active candidates; prevent deleting the only "new" stage)
  - Assign/remove examiner, reviewer, and advancer roles to a stage (kept consistent with the Settings behavior)
- **Decouple behavior (job-scoped pipeline)**: A job's pipeline is dedicated to that job. When the job uses a pipeline that is shared with other jobs (assigned via the dropdown or the tenant default), the first time stages are edited from the job page the system clones that pipeline for the job — the same mechanism used when a job is created from a template (`clone_template_to_pipeline`) — so edits never affect other jobs.
- Keep the existing "Pipeline" assign dropdown on the job so the admin can still change which pipeline the job uses.
- Admin-only authorization, consistent with the existing `Pipeline.create/update/delete_pipeline_stage` role checks.

## Capabilities

### New Capabilities
- `job-pipeline-editor`: Configure and edit the job's pipeline stages directly from the job detail page (add/edit/reorder/delete stages and manage stage roles), keeping the pipeline dedicated to the job by auto-cloning shared pipelines on first edit.

### Modified Capabilities
<!-- No existing spec-level behavior changes; this extends the job detail page (implementation) rather than changing an existing requirement. Intentional and left empty. -->

## Impact

- **LiveView**: `TrebyWeb.JobsLive.Show` (`lib/treby_web/live/jobs_live/show.ex`) — new pipeline editor section + stage role modal and event handlers.
- **Pipeline context**: reuse existing functions in `Treby.Pipeline` (`list_pipeline_stages`, `create/update/delete_pipeline_stage`, `reassign_and_delete_stage`, `active_applications_count`, role assignment helpers, and `clone_template_to_pipeline` for decoupling shared pipelines). May require small additions (e.g. a helper to detect pipeline sharing or clone-on-first-edit).
- **Routes**: no new routes (edit is rendered in an overlay/modal within the existing job detail page); if a dedicated route is preferred, a job-scoped stage route could be added.
- **Templates**: only the job detail template is extended; no new shared components beyond what already exists in the design system.
- **Access**: stage mutation remains restricted to admins via the existing actor checks in the Pipeline context.
- **Docs/site**: the `site/features/` showcase may need a screenshot update for the job detail page.
