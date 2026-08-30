## MODIFIED Requirements

### Requirement: Fill out scorecard
The system SHALL allow interviewers to fill out a scorecard after an interview. In multi-examiner events, each examiner fills out their own independent scorecard. When no active scorecard template exists for the tenant, the system SHALL not crash and SHALL guide the user to create one.

#### Scenario: Access scorecard form
- **WHEN** an interviewer navigates to a scheduled interview's scorecard
- **THEN** a form is displayed with all criteria from the scorecard template associated with the pipeline stage

#### Scenario: Access scorecard with no template does not crash
- **WHEN** an interviewer clicks "Scorecard" for an interview and no active scorecard template exists for the tenant
- **THEN** the system does not raise an error
- **AND** the system shows a message explaining that no scorecard template is configured and directs the user to Settings → Scorecards
- **AND** the Scorecard button on the board is disabled with a tooltip indicating no template is configured

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
