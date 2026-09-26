## ADDED Requirements

### Requirement: Guards assign current actor alongside membership

The system SHALL assign `current_actor` in the membership guards next to `current_tenant` and `current_membership`, without changing resolution, redirects, flash messages, or fail-closed semantics.

#### Scenario: Actor assigned on guarded mount

- **WHEN** a request passes the membership guards
- **THEN** `current_actor` matches the actor derived from the assigned membership and tenant

#### Scenario: Guard contract unchanged

- **WHEN** a request fails the membership guards
- **THEN** the existing redirect and flash behavior applies exactly as before
