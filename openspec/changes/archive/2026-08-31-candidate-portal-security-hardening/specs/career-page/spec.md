## MODIFIED Requirements

### Requirement: Application form
The system SHALL provide an application form for each job and SHALL inform the candidate if they have already applied.

#### Scenario: Submit duplicate application
- **WHEN** a candidate submits an application for a job they have already applied to (same email normalized, same job)
- **THEN** the system does not create a duplicate application (or marks it duplicate internally)
- **AND** the UI shows "You have already applied to this position on {date}" with a link to `/:tenant_slug/portal` and to "View other positions"
- **AND** it does not show a generic "Thank you" as if it were a new submission

#### Scenario: Submit new application
- **WHEN** a candidate submits for a job they have not applied to before
- **THEN** a new application is created and the thank-you confirmation is shown as before
