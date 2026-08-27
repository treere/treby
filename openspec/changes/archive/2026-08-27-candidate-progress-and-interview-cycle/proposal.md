## Why

After a candidate enters the pipeline, both the team that decides and the candidate lack a single, clear view of *where things stand and what must happen next*. The most painful moment — after an interview — is the most fragmented: there is no explicit "interview completed" step, scorecards are filled from a separate page, and advancement stays blocked on invisible, actionable blockers. The goal is to make the manual flow linear and explicit, not automatic: one more click is fine, as long as the state and the next action are crystal clear.

## What Changes

- Introduce a **shared "candidate progress" state** for any application: current stage, whether advancement is blocked, what is blocking it (and who must act), and the concrete next actions. Assembled from data that already exists (stage, `event_examiners`, scorecards, `min_examiners`), not new automation.
- Add an **explicit interview completion step**: an interviewer or recruiter marks a scheduled interview as *completed* with one explicit action, instead of the system silently waiting for scorecards.
- Add a **contextual scorecard invitation**: after an interview completes, the examiners who still must provide feedback get a clear, in-place prompt to fill their scorecard (no hunting through `/app/interviews`).
- Surface **blockers as actionable next-steps** for advancers/recruiters: the pipeline card and candidate detail show exactly who has not done what (e.g. "Caio: scorecard mancante"), instead of an opaque "X/Y scorecards".
- Add a **candidate-facing progress view** in the candidate portal: instead of only a stage badge, the candidate sees their current step, what is pending from them (if anything), and what happens next — phrased clearly and non-internally.

## Capabilities

### New Capabilities

- `candidate-progress`: The `current_state/1` view for an application — current stage, blockers, next actions — and how it is surfaced to the team (pipeline cards, candidate detail). No new automation; purely an assembled, transparent view.
- `interview-completion`: The explicit lifecycle step that closes a scheduled interview (status `scheduled` → `completed`), triggers the contextual scorecard invitation, and is the prerequisite for advancing from an interview stage.

### Modified Capabilities

- `candidate-portal-dashboard`: Extend the application detail view so a candidate sees not just their stage badge and status timeline, but a clear "where you are / what's next" progress panel (candidate-appropriate phrasing, without internal blocker language).

## Impact

- **Code**: `Treby.Pipeline` (advance-blocking logic, new `current_state`), `Treby.Interviews` (completion action), `Treby.Scorecards` (contextual submission flow), and the relevant LiveViews: `PipelineLive.Index`, `CandidatesLive.Show`, `InterviewsLive.Index`, `SchedulingLive.Booking`, `CandidatePortalLive.Index`/`MessageThread`.
- **Schema**: `interview_events.status` already supports `"completed"`; no migration strictly required unless we add richer fields (e.g. completion metadata / timestamps).
- **Specs**: new `candidate-progress`, new `interview-completion`, modified `candidate-portal-dashboard`.
- **No new dependencies, no automation, no AI.**
- **Not breaking** existing data; purely additive behavior on top of current stage/event/scorecard data.
