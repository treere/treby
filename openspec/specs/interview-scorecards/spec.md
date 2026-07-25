# Interview Scorecards

## Purpose

Provide structured evaluation forms for interviews so teams make consistent, comparable hiring decisions instead of relying on free-text notes alone.

## Requirements

### Requirement: Define scorecard template
The system SHALL allow admins to define scorecard templates with named criteria.

#### Scenario: Create scorecard template
- **WHEN** an admin creates a scorecard template with criteria
- **THEN** the template is saved with a name and an ordered list of criteria
- **AND** each criterion has a name, type, and position

#### Scenario: Criterion types
- **WHEN** an admin creates a criterion
- **THEN** they can choose from the following types: `number_1_5` (1-5 star rating), `yes_no_maybe` (Yes/No/Maybe dropdown), `text` (free-text)

#### Scenario: Edit scorecard template
- **WHEN** an admin edits a scorecard template (add, remove, or reorder criteria)
- **THEN** the template is updated
- **AND** existing filled scorecards retain their original criteria structure

#### Scenario: Delete scorecard template
- **WHEN** an admin deletes a scorecard template
- **THEN** the template is removed
- **AND** existing filled scorecards are preserved

### Requirement: Fill out scorecard
The system SHALL allow interviewers to fill out a scorecard after an interview.

#### Scenario: Access scorecard form
- **WHEN** an interviewer navigates to a scheduled interview's scorecard
- **THEN** a form is displayed with all criteria from the active template

#### Scenario: Submit scorecard
- **WHEN** an interviewer fills in all required criteria and submits
- **THEN** the scorecard is saved with the interviewer's responses, recommendation, and notes
- **AND** the interview event is linked to the scorecard

#### Scenario: Edit existing scorecard
- **WHEN** an interviewer revisits a previously submitted scorecard
- **THEN** the form is pre-populated with their previous responses
- **AND** they can update and re-submit

#### Scenario: One scorecard per interviewer per interview
- **WHEN** an interviewer submits a scorecard for an interview they already scored
- **THEN** the existing scorecard is updated (upsert), not duplicated

### Requirement: Scorecard recommendation
The system SHALL include a recommendation field on scorecards.

#### Scenario: Submit recommendation
- **WHEN** an interviewer fills out a scorecard
- **THEN** they can select a recommendation: "Strong Hire", "Hire", "Lean No", "No Hire", or "Strong No Hire"
- **AND** the recommendation is saved with the scorecard

### Requirement: View scorecards
The system SHALL display scorecards on the interview and candidate profile pages.

#### Scenario: Scorecard on interview detail
- **WHEN** a user views a scheduled interview
- **THEN** the scorecard status (pending/completed) is shown
- **AND** if completed, the scores, recommendation, and notes are displayed

#### Scenario: Scorecard summary on candidate profile
- **WHEN** a user views a candidate profile
- **THEN** all completed scorecards for that candidate are listed with interviewer name, date, scores, and recommendation

#### Scenario: Aggregate scores
- **WHEN** a candidate has multiple completed scorecards
- **THEN** the candidate profile shows an aggregate view (average scores per criterion, count of recommendations)

### Requirement: Scorecard visibility
The system SHALL make scorecards visible to all team members in the same tenant.

#### Scenario: Cross-user scorecard visibility
- **WHEN** Interviewer A fills out a scorecard
- **THEN** Interviewer B (same tenant) can view the scorecard results
