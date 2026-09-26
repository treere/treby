## ADDED Requirements

### Requirement: AI tools authorize through unified policy
AI tool filtering, run-time authorization, and confirm-time re-checks SHALL use the unified policy check against the actor effective set, preserving existing hide-and-deny behavior including fail-closed unmapped tools.

#### Scenario: Denied tool hidden and blocked
- **WHEN** a tool whose required action is denied is listed or invoked
- **THEN** it is hidden from the model and any run returns `{:error, :unauthorized}`

#### Scenario: Revoked action denied at confirm
- **WHEN** an action is revoked between proposal and confirmation
- **THEN** the confirm-time re-check denies with `{:error, :unauthorized}` and no mutation occurs
