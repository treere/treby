## MODIFIED Requirements

### Requirement: Create candidate
The system SHALL allow creating candidates with contact information. The system SHALL associate the candidate with the user's tenant.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin
- **THEN** a new candidate is created for the tenant

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)
