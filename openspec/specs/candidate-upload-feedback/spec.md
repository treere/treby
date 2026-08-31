# Candidate Upload Feedback

## Purpose

Provide visible, accessible feedback for candidate resume uploads and guard against silent failures, so low-PC, mobile candidates can confirm their selection and not lose their CV unknowingly.

## Requirements

### Requirement: Candidate resume upload visible state
The system SHALL render candidate resume upload state visibly on `/:tenant_slug/careers/:job_id/apply` so a low-PC, mobile candidate can confirm their selection without guessing.

#### Scenario: File selected shows filename and size
- **WHEN** a candidate picks a valid PDF/DOC/DOCX file at the apply form
- **THEN** the UI immediately shows the filename and human-readable size (e.g., "CV.pdf — 1.2 MB") below the input, plus a cancel/remove control

#### Scenario: Progress shown while uploading
- **WHEN** the file is uploading via LiveView
- **THEN** the UI shows a progress bar or percentage and the Submit button is disabled with "Uploading..." until done

#### Scenario: Success state
- **WHEN** upload completes successfully
- **THEN** the UI shows a success checkmark next to the filename and re-enables Submit

#### Scenario: Error state for rejected file
- **WHEN** a file is rejected (too large, wrong type, too many files)
- **THEN** the UI shows the `upload_error_to_string` message inline in red next to the field, keeps the form open, and allows removing the file to proceed without a CV

### Requirement: Apply submit guards upload
The system SHALL prevent a silent "Thank you" with missing resume when the candidate visibly attempted an upload.

#### Scenario: Submit with failed upload does not succeed silently
- **WHEN** a candidate clicks Submit while a picked file has errors or incomplete progress
- **THEN** the form is not submitted, the error remains visible, and a flash/inline message "Please fix the resume upload or remove the file to apply without a CV" is shown

#### Scenario: Submit without any file picked succeeds
- **WHEN** a candidate clicks Submit having picked no file at all
- **THEN** the application is created with `resume_url=nil` and the normal thank-you state is shown (some tenants allow no-CV applications)

### Requirement: Accessibility and i18n for upload feedback
The system SHALL make upload feedback accessible and translatable.

#### Scenario: Touch target and label
- **WHEN** the upload area is shown on a 390px viewport
- **THEN** the choose-file control and remove control have >=44px touch targets and clear labels, and all messages go through `gettext`

#### Scenario: English-only docs but UI is bilingual
- **WHEN** candidate switches locale via `/locale/:locale`
- **THEN** all upload messages appear in that locale (EN/IT), while docs remain English-only per `site/` guidelines
