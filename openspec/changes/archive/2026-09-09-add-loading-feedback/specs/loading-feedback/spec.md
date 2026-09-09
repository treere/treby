## ADDED Requirements

### Requirement: Loading feedback on form submission
The system SHALL provide immediate visual loading feedback whenever the user submits a form or triggers a mutating action, so the user understands the action is being processed.

#### Scenario: Dead-view POST shows loading state
- **WHEN** the user submits a dead-view form (e.g., login at `/login`, registration at `/register`, password reset at `/reset-password`, invite acceptance, candidate OTP verification)
- **THEN** the submit button becomes disabled, shows a spinning indicator (`hero-arrow-path` with `motion-safe:animate-spin`), and its label changes to a localized loading text (e.g., "Signing in...", "Sending...", "Verifying...")
- **AND** the button has `aria-busy="true"` while pending

#### Scenario: LiveView form shows loading state
- **WHEN** the user submits any LiveView form with `phx-submit`
- **THEN** the submit button shows a pending state via `phx-submit-loading:` Tailwind variants (dimmed/disabled appearance, spinner visible, label swapped to loading text) while the server event is in flight
- **AND** the button is not clickable again until the event completes (prevents double-submit)

#### Scenario: Mutating click shows loading state
- **WHEN** the user triggers a mutating `phx-click` action (e.g., confirm dialog, pipeline move where applicable)
- **THEN** the clicked element shows a pending state via `phx-click-loading:` variants (dimmed/disabled, spinner if applicable) while the event is in flight

#### Scenario: No loading overlay blocks unrelated UI
- **WHEN** a form is submitting
- **THEN** only the relevant submit control(s) show the loading state; the rest of the page remains visible (no full-page blocker), except where an explicit `loading_overlay` is intentionally used for page-level loads

#### Scenario: Reduced motion respected
- **WHEN** the user has `prefers-reduced-motion` enabled
- **THEN** the spinner does not animate (`motion-safe:animate-spin` only animates when motion is allowed)

#### Scenario: Light and dark themes
- **WHEN** the app is in light or dark theme
- **THEN** loading indicators remain visible and contrast-compliant in both themes
