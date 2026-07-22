## Context

The app currently has a single set of pipeline stages scoped to each tenant. All jobs within a tenant share the same stages (New → Screen → Interview → Offer → Hired). The `pipeline_stages` table has a `tenant_id` FK, and `applications` tracks candidates' positions within those shared stages.

This works for simple organizations but breaks when different roles need different hiring workflows. An engineering pipeline needs technical interview stages; a design pipeline needs portfolio review stages.

Current schema:
- `pipeline_stages`: id, name, position, color, tenant_id, timestamps
- `applications`: id, job_id, candidate_id, pipeline_stage_id, tenant_id, timestamps
- `jobs`: id, title, tenant_id, timestamps (+ other fields)

## Goals / Non-Goals

**Goals:**
- Allow multiple named pipelines per tenant
- Each job references a pipeline (or uses tenant default)
- Stages belong to a pipeline, not a tenant
- Stage types for auto-move logic (interview, offer, etc.)
- Pipeline CRUD in Settings (list, create, edit, duplicate, delete)
- Stage deletion with candidate reassignment (not blocking)
- Pipeline selector in job creation/editing

**Non-Goals:**
- Cross-tenant pipeline sharing
- Pipeline templates or import/export
- Pipeline versioning or history
- Stage conditions or branching (linear pipelines only)
- Bulk stage operations across pipelines

## Decisions

**1. Pipelines table design**

New `pipelines` table:
```
pipelines
├── id:          :binary_id (UUID, PK)
├── name:        :string (NOT NULL)
├── is_default:  :boolean (default: false)
├── tenant_id:   :binary_id (FK -> tenants, NOT NULL)
├── inserted_at: :utc_datetime
└── updated_at:  :utc_datetime
```

Index: composite `(tenant_id, is_default)` for fast default lookup.
Constraint: one default per tenant enforced in application code (not DB), since partial unique indexes aren't universally supported and the write path is simple enough.

**Rationale**: Separate entity rather than a field on jobs because pipelines have their own lifecycle (CRUD, stages, duplication). Keeping it as a table also lets the Kanban board and settings UI query cleanly.

**2. pipeline_stages FK change**

Drop `tenant_id` from `pipeline_stages`, add `pipeline_id` (NOT NULL FK -> pipelines, on_delete: :delete_all).

Add `stage_type` field: string, nullable, values restricted to `~w(new interview offer hired rejected)` in application code.

**Rationale**: Stages are conceptually children of a pipeline, not a tenant. The `stage_type` is optional because most stages are custom/untagged — only special-purpose stages need it. Keeping it as a string with app-level validation (rather than an enum type) is simpler and matches the project's existing patterns (e.g., `users.role` is also a string).

**3. Job → Pipeline resolution**

Add nullable `pipeline_id` FK to `jobs` (on_delete: :nilify_all).

Resolution logic:
```
job.pipeline_id != nil  →  use that pipeline
job.pipeline_id == nil  →  use tenant's default pipeline
```

**Rationale**: Nullable FK with a fallback is simpler than requiring every job to have a pipeline. New jobs default to the tenant's default pipeline unless explicitly assigned. The nilify_all on delete means if a pipeline is deleted, jobs revert to the default gracefully.

**4. Stage deletion with reassignment**

When a stage has active applications, show a reassignment modal instead of blocking deletion. The modal lists all other stages in the pipeline and lets the user pick where to move candidates.

After reassignment, the stage is hard-deleted.

**Rationale**: Blocking deletion is frustrating when you're redesigning your pipeline. A modal forces the user to handle active candidates explicitly, which is safer than nilify_all (which would lose track of where candidates were). Hard delete keeps the data clean — no soft-delete filtering complexity.

**5. Delete pipeline behavior**

When deleting a pipeline that has active jobs:
- Show confirmation modal listing affected jobs
- Move all jobs to the tenant's default pipeline
- Delete the pipeline and its stages (cascade)

Cannot delete the tenant's last pipeline (must always have at least one).

**6. Interview auto-move uses stage_type**

The `schedule_interview/1` function currently finds a stage named "Interview" by string match. With multiple pipelines, this breaks.

Change to: find stage where `stage_type == "interview"` within the job's pipeline. If no such stage exists, skip the auto-move gracefully (don't fail the interview scheduling).

**Rationale**: `stage_type` is a stable identifier regardless of what the stage is named. Each pipeline defines its own interview stage. The graceful skip means pipelines without an interview stage still work — candidates just don't auto-move.

**7. Settings UI restructure**

Current: flat list of stages at `/app/settings/pipeline`
New: two-level UI
- `/app/settings/pipeline` → list of pipelines with counts
- `/app/settings/pipeline/:id` → stage editor for that pipeline

Pipeline list shows: name, stage count, active job count, default indicator, edit/duplicate/delete actions.

Stage editor shows: reorderable stage list with name, stage_type dropdown, color picker, delete button. Add stage button at bottom.

**8. Kanban board loads from job's pipeline**

`list_pipeline_stages_for_job/1` changes from:
```elixir
where([ps], ps.tenant_id == ^job.tenant_id)
```
to:
```elixir
where([ps], ps.pipeline_id == ^pipeline_id)
```

Where `pipeline_id` is resolved from `job.pipeline_id || default_pipeline_id(job.tenant_id)`.

**9. Migration strategy**

Since the app is pre-production, write a single migration that:
1. Creates `pipelines` table
2. For each tenant with existing stages: create a default pipeline, reassign stages
3. Adds `pipeline_id` to `jobs` (nullable)
4. Recreates `pipeline_stages` with `pipeline_id` FK instead of `tenant_id`, adds `stage_type`
5. Backfills `stage_type` based on stage name matching ("New"→"new", "Interview"→"interview", etc.)

This is cleaner than preserving old migrations and writing complex data migration scripts.

## Risks / Trade-offs

- **Risk**: Deleting a pipeline cascades to stages, which cascades to nilify applications' `pipeline_stage_id` → **Mitigation**: The reassignment modal ensures applications are moved before deletion. The cascade on_delete: :delete_all for stages is a safety net, not the primary path.

- **Risk**: Two users editing the same pipeline's stages concurrently could cause conflicts → **Mitigation**: Low risk in practice (settings are edited rarely). The Kanban board already handles real-time stage changes via PubSub. If needed, optimistic locking can be added later.

- **Risk**: Default pipeline constraint (one per tenant) could drift if two requests set defaults simultaneously → **Mitigation**: Application-level serialization. The "set default" operation is: unset current default, set new default, in a transaction. Low write volume makes this safe.

- **Trade-off**: Hard delete vs soft delete for stages → Choose hard delete for simplicity. Historical data is preserved in the `applications` table (which still has `pipeline_stage_id`, just nilified if the stage is gone). The reassignment modal prevents data loss in the first place.

- **Trade-off**: Nullable `pipeline_id` on jobs vs required → Choose nullable for backward compatibility and simplicity. Jobs without a pipeline just use the tenant default.
