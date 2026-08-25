## 1. Database Migrations

- [x] 1.1 Create migration: add `is_template` boolean (default false) to `pipelines` table
- [x] 1.2 Create migration: add `min_examiners` integer (default 1) to `pipeline_stages` table
- [x] 1.3 Create migration: add `scorecard_template_id` FK (nullable) to `pipeline_stages` table
- [x] 1.4 Create migration: create `pipeline_stage_examiners` junction table (pipeline_stage_id, user_id, unique pair)
- [x] 1.5 Create migration: create `pipeline_stage_reviewers` junction table (pipeline_stage_id, user_id, unique pair)
- [x] 1.6 Create migration: create `pipeline_stage_advancers` junction table (pipeline_stage_id, user_id, unique pair)
- [x] 1.7 Create migration: create `interview_event_examiners` junction table (interview_event_id, user_id, status, unique pair)
- [x] 1.8 Create migration: add `pipeline_stage_id` FK (nullable) to `booking_tokens` table
- [x] 1.9 Write data migration: backfill `interview_event_examiners` from existing `interviewer_id` on `interview_events`
- [x] 1.10 Write data migration: backfill `booking_tokens.pipeline_stage_id` from linked application's current stage
- [x] 1.11 Create migration: remove `interviewer_id` column from `interview_events` (after backfill)

## 2. Ecto Schemas & Context Functions

- [x] 2.1 Add `is_template` field to `Treby.Pipeline.Pipeline` schema and changeset
- [x] 2.2 Add `min_examiners`, `scorecard_template_id` fields to `Treby.Pipeline.PipelineStage` schema and changeset
- [x] 2.3 Create `Treby.Pipeline.StageExaminer` schema for junction table
- [x] 2.4 Create `Treby.Pipeline.StageReviewer` schema for junction table
- [x] 2.5 Create `Treby.Pipeline.StageAdvancer` schema for junction table
- [x] 2.6 Create `Treby.Interviews.EventExaminer` schema for junction table
- [x] 2.7 Update `Treby.Pipeline.PipelineStage` to `has_many` examiner/reviewer/advancer associations
- [x] 2.8 Update `Treby.Interviews.InterviewEvent` to remove `interviewer_id`, add `has_many :event_examiners`
- [x] 2.9 Update `Treby.Scorecards.Scorecard` unique constraint to `[:interview_event_id, :interviewer_id]`
- [x] 2.10 Update `Treby.Interviews.BookingToken` to add nullable `pipeline_stage_id` FK
- [x] 2.11 Add context functions: `assign_examiner/2`, `remove_examiner/2`, `list_examiners/1` on pipeline stage
- [x] 2.12 Add context functions: `assign_reviewer/2`, `remove_reviewer/2`, `list_reviewers/1` on pipeline stage
- [x] 2.13 Add context functions: `assign_advancer/2`, `remove_advancer/2`, `list_advancers/1` on pipeline stage
- [x] 2.14 Add `all_scorecards_completed?/1` function to `Treby.Pipeline` context
- [x] 2.15 Add `list_eligible_examiners/1` function to get examiners for a pipeline stage

## 3. Pipeline Templates

- [x] 3.1 Add `list_templates/1` function to `Treby.Pipeline` context (filters `is_template = true`)
- [x] 3.2 Add `create_template/1` function (creates pipeline with `is_template = true`)
- [x] 3.3 Update `duplicate_pipeline/1` to also copy examiner/reviewer/advancer assignments and min_examiners
- [x] 3.4 Add `clone_template_to_pipeline/2` function (clones template → new pipeline, copies stages and all role assignments)
- [x] 3.5 Add `delete_template/1` function (only deletes if `is_template = true`)
- [x] 3.6 Update `list_pipelines/1` to exclude templates by default (separate query for templates)

## 4. Multi-Examiner Scheduling Engine

- [x] 4.1 Refactor `Treby.Calendar` free/busy query to accept a list of user IDs and batch Google Calendar API calls
- [x] 4.2 Implement `compute_overlapping_slots/4` function: takes list of examiners, min_examiners, date range, duration; returns overlapping available slots
- [x] 4.3 Implement availability rules intersection: compute common availability windows across examiners' availability rules
- [x] 4.4 Implement free/busy intersection: for each common window, subtract busy periods from each examiner's calendar
- [x] 4.5 Add slot caching (ETS or Cachex) for examiner availability per date range (5-minute TTL)
- [x] 4.6 Refactor `schedule_interview/1` to accept multiple examiner IDs, create junction table records, create single calendar event for all examiners
- [x] 4.7 Update `send_interview_notifications/1` to notify all examiners (not just one)
- [x] 4.8 Update `cancel_interview/1` to handle multi-examiner cancellation and notify all examiners
- [x] 4.9 Implement examiner substitution logic: find eligible examiners with overlapping availability when one cancels
- [x] 4.10 Add notification to advancer when no substitute is found for a cancelled examiner

## 5. Scorecard Completion Tracking

- [x] 5.1 Add `scorecard_completion_status/1` function: returns %{completed: N, total: M, pending: [...]} for an interview event
- [x] 5.2 Update `Treby.Scorecards` to associate scorecard with specific examiner via `interview_event_examiners` junction
- [x] 5.3 Update scorecard form to use stage's linked scorecard template (via `pipeline_stage.scorecard_template_id`)
- [x] 5.4 Add scorecard completion indicator to interview event detail page

## 6. Candidate Self-Scheduling (Multi-Examiner)

- [x] 6.1 Update booking token generation to link to `pipeline_stage_id` for multi-examiner stages
- [x] 6.2 Update public booking page to compute and display overlapping slots for multi-examiner stages
- [x] 6.3 Update slot display to show which examiners are available per slot
- [x] 6.4 Update slot booking to create event with all available examiners for the selected slot
- [x] 6.5 Update confirmation page to list all examiners for the booked event

## 7. Pipeline UI — Role Assignment

- [x] 7.1 Add role assignment panel to pipeline stage editor (Settings > Pipeline)
- [x] 7.2 Build examiner assignment UI: user search/select, list with remove button
- [x] 7.3 Build reviewer assignment UI: user search/select, list with remove button
- [x] 7.4 Build advancer assignment UI: user search/select, list with remove button
- [x] 7.5 Add min_examiners input field to interview-type stage configuration
- [x] 7.6 Add scorecard template selector to stage configuration
- [x] 7.7 Show assigned roles summary on pipeline stage list (small badges for examiner/reviewer/advancer counts)

## 8. Pipeline Templates UI

- [x] 8.1 Add "Pipeline Templates" section to Settings page
- [x] 8.2 Build template list view (name, stage count, role assignment status)
- [x] 8.3 Build "Create Template" flow (same as pipeline creation but with `is_template = true`)
- [x] 8.4 Build "Save as Template" action on existing pipeline
- [x] 8.5 Add template selector to job creation flow ("Start from template" option)
- [x] 8.6 Implement template cloning: when job is created from template, clone pipeline with all role assignments
- [x] 8.7 Add edit/delete actions for templates

## 9. Advancement & Rejection UI

- [x] 9.1 Add "Advance" button to pipeline Kanban card, gated by advancer role check
- [x] 9.2 Add scorecard completion check: disable "Advance" on interview-type stages until all scorecards are submitted
- [x] 9.3 Show scorecard completion progress indicator on candidate card in interview stage (e.g., "2/3 scorecards")
- [x] 9.4 Add "Reject" button with motivation modal to pipeline Kanban card
- [x] 9.5 Store rejection motivation on application (add `rejection_reason` field or use notes)
- [x] 9.6 Show rejected candidates in a "Rejected" filter/view (not on active Kanban board)

## 10. Interviews Dashboard Updates

- [x] 10.1 Update interviews dashboard to show all examiners per event (not single interviewer)
- [x] 10.2 Add scorecard completion status per examiner in the dashboard list
- [x] 10.3 Update filter-by-interviewer to match against `interview_event_examiners` junction
- [x] 10.4 Update interview detail page to show per-examiner scorecard status and results

## 11. Analytics & Reporting

- [x] 11.1 Update pipeline analytics to work with template pipelines (exclude templates from active pipeline counts)
- [x] 11.2 Add multi-examiner event metrics: average examiners per event, scorecard completion rate
