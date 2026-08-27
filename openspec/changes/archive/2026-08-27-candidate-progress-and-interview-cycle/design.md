## Context

Failure of discovery. After an application enters the pipeline, the state and the required next actions are scattered across `PipelineStage`, `InterviewEvent`/`EventExaminer`, `Scorecard`, and conversations. Today:

- `Interviews.schedule_interview/1` moves the application to the interview stage and relies on `Pipeline.all_scorecards_completed?/1` to gate advancement — but nothing ever marks the event as `completed`, and scorecards are only fillable from `/app/interviews`.
- The advance gate exists but is opaque: the pipeline card shows "X/Y scorecards" but not *who* is missing or *what to do about it*.
- Candidates see only a stage badge and a status timeline, not what happens next.

The proposal is deliberately **non-automated**: assemble a transparent, explicit view and an explicit completion step. One extra click is acceptable; ambiguity is not.

## Goals / Non-Goals

**Goals:**
- Produce a single, fresh `current_state/1` view of any application: stage, blocked?, blockers (who/what), next actions, and progress — assembled from existing data.
- Add an explicit "complete interview" step that transitions the event `scheduled → completed`.
- Surface scorecard completion as visible, actionable blockers for advancers/recruiters, and as contextual in-place prompts for examiners.
- Give candidates a clear, well-phrased progress/next-step panel in the portal.
- Keep everything manual and explicit; zero new automation/AI.

**Non-Goals:**
- No auto-advance, no auto-completion, no AI ranking/matching.
- No new schema migrations (existing `status` field and scorecard data suffice; any metadata is additive and optional).
- No changes to how interviews are *scheduled* or *cancelled* (already covered by `interview-scheduling`).
- No redesign of the candidate detail page as a whole — we add a progress panel, not a rebuild of the 1500-line hub.

## Decisions

### D1. `current_state/1` is computed on the fly, not stored
`Treby.Pipeline.current_state(application)` returns a plain map:
```
%{
  stage:        %PipelineStage{},
  blocked?:     true,
  blockers:     [
    %{kind: :interview_not_completed, assignee: nil, label: "Interview not yet completed"},
    %{kind: :scorecard_pending, assignee: %{user_id, name}, label: "Caio: scorecard mancante"}
  ],
  next_actions: [ %{kind: :complete_interview, assignee: ...}, %{kind: :submit_scorecard, assignee: ...} ],
  progress:     %{scorecards: %{completed: 2, total: 3}, interviews: %{scheduled: 1, completed: 0}}
}
```
- **Rationale:** single source of truth, always fresh, cannot drift from the underlying truth. No migration, no sync jobs.
- **Alternative considered:** denormalizing progress onto `applications`. **Rejected** — adds write paths and drift risk for zero user benefit at this scale.

### D2. Interview completion is an explicit event (never inferred)
Add `Treby.Interviews.complete_interview(event)` that sets `status: "completed"`; the action is available after `scheduled`. It is surfaced on the pipeline card, candidate detail, and interviews page for examiners/advancers/recruiters.
- **Rationale:** matches the explicit, "one more click but clear" principle. A real person confirms the interview happened.
- **Alternative considered:** treat "all scorecards submitted" as implicit completion. **Rejected** — user explicitly wants clarity over zero clicks.
- **Guardrail:** completion is a prerequisite for advancing from an interview stage, but is *not* itself advancement; the advancer still advances explicitly.

### D3. Keep the existing gate, make it transparent
`all_scorecards_completed?/1` stays as the final gate, but the UI now renders `current_state.blockers` instead of an opaque count. For non-interview stages, a new generic "no blockers / ready to advance" state replaces silent behavior.
- **Rationale:** minimal change to the domain logic that already works; the win is *visibility*, not new gate semantics.

### D4. Scorecards are submitable contextually
Reuse `Scorecards.submit_scorecard/3` (upsert, already supports edit) behind a shared scorecard form component, rendered from the pipeline card, candidate detail, and interviews page — not only `/app/interviews`.
- **Rationale:** removes the "hunt for the scorecard page" friction identified in discovery.
- **Alternative considered:** a modal deep-linking to `/app/interviews`. **Rejected** — same jumps, worse UX; the form is reusable cheaply.

### D5. Candidate progress is a projection of the same state
When building the candidate portal view, map `current_state` to candidate-safe phrasing (drop internal roles/labels, use clear sentences, and only show "pending on you" when the candidate actually must act — e.g. replying to a request for info).
- **Rationale:** reuse one model, two renderings; keeps the candidate view honest (no fabricated "next step" when it's an internal action).

## Risks / Trade-offs

- **[Stale/ambiguous "complete interview" if someone forgets]** → Mitigation: it is just one explicit action; if left undone, the blockers view *names it* ("interview not yet completed"), so the gap stays visible rather than silent.
- **[No status field on the event for who/when completed]** → Mitigation: acceptable for now; can add optional metadata later without breaking this design.
- **[Multiple examiners, one event]**: completion is per-event; individual scorecard blockers remain per-examiner. → Mitigation: `current_state` keeps this distinction explicit (event-level vs examiner-level blockers).
- **[Scope creep into the candidate detail hub]** → Mitigation: Non-Goal — add a panel, do not rebuild the page.

## Migration Plan

No data migration required. Deploy is additive:
1. Add `current_state/1` and `complete_interview/1` (no schema change).
2. Roll out the scorecard form component + pipeline-card/detail blockers UI.
3. Add the candidate portal progress panel.
Rollback: remove the UI affordances and new functions; existing events/scorecards are unaffected.

## Open Questions / Resolved Decisions

- **"Complete interview" confirmation:** RESOLVED — the "Mark as completed" action shows a confirmation dialog before applying. The extra click is the confirm, keeping the action explicit and reversible-in-intent.
- **Scorecard nudge after completion:** RESOLVED — reminders are in-app only (the contextual scorecard prompt + blocker naming); no automatic notification emails are sent on completion. Any email sent manually via the existing stage-email-template flow should simply state that there are updates waiting in the app, rather than recapping internal details such as pending examiners.

