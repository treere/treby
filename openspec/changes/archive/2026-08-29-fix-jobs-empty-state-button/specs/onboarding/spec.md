## MODIFIED Requirements

### Requirement: Jobs page empty state
The system SHALL display a guided empty state on the jobs page when no jobs exist.

#### Scenario: No jobs exist
- **WHEN** a user visits the jobs page and the tenant has no job postings
- **THEN** an empty state is displayed with an icon, title ("No job postings yet"), a brief description explaining what job postings do, and a "Create your first job" button

#### Scenario: Create first job from empty state
- **WHEN** a user with no job postings clicks the "Create your first job" button on the jobs page empty state
- **THEN** the inline job creation form is revealed on the page so the user can create their first job