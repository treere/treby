## MODIFIED Requirements

### Requirement: Set availability rules per day
The system SHALL allow users to configure their available hours for each day of the week, including multiple disjoint time blocks per day.

#### Scenario: Set working hours for a day
- **WHEN** a user sets their availability for Monday to 09:00-13:00 and 14:00-18:00
- **THEN** the system stores both time blocks independently for that day

#### Scenario: Mark a day as unavailable
- **WHEN** a user does not set availability rules for a day (e.g. Saturday)
- **THEN** no slots are generated for that day

#### Scenario: Multiple disjoint time blocks per day
- **WHEN** a day has more than one non-overlapping availability rule
- **THEN** slot generation unions all blocks for that day into a single set of available slots

### Requirement: Configure timezone
The system SHALL store timezone at the company (tenant) level and at the user level; availability times are interpreted in the owning scope's timezone.

#### Scenario: Company timezone at registration
- **WHEN** a tenant is registered
- **THEN** the company timezone is set from the browser timezone and editable by an admin

#### Scenario: User timezone
- **WHEN** a user is created
- **THEN** the user timezone defaults to the company timezone and is editable by the user

#### Scenario: Timezone interpretation
- **WHEN** slot generation runs
- **THEN** company rules are interpreted in the company timezone and user rules in the user timezone, converted to UTC for calendar integration

## REMOVED Requirements

### Requirement: Set buffer times
Rationale: buffers are removed; the system applies no margin before or after interviews.

## ADDED Requirements

### Requirement: Materialize user availability at creation
The system SHALL, when a user is created, copy the company default availability template into the user's own availability rules.

#### Scenario: New user inherits company template
- **WHEN** a new user is created in a tenant
- **THEN** the user receives a copy of the company template rules (Mon–Fri, 09:00–13:00 and 14:00–18:00) in the user's timezone

#### Scenario: Independent editing
- **WHEN** a user edits their availability after creation
- **THEN** only the user's own rules change; the company template is unaffected

### Requirement: Resolve availability with company fallback
The system SHALL use a user's own availability rules when present, and fall back to the company default template when the user has none.

#### Scenario: User has no rules
- **WHEN** slot computation runs for a user with no availability rules
- **THEN** the company template rules are used

#### Scenario: Neither user nor company has rules
- **WHEN** slot computation runs for a user and tenant with no availability rules
- **THEN** no slots are generated
