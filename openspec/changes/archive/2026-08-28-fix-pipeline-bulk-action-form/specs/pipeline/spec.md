# Pipeline

## Delta

## MODIFIED Requirements

### Requirement: Bulk move candidates
The system SHALL allow moving multiple selected candidates to a stage simultaneously. The bulk action bar stage selector and move button SHALL be wired through a form so the dropdown populates without client-side errors.

#### Scenario: Bulk move via selection
- **WHEN** a user selects multiple candidate cards and chooses "Move to Stage"
- **THEN** a dropdown of available stages is shown
- **AND** confirming moves all selected applications to the chosen stage

#### Scenario: Bulk move controls inside a form
- **WHEN** a user opens the bulk action bar on the pipeline board
- **THEN** the stage selector and move button are inside a form element
- **AND** no "form events require the input to be inside a form" error is raised in the browser console

#### Scenario: Bulk move with email notification
- **WHEN** the target stage has an email template and the user chooses to send
- **THEN** emails are sent to all selected candidates
- **AND** a summary is shown: "X moved, Y emails sent"