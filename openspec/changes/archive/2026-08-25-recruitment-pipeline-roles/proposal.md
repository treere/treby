## Why

The pipeline currently has no concept of roles per stage — anyone can do anything, and interviews are scheduled with a single interviewer. This limits structured hiring workflows where different people have different responsibilities (who interviews, who reviews, who advances) and where interview panels require multiple examiners in the same call. Templates are also missing: teams opening similar positions (Junior/Mid/Senior Engineer) must manually recreate pipeline configurations each time.

## What Changes

- **Pipeline templates**: Define reusable pipeline configurations (stages, roles, scorecard templates) that can be cloned when creating new job openings, then customized per job.
- **Stage roles**: Each pipeline stage can have assigned **examiners** (conduct interviews, give feedback via scorecard), **reviewers** (review applications), and **advancers** (manually advance or reject candidates). Roles are per-stage and per-pipeline.
- **Multi-examiner interviews**: Interview events support multiple examiners attending the same call. Each examiner fills out their own scorecard. A stage can require a minimum number of examiners (`min_examiners`).
- **Availability-based scheduling**: When computing available slots for interview stages, the system finds time windows where at least `min_examiners` eligible examiners are all available (overlapping calendar + availability rules). Candidates self-scheduling see only these overlapping slots.
- **Advancement rules**: For interview stages, advancement is only allowed after all examiners have submitted their scorecards. Advancement is manual (any assigned advancer can do it). Rejection requires a motivation.
- **Examiner substitution**: When a confirmed examiner cancels, the system searches for a substitute from the eligible examiner pool for that stage.

## Capabilities

### New Capabilities
- `pipeline-templates`: Create, manage, and clone pipeline templates when opening new positions. Templates define stages, role assignments, and scorecard template associations.
- `pipeline-stage-roles`: Assign examiners, reviewers, and advancers to specific pipeline stages. Configure minimum examiner requirements for interview stages.

### Modified Capabilities
- `pipeline`: Advancement logic changes — interview stages require all examiners to have submitted scorecards before any advancer can advance the candidate. Rejection requires a motivation field.
- `pipeline-config`: Stage editor gains new fields: `min_examiners` (for interview stages), examiner/reviewer/advancer assignment UI.
- `interview-scheduling`: Support scheduling events with multiple examiners. Compute available slots based on overlapping availability across eligible examiners. Create calendar events for all examiners.
- `interview-scorecards`: Scorecards become per-examiner per-event (one scorecard per interviewer in a multi-examiner event). Scorecard template is linked to the pipeline stage.
- `candidate-self-scheduling`: Booking page shows only slots where at least `min_examiners` eligible examiners are available. Booking token links to the stage's examiner pool rather than a single interviewer.
- `role-based-access`: Stage role assignments (examiner/reviewer/advancer) are a new layer on top of existing admin/member permissions. Only admins can configure stage roles.

## Impact

- **Database**: New tables (`pipeline_templates`, `pipeline_stage_examiners`, `pipeline_stage_reviewers`, `pipeline_stage_advancers`, `interview_event_examiners`). Modified `pipeline_stages` (add `min_examiners`). Modified `interview_events` (remove single `interviewer_id`, add relationship through junction table). Modified `scorecards` (link to event + specific examiner).
- **Scheduling engine**: Major rewrite of availability computation to support intersection of multiple examiners' calendars.
- **Self-scheduling**: Booking flow changes from single-interviewer to multi-examiner slot selection.
- **Pipeline UI**: Kanban board and stage configuration gain role assignment panels.
- **Scorecard UI**: Interview detail page shows scorecards per examiner with completion status.
- **Templates**: New settings section for template management, new "create from template" flow in job creation.
