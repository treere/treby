## ADDED Requirements

### Requirement: Loading feedback on every form submission
The system SHALL show immediate loading feedback on every form submission across the app, preventing confusion and double-submits.

#### Scenario: Any phx-submit shows pending on its submit button
- **WHEN** the user submits any `phx-submit` form (e.g., create/edit job, add/edit candidate, pipeline stages, branding, team invite, custom fields, email templates, availability, language, career apply)
- **THEN** the form's submit button enters a pending state (dimmed/disabled, spinner visible, label swapped to a loading text) via `phx-submit-loading:` while the event is in flight

#### Scenario: Double-submit is prevented
- **WHEN** a form is in pending state
- **THEN** the submit button has `pointer-events-none` and `disabled` so an additional click does not fire a second submit

