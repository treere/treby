## ADDED Requirements

### Requirement: Loading feedback on password reset
The system SHALL show loading feedback when the user submits password-reset forms.

#### Scenario: Reset request shows loading
- **WHEN** the user submits the password-reset request form at `/reset-password`
- **THEN** the submit button shows a spinner and localized loading label and becomes disabled with `aria-busy="true"` while the request is in flight

#### Scenario: Reset confirmation shows loading
- **WHEN** the user submits the new-password form at `/reset-password/:token`
- **THEN** the submit button shows a spinner and localized loading label and becomes disabled with `aria-busy="true"` while the update is in flight

