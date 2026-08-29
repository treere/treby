# Scorecards

Structured interview evaluation — templates with criteria, per-examiner submission, and advancement gating.

## Templates

Admins configure templates in **Settings → Scorecards** (`lib/treby_web/live/settings_live/scorecards.ex`, `lib/treby/scorecards/scorecard_template.ex`):

- Each template has an ordered list of **criteria** (e.g. "Technical depth", "Communication", "Culture fit") with optional descriptions
- Templates are tenant-scoped and ordered by `position`
- `stage_type = "interview"` stages can be linked to a template (`scorecard_template_id` on `pipeline_stage`)

See `lib/treby/scorecards/` for the context and schemas.

## Filling a scorecard

- Interview events have `EventExaminers` (`lib/treby/interviews/event_examiner.ex`); only assigned examiners can submit
- Scorecards are per `(interview_event_id, interviewer_id)` — `Scorecard` (`lib/treby/scorecards/scorecard.ex`)
- The shared form component `TrebyWeb.Components.ScorecardForm` is reused on:
  - the candidate card (pipeline/job page),
  - the candidate detail page progress panel,
  - the dashboard **My Actions → Fill scorecard** button,
  - the interviews dashboard
- Submitted scorecards can be edited by the same examiner

## Gating

For `stage_type = "interview"` stages, advancement is **gated** on both:

1. the interview being marked **completed** (explicit confirmation dialog, `InterviewEvent.status = "completed"`), and
2. **all** examiners' scorecards being submitted

Implemented in `lib/treby/pipeline/pipeline.ex:435` (`all_scorecards_completed?`, `ready_to_advance?`, `current_state/1`). Until both conditions are met:

- the pipeline card shows actionable blockers ("Scorecard missing: Caio", "Interview not yet completed") instead of an opaque count,
- the **Advance** button (and drag-and-drop into next stage) is disabled for non-advancers / incomplete scorecards

See also [Kanban Pipeline](/features/pipeline) for the full gating + rejection flow.

## Dashboard integration

- **My Actions → Scorecards to fill** lists your pending scorecards with a direct **Fill scorecard** button (`lib/treby/dashboard.ex:32`)
- **Waiting on others** shows applications blocked by other examiners' missing scorecards
