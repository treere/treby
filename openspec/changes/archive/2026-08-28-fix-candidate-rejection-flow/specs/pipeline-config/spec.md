# Pipeline Configuration

## Delta

## MODIFIED Requirements

### Requirement: Default pipeline
The system SHALL designate exactly one pipeline as the default per tenant. The default pipeline SHALL include a terminal stage with `stage_type = "rejected"`.

#### Scenario: Set default pipeline
- **WHEN** an admin sets a pipeline as default
- **THEN** the previous default pipeline loses its default status
- **AND** the new default is indicated in the pipeline list

#### Scenario: New jobs use default pipeline
- **WHEN** a job is created without specifying a pipeline
- **THEN** the job uses the tenant's default pipeline

#### Scenario: Rejected stage in default pipeline
- **WHEN** a tenant is created or an existing default pipeline lacks a rejected-type stage
- **THEN** the default pipeline includes a terminal stage with `stage_type = "rejected"`