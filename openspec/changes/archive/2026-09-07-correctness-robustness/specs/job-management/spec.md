## ADDED Requirements

### Requirement: Visible requires open status
A job posting SHALL NOT be markable visible while its status is closed; attempting to set `visible=true` on a closed job SHALL fail changeset validation.

#### Scenario: Publish a closed job
- **WHEN** a user sets visible on a job whose status is closed
- **THEN** validation fails with an error on visibility

#### Scenario: Open job stays publishable
- **WHEN** a user sets visible on a job whose status is open
- **THEN** validation passes
