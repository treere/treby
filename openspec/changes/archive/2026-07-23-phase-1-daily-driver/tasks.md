## 1. Database & Schema

- [x] 1.1 Create migration to add `reviewed` boolean field (default: false) to `applications` table
- [x] 1.2 Create migration to create `activity_log` table (id, action, actor_id, entity_type, entity_id, metadata, inserted_at)
- [x] 1.3 Update `Application` schema to include `reviewed` field
- [x] 1.4 Update `Application` changeset to cast `reviewed`
- [x] 1.5 Create `ActivityLog` schema in new `Treby.Activities` context

## 2. Activity Log Context

- [x] 2.1 Create `Treby.Activities` context module with `log_event/4`
- [x] 2.2 Add `list_events_for_entity/3` (entity_type, entity_id, limit)
- [x] 2.3 Instrument `Treby.Pipeline.move_application/3` to log `application_stage_changed`
- [x] 2.4 Instrument `Treby.Notes.create_note/2` to log `note_created`
- [x] 2.5 Instrument `Treby.Interviews.schedule_interview/2` to log `interview_scheduled`
- [x] 2.6 Instrument `Treby.Interviews.cancel_interview/2` to log `interview_cancelled`
- [x] 2.7 Instrument `Treby.Candidates.create_candidate/2` to log `candidate_created`
- [x] 2.8 Add `update_candidate/2` to `Treby.Candidates` context with activity logging

## 3. Candidate Search & Filtering

- [x] 3.1 Add `list_candidates/2` filter options to `Treby.Candidates` (search, job_id, stage)
- [x] 3.2 Add search query (ILIKE on name and email) to candidate listing
- [x] 3.3 Add job filter (join through applications) to candidate listing
- [x] 3.4 Add stage filter (join through applications) to candidate listing
- [x] 3.5 Update `CandidatesLive.Index` with search input and filter dropdowns
- [x] 3.6 Add `handle_event("search", ...)` and `handle_event("filter", ...)` handlers

## 4. Candidate Editing

- [x] 4.1 Add `update_candidate/2` to `Treby.Candidates` context
- [x] 4.2 Add edit mode toggle to `CandidatesLive.Show` (assign :editing?)
- [x] 4.3 Add inline edit form template with all fields + custom fields
- [x] 4.4 Add `handle_event("edit", ...)`, `handle_event("save_edit", ...)`, `handle_event("cancel_edit", ...)` handlers
- [x] 4.5 Add validation error display on the edit form

## 5. Application Review State

- [x] 5.1 Add `mark_reviewed/1` and `mark_unreviewed/1` to `Treby.Pipeline`
- [x] 5.2 Add `toggle_reviewed/1` to `Treby.Pipeline`
- [x] 5.3 Update `PipelineLive.Index` card template with "NEW" badge for unreviewed
- [x] 5.4 Add `handle_event("toggle_review", ...)` to `PipelineLive.Index`
- [x] 5.5 Add review state filter ("All" / "New only") to pipeline view
- [x] 5.6 Add `handle_event("filter_review", ...)` to `PipelineLive.Index`
- [x] 5.7 Ensure public application form sets `reviewed: false`

## 6. Dashboard

- [x] 6.1 Create `Treby.Dashboard` context with `get_dashboard_data/1`
- [x] 6.2 Implement `upcoming_interviews/2` (current user, next 7 days)
- [x] 6.3 Implement `stale_candidates/2` (tenant, threshold days)
- [x] 6.4 Implement `pipeline_snapshot/1` (per open job, counts per stage)
- [x] 6.5 Implement `weekly_stats/1` (applications, interviews, offers, hires this week)
- [x] 6.6 Rewrite `DashboardLive` to fetch and display all dashboard sections
- [x] 6.7 Build dashboard template: upcoming interviews, stale alerts, pipeline bars, weekly stats

## 7. Activity Timeline UI

- [x] 7.1 Create `ActivityTimeline` component in `core_components.ex`
- [x] 7.2 Display timeline on `CandidatesLive.Show` (20 most recent events)
- [x] 7.3 Format event descriptions (e.g., "moved from Screen to Interview")
- [x] 7.4 Show relative timestamps ("2 hours ago")

## 8. Cleanup & Verification

- [x] 8.1 Run `mix precommit` and fix any issues
- [x] 8.2 Test dashboard loads with correct data
- [x] 8.3 Test candidate search and filtering
- [x] 8.4 Test candidate editing with validation
- [x] 8.5 Test review toggle on pipeline board
- [x] 8.6 Test activity log entries appear on candidate profile
- [x] 8.7 Test combined filters (search + job + stage)
