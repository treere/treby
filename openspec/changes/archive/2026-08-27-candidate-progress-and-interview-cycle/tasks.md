## 1. Progress state backbone

- [x] 1.1 Add `Treby.Pipeline.current_state(application)` returning `%{stage, blocked?, blockers, next_actions, progress}` computed from stage, interview events, event examiners, scorecards, and min_examiners
- [x] 1.2 Add unit tests for `current_state/1` covering: non-interview no-blocker, interview with uncompleted event, interview completed with missing scorecards (per-examiner blockers), interview fully resolved, and progress counts

## 2. Interview completion

- [x] 2.1 Add `Treby.Interviews.complete_interview(event)` that sets status "scheduled" → "completed" (no application move)
- [x] 2.2 Add `handle_event("complete_interview", ...)` and a "Mark as completed" affordance with a confirmation dialog on the pipeline card for interview-stage applications
- [x] 2.3 Add the complete-interview action (with confirmation dialog) on the candidate detail page
- [x] 2.4 Add the complete-interview action (with confirmation dialog) on the interviews page
- [x] 2.5 Guard `Pipeline.all_scorecards_completed?/1` / advancement so a non-completed interview also blocks advancement (interview-not-completed blocker)
- [x] 2.6 Add tests for completion action, prerequisite blocking, and that completion does not advance the application

## 3. Contextual scorecard form

- [x] 3.1 Extract the scorecard form (criteria scoring, recommendation, notes) currently in `InterviewsLive.Index` into a reusable component backed by `Scorecards.submit_scorecard/3`
- [x] 3.2 Render the scorecard form in place for examiners on the pipeline card (after the interview is completed) and allow editing an existing scorecard
- [x] 3.2b Confirm no automatic notification email is sent on interview completion; any email sent via the existing stage-email-template flow states only that updates are waiting in the app
- [x] 3.3 Render the scorecard prompt/form on the candidate detail page for the current examiner (if pending or editable)
- [x] 3.4 Confirm the interviews page continues to work using the shared component

## 4. Surface blockers and next actions to the team

- [x] 4.1 Replace the opaque "X/Y scorecards" on the pipeline card with the render of `current_state.blockers` (named pending examiners, interview-not-completed)
- [x] 4.2 Show a "ready to advance" indicator on the card when `blocked? == false` for an advancer
- [x] 4.3 Add a progress panel (stage, blockers, next actions with assignees) to the candidate detail page

## 5. Candidate portal progress

- [x] 5.1 Map `current_state` to candidate-safe phrasing in `CandidatePortalLive.Index` / detail rendering
- [x] 5.2 Add the progress panel to the application detail view, highlighting a pending action on the candidate (e.g. reply to info request, choose slot) with a link to complete it
- [x] 5.3 Ensure internal roles/blockers are not revealed to candidates

## 6. Verification

- [x] 6.1 Run `mix test` and fix failures
- [x] 6.2 Run `mix precommit` and resolve any issues
- [x] 6.3 Regenerate documentation screenshots (`node scripts/screenshots.mjs`) and update the relevant `site/features/` page(s) if UI visibly changed
