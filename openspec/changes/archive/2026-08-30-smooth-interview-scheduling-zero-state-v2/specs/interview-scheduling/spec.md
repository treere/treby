## ADDED Requirements

### Requirement: Ad-hoc interview scheduling without availability

The system SHALL allow scheduling an interview ad-hoc when no availability rules exist, without requiring recurring rules.

#### Scenario: Zero-state shows ad-hoc picker

- **WHEN** a user navigates to `Schedule Interview` for an application and no team members have availability
- **THEN** the page shows `No team members have set their availability yet.` plus an ad-hoc form with date, time, and examiner select
- **AND** a helper link `Set weekly availability → Settings → Availability` is shown

#### Scenario: Book ad-hoc interview

- **WHEN** the user selects a date, time, and examiner in the ad-hoc form and clicks `Book Interview`
- **THEN** an `InterviewEvent` is created with `start_at_utc` from the inputs and `duration_minutes: 30`
- **AND** the candidate is moved to the Interview stage
