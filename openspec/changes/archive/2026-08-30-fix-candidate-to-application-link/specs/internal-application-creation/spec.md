## ADDED Requirements

### Requirement: Internal application creation
The system SHALL allow an authenticated user to create an Application linking a candidate to a job from inside the authenticated app, without using the public career page.

#### Scenario: Add candidate with job in one action
- **WHEN** a user submits the Add Candidate modal with name, email, and a selected job
- **THEN** a candidate is created (or reused via email dedup) for the tenant
- **AND** an Application is created linking that candidate to the selected job in the job's first pipeline stage

#### Scenario: Add existing candidate to job from profile
- **WHEN** a user clicks Add to Job on a candidate profile that has no application for a chosen job and selects a job
- **THEN** an Application is created for that candidate and job in the first stage

#### Scenario: Add existing candidate from job or pipeline empty state
- **WHEN** a user picks an existing tenant candidate from the Jobs or Pipeline empty-state picker
- **THEN** an Application is created for that job and candidate in the first stage

#### Scenario: Duplicate handling
- **WHEN** a user adds a candidate who already has an Application for the selected job
- **THEN** a second Application is created and flagged as `is_duplicate = true`
