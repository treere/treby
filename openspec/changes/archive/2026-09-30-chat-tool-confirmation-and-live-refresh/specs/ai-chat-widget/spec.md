## ADDED Requirements

### Requirement: Confirmation card renders summary instead of raw JSON only

The widget SHALL render pending tool runs as summary cards (action title, field rows, collapsed raw details) in both the floating panel and the full assistant page, in light and dark themes.

#### Scenario: Floating panel summary card

- **WHEN** a pending run exists and the user opens the floating assistant panel
- **THEN** the confirmation card shows the summary rows with Confirm/Cancel actions and a collapsed Details section

#### Scenario: Assistant page summary card

- **WHEN** a pending run exists and the user visits the dedicated assistant page
- **THEN** the same summary card is shown with identical actions

#### Scenario: Both themes readable

- **WHEN** the confirmation card is shown in light or dark theme
- **THEN** all text meets contrast requirements and long values wrap without breaking layout
