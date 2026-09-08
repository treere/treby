## Context

`JobsLive.Index` rendered `prompt={gettext("Default pipeline")}` above real options and relied on `create_job` fallback to `Pipeline.default_pipeline_id/1` when `pipeline_id` was empty. Specs described this as "empty prompt → nil".

## Goals / Non-Goals

**Goals:**
- Make job creation show only real pipelines with the default preselected; remove confusing placeholder.

**Non-Goals:**
- Change default-pipeline designation logic or fallback for API callers.

## Decisions

- **Preselect in LiveView, not via prompt**: mount and `show_create_form`/`hide_create_form` build form with `%Job{pipeline_id: default_pipeline_id}`; select has no prompt. Alternatives (prompt with default name) still showed abstract entry.
- **Keep backend fallback**: `create_job` still handles `nil/""` → default for safety/API compatibility; no spec break.

## Risks / Trade-offs

- [Risk] Tenant has no pipelines → select empty and job creation falls back to nil → mitigated by fallback and validation (pipeline required elsewhere).
- [Risk] Default changes after page load → stale preselection → minor; user can change selection, fallback covers edge.

## Migration Plan

No migration. Deploy code only; rollback via revert.

## Open Questions

None.
