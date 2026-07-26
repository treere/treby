# Pipeline (Modified)

## Changes from Main Spec

### ADDED Requirements

### Requirement: Bulk move candidates
The system SHALL allow moving multiple selected candidates to a stage simultaneously.

#### Scenario: Bulk move via selection
- **WHEN** a user selects multiple candidate cards and chooses "Move to Stage"
- **THEN** a dropdown of available stages is shown
- **AND** confirming moves all selected applications to the chosen stage

#### Scenario: Bulk move with email notification
- **WHEN** the target stage has an email template and the user chooses to send
- **THEN** emails are sent to all selected candidates
- **AND** a summary is shown: "X moved, Y emails sent"

### Requirement: Bulk mark reviewed
The system SHALL allow marking multiple selected applications as reviewed or unreviewed.

#### Scenario: Bulk mark reviewed
- **WHEN** a user selects candidate cards and clicks "Mark as Reviewed"
- **THEN** all selected applications have `reviewed` set to `true`

#### Scenario: Bulk mark unreviewed
- **WHEN** a user selects reviewed candidate cards and clicks "Mark as New"
- **THEN** all selected applications have `reviewed` set to `false`
