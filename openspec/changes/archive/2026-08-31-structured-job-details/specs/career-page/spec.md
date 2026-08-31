## MODIFIED Requirements

### Requirement: Job detail on career page
The system SHALL show job details on the career page including company branding and structured job metadata.

#### Scenario: Click job listing
- **WHEN** a visitor clicks on a job listing
- **THEN** the full job description, salary range, company logo, company name, company description, and "Apply" button are shown
- **AND** structured metadata (location, employment type, workplace type, salary, published date) is shown when present, with empty fields hidden

#### Scenario: Structured fields hidden when empty
- **WHEN** a job has no `location` or type fields set
- **THEN** the detail page does not render empty badges or placeholders for those fields

#### Scenario: Closed job detail
- **WHEN** a visitor navigates to a job detail page for a closed job
- **THEN** the page displays "This position is no longer available" with a link back to the career page
