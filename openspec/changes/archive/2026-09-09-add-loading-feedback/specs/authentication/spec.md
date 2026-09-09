## ADDED Requirements

### Requirement: Loading feedback on login
The system SHALL show loading feedback when the user submits the login form, so the user understands the sign-in is being processed.

#### Scenario: Login submit shows loading
- **WHEN** the user clicks "Sign in" on `/login`
- **THEN** the button immediately shows a spinner and changes its label to a localized loading text (e.g., "Signing in...") and becomes disabled with `aria-busy="true"` until the response completes

