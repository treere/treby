# Scorecards

Structured evaluations for interviews: templates with criteria, per-examiner completion, and advancement gating until all scorecards are in.

![Settings — Scorecard Templates](/screenshots/33-settings-scorecards.png)

## Templates

Admins configure templates in **Settings → Scorecards**:

- Each template has an ordered list of **criteria** (e.g., "Technical Depth", "Communication", "Culture Fit") with an optional description
- Interview-type stages can be linked to a template

## Completing Scorecards

- Only examiners assigned to the stage can submit the scorecard for that interview
- Each interview has one scorecard per examiner
- The same form is available in multiple places: the candidate card in the pipeline, the profile panel, the **Fill scorecard** button on the dashboard and on the interviews page
- A submitted scorecard can be edited by the same examiner

## Advancement Gating

In interview stages, advancing requires both conditions:

1. the interview marked as **completed** (with confirmation), and
2. **all** examiner scorecards submitted

While something is missing:

- the card shows blockers ("Missing scorecard: John", "Interview not yet completed")
- the **Advance** button (and drag & drop to the next stage) stays disabled for non-advancers or when scorecards are incomplete

See also [Kanban Pipeline](/features/pipeline) for the full advancement and rejection flow.

## Interviews Dashboard

![Interviews Dashboard](/screenshots/34-interviews-dashboard.png)

Track every upcoming interview, scorecard completion, and direct action to mark interviews complete or submit a scorecard.

## Dashboard Link

- **My Actions → Scorecards to fill** lists interviews where you are an examiner with a direct button to fill the scorecard
- **Waiting on others** shows applications blocked because other examiners still have outstanding scorecards
