# Form Submission

## Purpose

Ensure all forms across the application submit reliably, with Design System submit buttons rendering correctly and no form events being silently dropped.

## Requirements

### Requirement: Design System submit buttons
The system SHALL render Design System buttons that pass `type="submit"` as HTML submit buttons so their enclosing `phx-submit` form actually submits.

#### Scenario: Submit button renders with correct type
- **WHEN** a template renders `<.button type="submit">`
- **THEN** the rendered element has `type="submit"`
- **AND** clicking it submits the enclosing form

#### Scenario: Default button type remains button
- **WHEN** a template renders `<.button>` without a type attribute
- **THEN** the rendered element has `type="button"`
- **AND** it does not submit an enclosing form

#### Scenario: All submit forms fire their events
- **WHEN** a user clicks a Design System submit button on any form (create/edit job, add/edit candidate, custom fields, branding, team invite, sources, pipeline stages, email templates, availability, language)
- **THEN** the form's `phx-submit` event is sent to the server
- **AND** the form is not silently dropped

#### Scenario: Confirm dialog forwards extra params
- **WHEN** a confirm dialog is rendered with `extra_attrs={%{id: 42}}`
- **THEN** the confirm button carries `phx-value-id="42"` (not a literal `id` attribute)
- **AND** clicking it sends `%{"id" => 42}` to the `on_confirm` handler

### Requirement: Loading feedback on every form submission
The system SHALL show immediate loading feedback on every form submission across the app, preventing confusion and double-submits.

#### Scenario: Any phx-submit shows pending on its submit button
- **WHEN** the user submits any `phx-submit` form (e.g., create/edit job, add/edit candidate, pipeline stages, branding, team invite, custom fields, email templates, availability, language, career apply)
- **THEN** the form's submit button enters a pending state (dimmed/disabled, spinner visible, label swapped to a loading text) via `phx-submit-loading:` while the event is in flight

#### Scenario: Double-submit is prevented
- **WHEN** a form is in pending state
- **THEN** the submit button has `pointer-events-none` and `disabled` so an additional click does not fire a second submit
