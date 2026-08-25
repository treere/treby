# Interview Scorecards (delta)

## MODIFIED Requirements

### Requirement: Fill out scorecard
The system SHALL allow interviewers to fill out a scorecard after an interview. In multi-examiner events, each examiner fills out their own independent scorecard.

#### Scenario: Access scorecard form
- **WHEN** an interviewer navigates to a scheduled interview's scorecard
- **THEN** a form is displayed with all criteria from the scorecard template associated with the pipeline stage

#### Scenario: Submit scorecard (multi-examiner)
- **WHEN** an examiner fills in all required criteria and submits
- **THEN** a scorecard record is created linked to the interview event AND the specific examiner
- **AND** other examiners for the same event can simultaneously fill out their own scorecards

#### Scenario: Edit existing scorecard
- **WHEN** an interviewer revisits a previously submitted scorecard
- **THEN** the form is pre-populated with their previous responses
- **AND** they can update and re-submit

#### Scenario: One scorecard per examiner per interview
- **WHEN** an examiner submits a scorecard for an interview they already scored
- **THEN** the existing scorecard is updated (upsert), not duplicated
- **AND** each examiner has exactly one scorecard per interview event

### Requirement: View scorecards
The system SHALL display scorecards on the interview and candidate profile pages, showing per-examiner results for multi-examiner events.

#### Scenario: Scorecard on interview detail
- **WHEN** a user views a scheduled interview
- **THEN** each examiner's scorecard status (pending/completed) is shown
- **AND** if completed, the scores, recommendation, and notes for each examiner are displayed

#### Scenario: Scorecard summary on candidate profile
- **WHEN** a user views a candidate profile
- **THEN** all completed scorecards for that candidate are listed with interviewer name, date, scores, and recommendation
- **AND** for multi-examiner events, scorecards are grouped by event

#### Scenario: Aggregate scores
- **WHEN** a candidate has multiple completed scorecards
- **THEN** the candidate profile shows an aggregate view (average scores per criterion, count of recommendations)

### Requirement: Scorecard recommendation
The system SHALL include a recommendation field on scorecards.

#### Scenario: Submit recommendation
- **WHEN** an interviewer fills out a scorecard
- **THEN** they can select a recommendation: "Strong Hire", "Hire", "Lean No", "No Hire", or "Strong No Hire"
- **AND** the recommendation is saved with the scorecard

## ADDED Requirements

### Requirement: Scorecard completion tracking per event
The system SHALL track scorecard completion status for each examiner in a multi-examiner event.

#### Scenario: View completion status
- **WHEN** a user views a multi-examiner interview event
- **THEN** a list of all examiners is shown with their scorecard status (completed/pending)
- **AND** a count of completed vs total scorecards is displayed (e.g., "2/3 completed")

#### Scenario: All scorecards completed
- **WHEN** all examiners for a multi-examiner event have submitted their scorecards
- **THEN** the event is marked as fully scored
- **AND** the advancement to the next stage becomes available (subject to advancer approval)
