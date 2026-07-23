## 1. Database & Schema — RBAC

- [ ] 1.1 Create `TrebyWeb.Hooks.RequireRole` LiveView `on_mount` hook that checks `current_user.role` against required role
- [ ] 1.2 Apply `:require_role` hook to all settings LiveViews (admin-only)
- [ ] 1.3 Add role check to `Treby.Accounts.invite_member/2` (admin-only)
- [ ] 1.4 Add role check to `Treby.Accounts.remove_user_from_tenant/2` (admin-only)
- [ ] 1.5 Add role check to `Treby.Pipeline` stage CRUD functions (admin-only)
- [ ] 1.6 Add role check to `Treby.Customization` field CRUD functions (admin-only)
- [ ] 1.7 Add role check to `Treby.Candidates.delete_candidate/2` (admin-only)
- [ ] 1.8 Show/hide admin-only UI elements (settings links, delete buttons, invite forms) based on role
- [ ] 1.9 Add "permission denied" flash message for unauthorized access attempts

## 2. Database & Schema — Scorecards

- [ ] 2.1 Create migration to create `scorecard_templates` table (id, name, criteria JSON, position, tenant_id)
- [ ] 2.2 Create migration to create `scorecards` table (id, scores JSON, recommendation, notes, interview_event_id, interviewer_id, tenant_id, inserted_at, updated_at)
- [ ] 2.3 Create `ScorecardTemplate` schema with changeset (cast name, criteria, position)
- [ ] 2.4 Create `Scorecard` schema with changeset (cast scores, recommendation, notes)
- [ ] 2.5 Add unique constraint on `(interview_event_id, interviewer_id)` in `scorecards`

## 3. Database & Schema — Email Templates

- [ ] 3.1 Create migration to create `email_templates` table (id, name, stage_type, subject, body, tenant_id)
- [ ] 3.2 Add unique constraint on `(stage_type, tenant_id)` in `email_templates`
- [ ] 3.3 Create `EmailTemplate` schema with changeset (cast name, stage_type, subject, body)

## 4. Context — Scorecards

- [ ] 4.1 Create `Treby.Scorecards` context module
- [ ] 4.2 Implement `list_scorecard_templates/1` (by tenant)
- [ ] 4.3 Implement `create_scorecard_template/2` with criteria validation
- [ ] 4.4 Implement `update_scorecard_template/2`
- [ ] 4.5 Implement `delete_scorecard_template/1`
- [ ] 4.6 Implement `get_active_template/1` (returns the tenant's current template)
- [ ] 4.7 Implement `submit_scorecard/3` (interview_event_id, interviewer_id, params) with upsert
- [ ] 4.8 Implement `get_scorecard_for_interview/2` (interview_event_id, interviewer_id)
- [ ] 4.9 Implement `list_scorecards_for_candidate/1` (by candidate, across all interviews)
- [ ] 4.10 Implement `compute_aggregate_scores/1` (average per criterion, recommendation counts)

## 5. Context — Email Templates

- [ ] 5.1 Create `Treby.EmailTemplates` context module
- [ ] 5.2 Implement `list_email_templates/1` (by tenant)
- [ ] 5.3 Implement `get_email_template_for_stage/2` (tenant_id, stage_type)
- [ ] 5.4 Implement `upsert_email_template/2` (create or replace by stage_type)
- [ ] 5.5 Implement `delete_email_template/1`
- [ ] 5.6 Implement `render_email/2` (template, assigns map) — simple string variable interpolation
- [ ] 5.7 Implement `send_stage_email/3` (template, candidate, job) via Swoosh

## 6. Context — Analytics Enhancements

- [ ] 6.1 Refactor `Treby.Pipeline` analytics queries to accept optional `pipeline_id` parameter
- [ ] 6.2 Implement `time_in_stage_metrics/2` (tenant_id, pipeline_id) — compute from activity_log stage changes
- [ ] 6.3 Implement `per_pipeline_conversion_rates/2` (tenant_id, pipeline_id)
- [ ] 6.4 Implement `list_pipelines/1` (for analytics dropdown)

## 7. LiveViews — Scorecard Settings

- [ ] 7.1 Create `SettingsLive.Scorecards` LiveView with template list and create/edit form
- [ ] 7.2 Build template editor UI: name input, criteria list with add/remove/reorder
- [ ] 7.3 Each criterion row: name input, type dropdown (number_1_5, yes_no_maybe, text), position
- [ ] 7.4 Add `handle_event` handlers for CRUD operations and criteria management
- [ ] 7.5 Add route `/app/settings/scorecards` to router

## 8. LiveViews — Email Template Settings

- [ ] 8.1 Create `SettingsLive.EmailTemplates` LiveView with template list and create/edit form
- [ ] 8.2 Build template editor UI: name, stage type dropdown, subject, body textarea
- [ ] 8.3 Add live preview panel showing rendered template with sample variables
- [ ] 8.4 Add `handle_event` handlers for CRUD operations
- [ ] 8.5 Add route `/app/settings/emails` to router

## 9. LiveViews — Scorecard Filling

- [ ] 9.1 Add scorecard section to `InterviewsLive.Index` showing pending/completed status per interview
- [ ] 9.2 Create scorecard form view (inline or modal) with dynamic criteria from active template
- [ ] 9.3 Each criterion renders appropriate input: star rating for number_1_5, dropdown for yes_no_maybe, textarea for text
- [ ] 9.4 Add recommendation dropdown (Strong Hire, Hire, Lean No, No Hire, Strong No Hire)
- [ ] 9.5 Add notes textarea
- [ ] 9.6 Add `handle_event("submit_scorecard", ...)` handler

## 10. LiveViews — Scorecard Display

- [ ] 10.1 Show scorecard summary on `CandidatesLive.Show` (all scorecards for the candidate)
- [ ] 10.2 Show individual scorecard detail (scores, recommendation, notes, interviewer)
- [ ] 10.3 Show aggregate view: average scores per criterion, recommendation distribution

## 11. LiveViews — Email on Stage Move

- [ ] 11.1 Modify `PipelineLive.Index` `handle_event("move_candidate", ...)` to check for email template
- [ ] 11.2 Show confirmation dialog with email preview when template exists
- [ ] 11.3 Add `handle_event("confirm_stage_move", ...)` with send/skip options
- [ ] 11.4 Call `EmailTemplates.send_stage_email/3` on send, skip on skip
- [ ] 11.5 Move candidate to new stage in both cases

## 12. LiveViews — Analytics Enhancement

- [ ] 12.1 Add pipeline dropdown to `AnalyticsLive.Index`
- [ ] 12.2 Add `handle_event("select_pipeline", ...)` to reload analytics data
- [ ] 12.3 Refactor analytics queries to use pipeline_id parameter
- [ ] 12.4 Add time-in-stage section to analytics page (bar chart or table)
- [ ] 12.5 Highlight bottleneck stages (above-average time)

## 13. Router & Navigation

- [ ] 13.1 Add `/app/settings/scorecards` route
- [ ] 13.2 Add `/app/settings/emails` route
- [ ] 13.3 Update settings hub page with links to new settings pages
- [ ] 13.4 Update settings nav to show/hide based on role

## 14. Cleanup & Verification

- [ ] 14.1 Run `mix precommit` and fix any issues
- [ ] 14.2 Test RBAC: member cannot access settings, invite, delete candidates
- [ ] 14.3 Test RBAC: admin can access all settings and perform admin actions
- [ ] 14.4 Test scorecard template CRUD
- [ ] 14.5 Test scorecard submission (upsert behavior)
- [ ] 14.6 Test scorecard display on candidate profile with aggregate
- [ ] 14.7 Test email template CRUD with preview
- [ ] 14.8 Test stage move with email confirmation dialog
- [ ] 14.9 Test email sending on stage move
- [ ] 14.10 Test analytics pipeline selector and time-in-stage metrics
