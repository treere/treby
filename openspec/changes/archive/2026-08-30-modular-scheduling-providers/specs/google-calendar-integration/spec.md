# Google Calendar Integration

## Purpose

Integrate with Google Calendar as one calendar provider among several: OAuth-based access, token management, and free/busy queries.

## MODIFIED Requirements

### Requirement: Connect Google Calendar account
The system SHALL allow team members to connect their Google Calendar account via OAuth.

#### Scenario: Initiate Google Calendar connection
- **WHEN** a user clicks "Connect Google Calendar" in settings
- **THEN** the system redirects to Google OAuth consent screen requesting `openid`, `email`, `profile`, and `calendar` scopes

#### Scenario: Successful OAuth callback
- **WHEN** a user authorizes the Google OAuth application
- **THEN** the system resolves the user's email from Google's userinfo endpoint
- **AND** the system stores the access token, refresh token, and token expiry encrypted in `calendar_connections`
- **AND** the system stores the user's email as `provider_email` and the primary calendar ID
- **AND** the connection is recorded with provider `"google"`
- **AND** the settings page shows "Connected as user@gmail.com"

#### Scenario: OAuth denied
- **WHEN** a user denies the Google OAuth request
- **THEN** the system redirects back to settings with a message indicating the connection was not completed

### Requirement: Disconnect Google Calendar
The system SHALL allow users to disconnect their Google Calendar account.

#### Scenario: Disconnect calendar
- **WHEN** a user clicks "Disconnect" on the calendar settings page
- **THEN** the system deletes the Google `calendar_connection` record for that user
- **AND** Google busy periods and Google events are no longer used for that user
- **AND** scheduling continues to work using the internal calendar (and any other connected providers)