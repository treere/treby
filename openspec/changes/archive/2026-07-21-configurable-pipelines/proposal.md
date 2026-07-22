## Why

Pipeline stages are currently tenant-wide — every job in a tenant shares the same set of stages. This doesn't work for organizations with diverse hiring processes. An engineering role needs technical interview stages; a design role needs portfolio review stages. Making pipelines configurable per-job lets each role have its own hiring workflow.

## What Changes

- Add `pipelines` entity — named collections of stages, scoped to a tenant
- Move `pipeline_stages` from tenant-scoped to pipeline-scoped (each pipeline owns its stages)
- Add optional `pipeline_id` to jobs — jobs reference a pipeline, falling back to tenant default
- Add `stage_type` field to stages — optional tags (new, interview, offer, hired, rejected) for auto-move logic and analytics
- Change stage deletion: allow deleting stages with active candidates (with reassignment modal) instead of blocking
- Update interview auto-move to find stages by `stage_type` instead of stage name
- Add pipeline CRUD in Settings (list, create, edit, duplicate, delete)
- Add pipeline selector when creating/editing a job

## Capabilities

### New Capabilities
- `pipeline-config`: Pipeline management — CRUD operations, default pipeline assignment, settings UI for creating and configuring pipeline definitions

### Modified Capabilities
- `pipeline`: Stages become per-pipeline instead of per-tenant; stage deletion allows reassignment; interview auto-move uses stage_type; Kanban board loads stages from job's pipeline

## Impact

- **Database**: New `pipelines` table; `pipeline_stages` changes FK from `tenant_id` to `pipeline_id`, adds `stage_type`; `jobs` gains nullable `pipeline_id`
- **Router**: Settings routes unchanged (existing `/app/settings/pipeline` becomes pipeline list, sub-routes for edit)
- **LiveViews**: `PipelineLive.Index` (Kanban) loads stages from job's pipeline; `SettingsLive.Pipeline` becomes pipeline list + stage editor; `JobsLive` adds pipeline selector
- **Context modules**: `Pipeline` context gains pipeline CRUD functions; stage queries scoped to pipeline instead of tenant
- **Migration**: Requires data migration to create default pipelines for existing tenants and reassign stages
