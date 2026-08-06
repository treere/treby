## MODIFIED Requirements

### Requirement: Copy public link
The system SHALL provide a way to copy the public job URL from the internal job detail page.

#### Scenario: Copy link button exists
- **WHEN** a user views the internal job detail page (`/app/jobs/:id`)
- **THEN** a "Copy Public Link" button is visible

#### Scenario: Copy link action
- **WHEN** a user clicks "Copy Public Link"
- **THEN** the full absolute public URL (`https://<host>/:tenant_slug/careers/:job_id`) is copied to the clipboard, including the hostname
- **AND** a confirmation message is shown
