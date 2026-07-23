# Pipeline (Modified)

## Changes from Main Spec

### Added: Application review state

#### Scenario: Review badge on pipeline card
- **WHEN** an application has `reviewed = false`
- **THEN** a "NEW" badge is displayed on the pipeline card

#### Scenario: Toggle review state
- **WHEN** a user clicks the review toggle on a pipeline card
- **THEN** the application's `reviewed` field is toggled between `true` and `false`

#### Scenario: Filter by review state
- **WHEN** a user selects "New only" from the pipeline filter
- **THEN** only cards with `reviewed = false` are shown in each stage

#### Scenario: Default review state for new applications
- **WHEN** a new application is created (via public form or manual)
- **THEN** `reviewed` defaults to `false`
