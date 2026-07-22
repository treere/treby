## 1. Database & Schema

- [x] 1.1 Create `pipelines` table migration (id, name, is_default, tenant_id, timestamps)
- [x] 1.2 Create Pipeline schema (`lib/treby/pipeline/pipeline.ex`)
- [x] 1.3 Add `pipeline_id` FK to `jobs` table (nullable, on_delete: :nilify_all)
- [x] 1.4 Update Job schema with `belongs_to :pipeline` association
- [x] 1.5 Recreate `pipeline_stages` migration: drop `tenant_id`, add `pipeline_id` FK (NOT NULL, on_delete: :delete_all), add `stage_type` field
- [x] 1.6 Update PipelineStage schema: replace `belongs_to :tenant` with `belongs_to :pipeline`, add `stage_type` field

## 2. Pipeline Context Module

- [x] 2.1 Add pipeline CRUD functions to `Pipeline` context (list_pipelines, get_pipeline!, create_pipeline, update_pipeline, delete_pipeline)
- [x] 2.2 Add `set_default_pipeline/2` function (unsets current default, sets new default in transaction)
- [x] 2.3 Add `duplicate_pipeline/2` function (copies pipeline + all stages)
- [x] 2.4 Add `default_pipeline_id/1` function (returns tenant's default pipeline ID)
- [x] 2.5 Update `list_pipeline_stages/1` to accept `pipeline_id` instead of `tenant_id`
- [x] 2.6 Update `list_pipeline_stages_for_job/1` to resolve pipeline from job (job.pipeline_id || default)
- [x] 2.7 Update `create_application/1` to use pipeline-scoped stages for initial stage assignment
- [x] 2.8 Add `reassign_and_delete_stage/2` function (moves applications to target stage, then deletes)
- [x] 2.9 Add `delete_pipeline_with_reassignment/2` function (moves jobs to default, deletes pipeline)

## 3. Settings UI — Pipeline List

- [x] 3.1 Restructure `SettingsLive.Pipeline` into pipeline list view (name, stage count, job count, default indicator)
- [x] 3.2 Add "New Pipeline" form/modal to pipeline list
- [x] 3.3 Add "Set Default" action to pipeline list items
- [x] 3.4 Add "Duplicate" action to pipeline list items
- [x] 3.5 Add "Delete" action with confirmation modal (shows affected jobs, blocks if last pipeline)
- [x] 3.6 Add route for pipeline stage editor (`/app/settings/pipeline/:id`)

## 4. Settings UI — Stage Editor

- [x] 4.1 Create `SettingsLive.Pipeline.Stages` LiveView for editing stages within a pipeline
- [x] 4.2 Render reorderable stage list with name, stage_type dropdown, color, delete button
- [x] 4.3 Implement stage_type dropdown with fixed options: (none), new, interview, offer, hired, rejected
- [x] 4.4 Implement add stage form
- [x] 4.5 Implement stage reordering (drag-and-drop or up/down buttons)
- [x] 4.6 Implement delete stage with no candidates (direct delete)
- [x] 4.7 Implement delete stage with candidates (reassignment modal: list other stages, select destination, confirm)
- [x] 4.8 Implement delete guard for last stage with type "new" (warning, prevent delete)

## 5. Kanban Board Update

- [x] 5.1 Update `PipelineLive.Index` to load stages from job's resolved pipeline
- [x] 5.2 Update `list_applications_by_stage/1` to work with pipeline-scoped stages
- [x] 5.3 Verify drag-and-drop works correctly with pipeline-scoped stages
- [x] 5.4 Verify real-time PubSub updates work with pipeline-scoped stages

## 6. Job Pipeline Selector

- [x] 6.1 Add pipeline selector dropdown to job creation form (`JobsLive.Index` or relevant form)
- [x] 6.2 Add pipeline selector to job edit form (`JobsLive.Show` or relevant form)
- [x] 6.3 Default selector to tenant's default pipeline

## 7. Interview Auto-Move

- [x] 7.1 Update `schedule_interview/1` to find interview stage by `stage_type` within job's pipeline
- [x] 7.2 Handle graceful skip when no `stage_type == "interview"` stage exists in pipeline

## 8. Migration

- [x] 8.1 Write data migration: create `pipelines` table
- [x] 8.2 Write data migration: for each tenant, create default pipeline and reassign existing stages
- [x] 8.3 Write data migration: add `pipeline_id` to jobs (nullable)
- [x] 8.4 Write data migration: alter `pipeline_stages` (drop tenant_id, add pipeline_id, add stage_type)
- [x] 8.5 Backfill `stage_type` based on stage name matching ("New"→"new", "Interview"→"interview", "Offer"→"offer", "Hired"→"hired")

## 9. Cleanup & Verification

- [x] 9.1 Run `mix precommit` and fix any warnings
- [x] 9.2 Verify all existing pipeline tests pass
- [x] 9.3 Test pipeline CRUD operations end-to-end
- [x] 9.4 Test stage deletion with reassignment
- [x] 9.5 Test job pipeline assignment and Kanban board rendering
- [x] 9.6 Test interview auto-move with stage_type
