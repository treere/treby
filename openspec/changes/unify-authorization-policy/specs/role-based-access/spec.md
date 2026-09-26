## ADDED Requirements

### Requirement: LiveView checks resolve through unified policy
All LiveView and hook permission checks SHALL resolve through the unified policy check with an actor built by the single actor builder, preserving existing grant/deny decisions and fail-closed behavior.

#### Scenario: Settings guard unchanged
- **WHEN** a user without the page action navigates to a settings page
- **THEN** the system still redirects to the dashboard with a permission-denied flash

#### Scenario: Template guard unchanged
- **WHEN** a template renders a gated action
- **THEN** visibility matches the previous helper result for the same membership
