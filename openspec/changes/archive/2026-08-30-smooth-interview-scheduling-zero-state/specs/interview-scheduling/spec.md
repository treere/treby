## MODIFIED Requirements

### Requirement: Schedule interview
The system SHALL allow scheduling an interview for an application. When availability rules exist, the system SHALL show overlapping slots; when none exist, the system SHALL allow ad-hoc scheduling.

#### Scenario: Schedule with availability
- **WHEN** an examiner has availability rules and a user schedules an interview
- **THEN** the system shows available overlapping slots and allows booking

#### Scenario: Schedule without availability (zero-state)
- **WHEN** no examiner has availability rules and a user opens the schedule page
- **THEN** the system shows an ad-hoc datetime picker and examiner selector
- **AND** the user can schedule the interview at the chosen time

#### Scenario: Pipeline schedule CTA in zero-state
- **WHEN** a candidate is in Interview stage with no interview scheduled and no availability exists
- **THEN** the pipeline card shows a "Schedule interview" button linking to the schedule page
