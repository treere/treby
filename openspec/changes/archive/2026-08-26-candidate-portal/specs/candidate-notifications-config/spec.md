## ADDED Requirements

### Requirement: Candidate notification preferences
The system SHALL allow candidates to configure which email notifications they receive.

#### Scenario: Default preferences
- **WHEN** a candidate has no explicit notification preferences set
- **THEN** the system uses defaults: new_message=true, status_change=true, interview_update=true, important_only=false

#### Scenario: Preferences UI
- **WHEN** candidate accesses the portal settings page
- **THEN** the system displays toggle switches for: "New messages" (email when recruiter sends a message), "Status changes" (email when application stage changes), "Interview updates" (email when interview is scheduled/changed), "Important notifications only" (disable non-critical emails like new_message)

#### Scenario: Update preferences
- **WHEN** candidate toggles a preference and saves
- **THEN** the system updates the `notification_preferences` JSONB field on the candidate record and displays a success confirmation

### Requirement: Notification filtering
The system SHALL respect candidate notification preferences when sending emails.

#### Scenario: Preference enabled
- **WHEN** a notification event occurs and the candidate has the corresponding preference enabled
- **THEN** the system sends the notification email

#### Scenario: Preference disabled
- **WHEN** a notification event occurs and the candidate has the corresponding preference disabled
- **THEN** the system skips the email notification and logs the skip

#### Scenario: Important-only mode
- **WHEN** candidate has "important_only" enabled
- **THEN** the system only sends emails for: status_change, interview_update, offer, rejection — and skips new_message and info_request notifications

### Requirement: Candidate settings page
The system SHALL provide a settings page at `/:tenant_slug/portal/settings`.

#### Scenario: Settings page content
- **WHEN** candidate accesses the settings page
- **THEN** the system displays: candidate name, email (read-only), notification preference toggles, and a "Save" button

#### Scenario: Settings save confirmation
- **WHEN** candidate saves notification preferences
- **THEN** the system displays a success flash message "Preferences saved"
