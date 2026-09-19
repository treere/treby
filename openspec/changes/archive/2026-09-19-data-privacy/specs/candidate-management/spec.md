## MODIFIED Requirements

### Requirement: Master candidate profile
The system SHALL maintain a single master anagrafica per candidate (name, email, phone, LinkedIn URL, custom fields) that serves as the internal reference for identity, deduplication, and email communication. The master SHALL be editable without affecting historical application data. When a Data & Privacy erasure is executed, the master SHALL be anonymized (name/email/phone/linkedin/custom_fields scrubbed per anonymization rule) while the candidate row itself is retained to preserve application FK integrity.

#### Scenario: Edit master profile
- **WHEN** a user edits the master candidate profile
- **THEN** the candidate record is updated
- **AND** no existing application's anagrafica snapshot is modified

#### Scenario: Master is the dedup identity
- **WHEN** the system checks for an existing candidate
- **THEN** it uses the master email (case-insensitive) within the tenant as the identity key

#### Scenario: Data & Privacy anonymization preserves row
- **WHEN** a Data & Privacy erasure anonymizes a candidate
- **THEN** the `candidates` row remains with anonymized fields (`name = "Deleted Candidate <short>"`, `email = "deleted+<id>@deleted.local"`, `phone/linkedin = nil`, `custom_fields = {}`)
- **AND** no hard `DELETE` is issued for the candidate

